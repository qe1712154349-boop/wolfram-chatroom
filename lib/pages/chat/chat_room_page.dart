// lib/pages/chat/chat_room_page.dart
// 彻底迁移到新主题系统（context.themeColor + ColorSemantic）
// 已删除所有旧 AppTheme / Theme.of(context) / cs.xxx 调用
// 保留保活、权限引导、消息解析、滚动、历史恢复等原有逻辑
// 气泡完全用新扩展（context.userBubbleBackground / aiBubbleBackground 等）

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';
import '../../theme/theme.dart' as app_theme; // 新系统入口（as app_theme 避免冲突）
import 'chat_components.dart';
import 'chat_room_settings_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/logger.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _showScrollToBottomButton = false;
  Timer? _scrollButtonTimer;
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  final FocusNode _focusNode = FocusNode();
  bool _isInitializingForegroundService = false;

  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;

  final String _currentStatus = '空白';
  bool _showUserAvatar = true;
  String _systemPrompt = '';
  bool _narrationCentered = true;

  // 前台服务相关
  StreamSubscription<dynamic>? _foregroundServiceSubscription;
  Timer? _serviceMonitorTimer;

  String? _savedInputText;
  double _savedScrollOffset = 0.0;

  AxisDirection _lastDirection = AxisDirection.down;

  bool _hasShownPermissionGuide = false;
  bool _hasShownBatteryGuide = false;

  void Function(dynamic)? _taskDataCallback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _initializeForegroundService();
      });
    });

    _restoreAppState();
    _loadCharacterData();
    _loadNarrationCentered();
    _loadUserSettings();
    _loadHistory();

    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_savedScrollOffset);
      }
    });

    _startServiceMonitor();
  }

  void _scrollListener() {
    if (!mounted) return;

    final pos = _scrollController.position;
    final distanceFromBottom = pos.maxScrollExtent - pos.pixels;

    final isScrollingUp = pos.userScrollDirection == ScrollDirection.reverse;
    final isScrollingDown = pos.userScrollDirection == ScrollDirection.forward;

    if (isScrollingDown && distanceFromBottom > 100.0) {
      if (_lastDirection == AxisDirection.up) {
        setState(() => _showScrollToBottomButton = true);
        _scrollButtonTimer?.cancel();
        _scrollButtonTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _showScrollToBottomButton) {
            setState(() => _showScrollToBottomButton = false);
          }
        });
      }
    }

    if (distanceFromBottom < 50.0) {
      setState(() => _showScrollToBottomButton = false);
      _scrollButtonTimer?.cancel();
    }

    if (isScrollingUp) {
      _lastDirection = AxisDirection.up;
    } else if (isScrollingDown) {
      _lastDirection = AxisDirection.down;
    }
  }

  @override
  void dispose() {
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    }

    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _scrollButtonTimer?.cancel();
    _foregroundServiceSubscription?.cancel();
    _serviceMonitorTimer?.cancel();

    _storage.saveAppState(
      messages: _messages,
      scrollOffset:
          _scrollController.hasClients ? _scrollController.offset : 0.0,
      inputText: _controller.text,
    );

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _storage.saveAppState(
        messages: _messages,
        scrollOffset:
            _scrollController.hasClients ? _scrollController.offset : 0.0,
        inputText: _controller.text,
        currentRoute: '/chat_room',
      );
      _focusNode.unfocus();
      FocusScope.of(context).unfocus();
    } else if (state == AppLifecycleState.resumed) {
      _startForegroundServiceWithPermissions();
      _restoreAppState();
    } else if (state == AppLifecycleState.detached) {
      _foregroundServiceSubscription?.cancel();
    }
  }

  Future<void> _initializeForegroundService() async {
    if (_isInitializingForegroundService) return;

    _isInitializingForegroundService = true;

    try {
      await _startForegroundServiceWithPermissions();
    } catch (e) {
      log.e('前台服务初始化失败: $e');
    } finally {
      _isInitializingForegroundService = false;
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;

    if (_scrollController.hasClients && _messages.isNotEmpty) {
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (keyboardVisible) {
        _scrollToBottom(animate: true);
      }
    }

    super.didChangeMetrics();
  }

  void _startServiceMonitor() {
    _serviceMonitorTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!mounted) return;
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        log.w('前台服务停止，尝试重启...');
        _startForegroundServiceWithPermissions();
      }
    });
  }

  void _scrollToBottom({bool animate = false}) {
    if (!mounted || !_scrollController.hasClients) return;

    const target = 0.0;

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _loadCharacterData() async {
    final name = await _storage.getCharacterNickname();
    final avatarPath = await _storage.getCharacterAvatarPath();

    if (mounted) {
      setState(() {
        _characterName = name;
        _avatarPath = avatarPath;
      });
    }
  }

  Future<void> _loadUserSettings() async {
    final showAvatar = await _storage.getShowUserAvatar();
    final userAvatarPath = await _storage.getUserAvatarPath();

    if (mounted) {
      setState(() {
        _showUserAvatar = showAvatar;
        _userAvatarPath = userAvatarPath;
      });
    }
  }

  Future<void> _loadHistory() async {
    final allHistory = await _storage.loadChatHistory();

    if (allHistory.isEmpty) {
      await _loadOpeningMessage();
      return;
    }

    // 1. 先显示一屏能容纳的消息（35条）
    final screenFullCount = 35;
    final displayCount = allHistory.length > screenFullCount
        ? screenFullCount
        : allHistory.length;

    final recentMessages = allHistory.sublist(allHistory.length - displayCount);

    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(recentMessages);
      });

      // 滚动到最新消息
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    }

    // 2. 如果有更多历史，后台悄悄添加到顶部
    if (allHistory.length > displayCount) {
      final olderMessages =
          allHistory.sublist(0, allHistory.length - displayCount);

      // 延迟一点，等用户开始看消息后再添加
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _messages.insertAll(0, olderMessages);
          });
        }
      });
    }
  }

  Future<void> _loadOpeningMessage() async {
    final opening = await _storage.getCharacterOpening();
    if (opening.isEmpty) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);

    final msg = Message(
      id: 'opening_${now.millisecondsSinceEpoch}',
      role: 'assistant',
      rawContent: opening,
      displayContent: opening,
      timestamp: timestamp,
      messageType: MessageType.aiDialogue,
    );

    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
      await _saveHistory();
    }
  }

  Future<void> _saveHistory() async {
    await _storage.saveChatHistory(_messages);
    if (kDebugMode) {
      print('保存聊天历史成功，消息数: ${_messages.length}');
    }
  }

  Future<void> _loadNarrationCentered() async {
    final centered = await _storage.getNarrationCentered();
    if (mounted) {
      setState(() {
        _narrationCentered = centered;
      });
    }
  }

  Future<void> _clearAllMessages() async {
    if (!mounted) return;
    setState(() {
      _messages.clear();
    });
    await _storage.clearChatHistory();
  }

  /// 最优重构：权限 + 电池优化 + 服务启动 全流程
  Future<void> _startForegroundServiceWithPermissions() async {
    if (!Platform.isAndroid || !mounted) return;

    try {
      // 1. 处理通知权限（Android 13+ 必须）
      await _handleNotificationPermission();

      // 2. 检查服务是否运行
      if (await FlutterForegroundTask.isRunningService) {
        log.d('前台服务已在运行');
        return;
      }

      // 3. 启动服务（9.2.0 标准写法）
      final result = await FlutterForegroundTask.startService(
        notificationTitle: '小猫在线',
        notificationText: '一直陪着你，等你的消息～',
        notificationIcon:
            const NotificationIcon(metaDataName: 'foreground_icon'),
        notificationInitialRoute: '/chat_room',
      );

      if (result is ServiceRequestSuccess) {
        log.d('前台服务启动成功！通知已显示');

        // 监听服务数据
        _setupReceivePortListener();

        // 延迟引导电池优化
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _handleBatteryOptimizationGuide();
        });
      } else {
        log.e('启动失败: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('服务启动失败 ($result)，请检查通知权限')),
          );
        }
      }
    } catch (e, st) {
      log.e('前台服务异常: $e\n$st');
    }
  }

  /// 通知权限处理（最彻底写法）
  Future<void> _handleNotificationPermission() async {
    final status = await FlutterForegroundTask.checkNotificationPermission();

    if (status == NotificationPermission.granted) return;

    final requestResult =
        await FlutterForegroundTask.requestNotificationPermission();

    if (requestResult == NotificationPermission.granted) return;

    // 永久拒绝或 denied → 引导去系统设置
    if (!_hasShownPermissionGuide && mounted) {
      _hasShownPermissionGuide = true;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('小猫需要你的允许～'),
          content: const Text('请开启通知权限，让小猫能在后台一直陪你哦～'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await openAppSettings();
              },
              child: const Text('去开启'),
            ),
          ],
        ),
      );
    }
  }

  /// 电池优化引导（只能跳转，无法查询状态）
  Future<void> _handleBatteryOptimizationGuide() async {
    if (_hasShownBatteryGuide) return;

    _hasShownBatteryGuide = true;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('让小猫一直在线～'),
        content: const Text(
          '请在电池优化中选择"小猫"为"不优化"或"无限制"，否则小猫可能会被系统偷偷杀掉哦～',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('稍后'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FlutterForegroundTask.requestIgnoreBatteryOptimization();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 监听服务数据（心跳、停止重启等）
  void _setupReceivePortListener() {
    // 先移除旧 callback（防重复注册）
    if (_taskDataCallback != null) {
      FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback!);
    }

    // 官方生产方式：注册 callback
    _taskDataCallback = (dynamic data) {
      if (!mounted) return;
      log.d('收到前台服务数据: $data');

      if (data is Map<String, dynamic>) {
        final type = data['type'] as String?;
        switch (type) {
          case 'heartbeat':
            // 可用于心跳 UI 更新
            break;
          case 'service_stopped':
            log.w('服务被停止，3秒后自动重启');
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _startForegroundServiceWithPermissions();
            });
            break;
          case 'notification_clicked':
            log.i('用户点击通知，可跳转或刷新');
            break;
        }
      }
    };

    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
  }

  Future<void> _restoreAppState() async {
    final state = await _storage.loadAppState();
    if (state.isNotEmpty && mounted) {
      _savedInputText = state['inputText'];
      _savedScrollOffset = state['scrollOffset'] ?? 0.0;
      _controller.text = _savedInputText ?? '';
      log.d('恢复：滚动 $_savedScrollOffset px，输入 ${_controller.text}');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);

    final MessageType messageType = text.trim().startsWith('/')
        ? MessageType.userNarration
        : MessageType.userDialogue;

    final processedContent = messageType == MessageType.userNarration
        ? text.trim().substring(1).trim()
        : text.trim();

    final userMessage = Message(
      id: 'user_${now.millisecondsSinceEpoch}',
      role: 'user',
      rawContent: processedContent,
      timestamp: timestamp,
      messageType: messageType,
    );

    setState(() {
      _messages.add(userMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
        _scrollController.position.notifyListeners();
      }
    });

    unawaited(_saveHistory());

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final systemPrompt = await _storage.getCharacterSystemPrompt();
      _systemPrompt = systemPrompt;

      List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': systemPrompt},
      ];

      final contextMessages = _buildContextMessages();
      apiMessages.addAll(contextMessages.map((msg) => ({
            'role': msg['role']!,
            'content': msg['content']!,
          })));

      final aiReply = await _apiService.sendChatMessage(apiMessages,
          model: 'deepseek-chat');

      if (mounted) {
        final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());
        final aiMessages = await _parseAiResponse(aiReply ?? '', aiTimestamp);

        setState(() {
          _messages.addAll(aiMessages);
          _isLoading = false;
        });

        await _saveHistory();

        // 在 setState(() { _messages.addAll(aiMessages); ... }) 后添加：
        FlutterForegroundTask.sendDataToTask({
          'type': 'new_message',
          'content': aiReply ?? '（思考中……）',
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0.0);
            _scrollController.position.notifyListeners();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final errorTimestamp = DateFormat('HH:mm').format(DateTime.now());
        setState(() {
          _messages.add(Message(
            id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            rawContent: '出错啦… $e',
            timestamp: errorTimestamp,
            messageType: MessageType.aiDialogue,
          ));
          _isLoading = false;
        });
        await _saveHistory();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0.0);
            _scrollController.position.notifyListeners();
          }
        });
      }
    }
  }

  void _deleteMessage(int index) {
    if (!mounted) return;

    setState(() {
      _messages.removeAt(index);
    });
    _saveHistory();
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.themeColor(app_theme.ColorSemantic.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text("删除消息",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.themeColor(app_theme.ColorSemantic.onSurface),
            )),
        content: Text("确定要删除这条消息吗？",
            style: TextStyle(
              fontSize: 14,
              color:
                  context.themeColor(app_theme.ColorSemantic.onSurfaceVariant),
            )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("取消",
                style: TextStyle(
                  color:
                      context.themeColor(app_theme.ColorSemantic.textSecondary),
                )),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(index);
              Navigator.pop(context);
            },
            child: Text("删除",
                style: TextStyle(
                  color: context.themeColor(app_theme.ColorSemantic.error),
                )),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildContextMessages({int maxCount = 20}) {
    if (_messages.isEmpty) return [];

    final candidates = _messages
        .where((m) => m.messageType != MessageType.systemTime)
        .toList();

    if (candidates.isEmpty) return [];

    final startIndex =
        (candidates.length - maxCount).clamp(0, candidates.length);
    final recent = candidates.sublist(startIndex);

    final apiList = <Map<String, String>>[];

    for (final msg in recent) {
      final content = msg.role == 'user'
          ? msg.displayContent.trim()
          : msg.rawContent.trim();

      if (content.isEmpty) continue;

      apiList.add({
        'role': msg.role,
        'content': content,
      });
    }

    return apiList;
  }

  Future<List<Message>> _parseAiResponse(
      String aiContent, String timestamp) async {
    final List<Message> messages = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    final characterData = await _storage.loadCharacterData();
    final enableCustomFormat = characterData['enable_custom_format'] == 'true';

    final String rawContent = aiContent.trim();

    if (rawContent.isEmpty) {
      messages.add(Message(
        id: 'ai_${now}_empty',
        role: 'assistant',
        rawContent: '（思考中……）',
        displayContent: '（思考中……）',
        timestamp: timestamp,
        messageType: MessageType.aiDialogue,
      ));
      return messages;
    }

    if (enableCustomFormat) {
      String displayEnvironment = '';
      String displayDialogue = '';

      final startResponse = rawContent.indexOf('<response>');
      final endResponse = rawContent.lastIndexOf('</response>');

      if (startResponse != -1 &&
          endResponse != -1 &&
          endResponse > startResponse) {
        final responseInner = rawContent
            .substring(
              startResponse + '<response>'.length,
              endResponse,
            )
            .trim();

        final envStart = responseInner.indexOf('<environment>');
        final envEnd = responseInner.indexOf('</environment>');
        if (envStart != -1 && envEnd != -1 && envEnd > envStart) {
          displayEnvironment = responseInner
              .substring(envStart + '<environment>'.length, envEnd)
              .trim();
        }

        final diaStart = responseInner.indexOf('<dialogue>');
        final diaEnd = responseInner.indexOf('</dialogue>');
        if (diaStart != -1 && diaEnd != -1 && diaEnd > diaStart) {
          displayDialogue = responseInner
              .substring(diaStart + '<dialogue>'.length, diaEnd)
              .trim();
        }
      } else {
        displayDialogue = rawContent;
      }

      if (displayEnvironment.isNotEmpty) {
        messages.add(Message(
          id: 'ai_nar_$now',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: displayEnvironment,
          timestamp: timestamp,
          messageType: MessageType.aiNarration,
        ));
      }

      if (displayDialogue.isNotEmpty) {
        messages.add(Message(
          id: 'ai_dia_$now',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: displayDialogue,
          timestamp: timestamp,
          messageType: MessageType.aiDialogue,
        ));
      }

      if (messages.isEmpty) {
        messages.add(Message(
          id: 'ai_${now}_raw',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: rawContent,
          timestamp: timestamp,
          messageType: MessageType.aiDialogue,
        ));
      }
    } else {
      messages.add(Message(
        id: 'ai_${now}_simple',
        role: 'assistant',
        rawContent: rawContent,
        displayContent: rawContent,
        timestamp: timestamp,
        messageType: MessageType.aiDialogue,
      ));
    }

    return messages;
  }

  Widget _buildMessageWidget(Message msg) {
    final displayText = msg.displayContent;

    switch (msg.messageType) {
      case MessageType.userNarration:
        return NarrationMessage(
          text: displayText,
          isAI: false,
          isCentered: _narrationCentered,
        );

      case MessageType.aiNarration:
        return NarrationMessage(
          text: displayText,
          isAI: true,
          isCentered: _narrationCentered,
        );

      case MessageType.userDialogue:
        return SentMessage(
          text: displayText,
          userAvatarPath: _userAvatarPath,
          showUserAvatar: _showUserAvatar,
        );

      case MessageType.aiDialogue:
        return ReceivedMessage(
          text: displayText,
          avatarPath: _avatarPath,
        );

      case MessageType.systemTime:
        return SystemTimeMessage(text: displayText);

      case MessageType.systemState:
        return Container();
    }
  }

  // 重点替换：build 方法的所有旧颜色调用 → 新语义
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.themeColor(app_theme.ColorSemantic.chatRoomBackground),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        foregroundColor: context.themeColor(app_theme.ColorSemantic.appBarText),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _showAISetting(context),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context
                    .themeColor(app_theme.ColorSemantic.primaryContainer),
                backgroundImage:
                    _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null
                    ? Icon(
                        Icons.person,
                        size: 18,
                        color: context.themeColor(
                            app_theme.ColorSemantic.onPrimaryContainer),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _characterName,
                    style: TextStyle(
                      color:
                          context.themeColor(app_theme.ColorSemantic.onSurface),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '状态：$_currentStatus',
                    style: TextStyle(
                      color: context
                          .themeColor(app_theme.ColorSemantic.onSurfaceVariant),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 24),
            onPressed: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomSettingsPage(
                    characterName: _characterName,
                    avatarPath: _avatarPath,
                  ),
                ),
              );

              if (result == 'cleared') {
                // 原有逻辑：清空消息
                await _clearAllMessages();
              } else if (result == 'imported') {
                // 新增：导入成功，重新加载数据
                await _loadCharacterData();
                await _loadHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollController,
                    reverse: true,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(height: 75),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (_isLoading && index == 0) {
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: context.themeColor(
                                            app_theme.ColorSemantic
                                                .primaryContainer),
                                        backgroundImage: _avatarPath != null
                                            ? FileImage(File(_avatarPath!))
                                            : null,
                                        child: _avatarPath == null
                                            ? Icon(
                                                Icons.person,
                                                size: 20,
                                                color: context.themeColor(
                                                    app_theme.ColorSemantic
                                                        .onPrimaryContainer),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: context.themeColor(app_theme
                                              .ColorSemantic
                                              .surfaceContainerHighest),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          "正在输入...",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: context.themeColor(app_theme
                                                .ColorSemantic.onSurface),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final msgIndex = _messages.length -
                                1 -
                                index +
                                (_isLoading ? 1 : 0);
                            if (msgIndex < 0 || msgIndex >= _messages.length) {
                              return const SizedBox.shrink();
                            }

                            final msg = _messages[msgIndex];
                            return Container(
                              key: ValueKey(msg.id),
                              child: GestureDetector(
                                onLongPress: () => _showDeleteDialog(msgIndex),
                                child: _buildMessageWidget(msg),
                              ),
                            );
                          },
                          childCount: _messages.length + (_isLoading ? 1 : 0),
                        ),
                      ),
                    ],
                  ),
                  if (_showScrollToBottomButton)
                    Positioned(
                      bottom: 90,
                      right: 16,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.themeColor(
                              app_theme.ColorSemantic.surfaceContainerHighest),
                          border: Border.all(
                            color: context
                                .themeColor(app_theme.ColorSemantic.border),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_downward,
                            color: context
                                .themeColor(app_theme.ColorSemantic.primary),
                            size: 20,
                          ),
                          onPressed: () {
                            _scrollToBottom(animate: true);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 2),
            color: context
                .themeColor(app_theme.ColorSemantic.messageInputBackground),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 22,
                        color: context
                            .themeColor(app_theme.ColorSemantic.textSecondary),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 36),
                        decoration: BoxDecoration(
                          color: context.themeColor(
                              app_theme.ColorSemantic.inputBackground),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: context.themeColor(
                                app_theme.ColorSemantic.inputBorder),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 15,
                            color: context
                                .themeColor(app_theme.ColorSemantic.inputText),
                          ),
                          decoration: InputDecoration(
                            hintText: "输入消息...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(
                              color: context
                                  .themeColor(app_theme.ColorSemantic.textHint),
                            ),
                          ),
                          onSubmitted: (value) {
                            final text = _controller.text.trim();
                            if (text.isNotEmpty) {
                              _sendMessage(text);
                              _controller.clear();
                            }
                          },
                          onChanged: (value) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _sendMessage(text);
                          _controller.clear();
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              context
                                  .themeColor(app_theme.ColorSemantic.primary),
                              context
                                  .themeColor(app_theme.ColorSemantic.primary)
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _showAISetting 弹窗也迁移颜色
  void _showAISetting(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.themeColor(app_theme.ColorSemantic.surface),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: context.themeColor(app_theme.ColorSemantic.divider),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "$_characterName 人物设定",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.themeColor(app_theme.ColorSemantic.onSurface),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _systemPrompt,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color:
                        context.themeColor(app_theme.ColorSemantic.textPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    context.themeColor(app_theme.ColorSemantic.primary),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "关闭",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
