// lib/pages/chat/chat_room_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';
import '../../app/theme.dart';
import 'chat_components.dart';
import 'chat_room_settings_page.dart';

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
  
  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;
 
  final String _currentStatus = '空白';
  bool _showUserAvatar = true;
  String _systemPrompt = '';
  bool _narrationCentered = true;

  // 新增字段
  String? _savedInputText;  // 保存输入框
  double _savedScrollOffset = 0.0;  // 保存滚动位置
  
  // 修改：使用枚举值而不是枚举类型本身
  AxisDirection _lastDirection = AxisDirection.down;

  // 新增：判断用户是否在底部附近（用于决定是否自动跟随新消息）
  // ignore: unused_element
  bool get _isUserAtBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    final distance = pos.maxScrollExtent - pos.pixels;
    final isAtBottom = distance < 300.0;
    final isScrollingDown = pos.userScrollDirection == ScrollDirection.forward;
    return isAtBottom || (distance < 600 && isScrollingDown);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. 启动前台服务（保活）
    _startForegroundService();
    
    // 2. 快速恢复状态（0.1s 内）
    _restoreAppState();
    
    // 3. 原有初始化
    _loadCharacterData();
    _loadNarrationCentered();
    _loadUserSettings();
    _loadHistory();
    
    // 4. 原有 scroll listener（不变）
    _scrollController.addListener(() {
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
    });

    // 5. 初始滚动（恢复后自动跳）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_savedScrollOffset);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    _scrollButtonTimer?.cancel();
    
    // 保存最终状态
    _storage.saveAppState(
      messages: _messages,
      scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
      inputText: _controller.text,
    );
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final storage = StorageService();
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 切后台：0.1s 内保存状态
      storage.saveAppState(
        messages: _messages,
        scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
        inputText: _controller.text,
        currentRoute: '/chat_room',
      );
      _focusNode.unfocus();
      FocusScope.of(context).unfocus();
    } else if (state == AppLifecycleState.resumed) {
      // 切回：重启服务 + 恢复
      _startForegroundService();
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

  // 简化版 _scrollToBottom（reverse:true 时目标是 0.0）
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
    final history = await _storage.loadChatHistory();
    if (history.isNotEmpty) {
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
      }
    } else {
      await _loadOpeningMessage();
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
      messageType: MessageType.aiDialogue,  // ← 已改
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

  // 新增方法：启动前台服务
  Future<void> _startForegroundService() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: '小猫',
        notificationText: 'ρ(・ω・、)',
      );
    }
  }

  // 新增方法：恢复应用状态
  Future<void> _restoreAppState() async {
    final state = await StorageService().loadAppState();
    if (state.isNotEmpty) {
      _savedInputText = state['inputText'];
      _savedScrollOffset = state['scrollOffset'] ?? 0.0;
      _controller.text = _savedInputText ?? '';  // 恢复输入框
      if (kDebugMode) print('恢复状态：滚动 ${_savedScrollOffset}px，输入 ${_controller.text}');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    final MessageType messageType = text.trim().startsWith('/') 
        ? MessageType.userNarration   // ← 已改
        : MessageType.userDialogue;   // ← 已改

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

    // 第一阶段：只添加用户消息
    setState(() {
      _messages.add(userMessage);
      // 注意：这里**不**设 _isLoading = true，先让用户消息稳定出现
    });

    // 立即强制下一帧滚动 + paint（核心防合并）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0.0);
      _scrollController.position.notifyListeners();  // 强制通知位置变化
      
      // 额外强制一帧
      SchedulerBinding.instance.scheduleFrame();
    });

    // 异步保存历史
    unawaited(_saveHistory());

    // 短暂延迟后显示 loading（模拟"思考中"，避免抢用户消息的风头）
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

      final aiReply = await _apiService.sendChatMessage(apiMessages, model: 'deepseek-chat');
      
      // 调试打印
      if (kDebugMode) {
        print('\n=== 发送给 DeepSeek 的完整上下文 ===');
        print('时间: ${DateTime.now()}');
        for (var i = 0; i < apiMessages.length; i++) {
          final msg = apiMessages[i];
          final short = msg['content']!.length > 80 
              ? '${msg['content']!.substring(0, 80)}...' 
              : msg['content'];
          print('${i.toString().padLeft(2)} | ${msg['role']!.padRight(8)} | $short');
        }
        print('=============================\n');
      }

      if (mounted) {
        final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());
        final aiMessages = await _parseAiResponse(aiReply ?? '', aiTimestamp);

        setState(() {
          _messages.addAll(aiMessages);
          _isLoading = false;
        });

        await _saveHistory();

        // AI 加入后也强制跳一次（以防长回复推高）
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
            messageType: MessageType.aiDialogue,  // ← 已改
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("删除消息", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text("确定要删除这条消息吗？", style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(index);
              Navigator.pop(context);
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildContextMessages({int maxCount = 20}) {
    if (_messages.isEmpty) return [];

    final candidates = _messages.where((m) => m.messageType != MessageType.systemTime).toList();  // ← 已改

    if (candidates.isEmpty) return [];

    final startIndex = (candidates.length - maxCount).clamp(0, candidates.length);
    final recent = candidates.sublist(startIndex);

    final apiList = <Map<String, String>>[];

    for (final msg in recent) {
      final content = msg.role == 'user'
          ? msg.displayContent.trim()  // 第477行：去掉 ?.，直接用 .
          : msg.rawContent.trim();

      if (content.isEmpty) continue;

      apiList.add({
        'role': msg.role,
        'content': content,
      });
    }

    return apiList;
  }
  
  Future<List<Message>> _parseAiResponse(String aiContent, String timestamp) async {
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
        messageType: MessageType.aiDialogue,  // ← 已改
      ));
      return messages;
    }

    if (enableCustomFormat) {
      String displayEnvironment = '';
      String displayDialogue = '';

      final startResponse = rawContent.indexOf('<response>');
      final endResponse = rawContent.lastIndexOf('</response>');
      
      if (startResponse != -1 && endResponse != -1 && endResponse > startResponse) {
        final responseInner = rawContent.substring(
          startResponse + '<response>'.length,
          endResponse,
        ).trim();

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
          id:'ai_nar_$now',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: displayEnvironment,
          timestamp: timestamp,
          messageType: MessageType.aiNarration,  // ← 已改
        ));
      }

      if (displayDialogue.isNotEmpty) {
        messages.add(Message(
          id: 'ai_dia_$now',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: displayDialogue,
          timestamp: timestamp,
          messageType: MessageType.aiDialogue,  // ← 已改
        ));
      }

      if (messages.isEmpty) {
        messages.add(Message(
          id: 'ai_${now}_raw',
          role: 'assistant',
          rawContent: rawContent,
          displayContent: rawContent,
          timestamp: timestamp,
          messageType: MessageType.aiDialogue,  // ← 已改
        ));
      }
    } else {
      messages.add(Message(
        id: 'ai_${now}_simple',
        role: 'assistant',
        rawContent: rawContent,
        displayContent: rawContent,
        timestamp: timestamp,
        messageType: MessageType.aiDialogue,  // ← 已改
      ));
    }

    return messages;
  }

  Widget _buildMessageWidget(Message msg) {
    final displayText = msg.displayContent;
    
    switch (msg.messageType) {
      case MessageType.userNarration:  // ← 已改
        return NarrationMessage(
          text: displayText,
          isAI: false,
          isCentered: _narrationCentered,
        );

      case MessageType.aiNarration:  // ← 已改
        return NarrationMessage(
          text: displayText,
          isAI: true,
          isCentered: _narrationCentered,
        );

      case MessageType.userDialogue:  // ← 已改
        return SentMessage(
          text: displayText,
          userAvatarPath: _userAvatarPath,
          showUserAvatar: _showUserAvatar,
        );

      case MessageType.aiDialogue:  // ← 已改
        return ReceivedMessage(
          text: displayText,
          avatarPath: _avatarPath,
        );

      case MessageType.systemTime:  // ← 已改
        return SystemTimeMessage(text: displayText);

      case MessageType.systemState:  // ← 已改
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: isDark 
            ? Colors.grey[900]
            : AppTheme.chatRoomTopLight,
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
                backgroundColor: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFD2DD),
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null
                    ? Icon(
                        Icons.person, 
                        size: 18, 
                        color: isDark ? Colors.white : Colors.white
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
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '状态：$_currentStatus',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey, 
                      fontSize: 12
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomSettingsPage(
                    characterName: _characterName,
                    avatarPath: _avatarPath,
                  ),
                ),
              );
              
              if (result == true) {
                await _clearAllMessages();
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
                      // 先加一个大的 SliverPadding 让开场白偏上
                      SliverToBoxAdapter(
                        child: SizedBox(height: 75), // ← 调这个值，越大开场白越靠上
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // 处理"正在输入..."（放在视觉最底部，即 index=0）
                            if (_isLoading && index == 0) {
                              // 只在用户消息后显示
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFD2DD),
                                        backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                                        child: _avatarPath == null 
                                            ? Icon(Icons.person, size: 20, color: isDark ? Colors.white : Colors.white) 
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFD2DD),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          "正在输入...", 
                                          style: TextStyle(
                                            fontSize: 16, 
                                            color: isDark ? Colors.white : Colors.black87, 
                                            height: 1.4
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // 根据是否有loading调整索引
                            final msgIndex = _messages.length - 1 - index + (_isLoading ? 1 : 0);
                            if (msgIndex < 0 || msgIndex >= _messages.length) {
                              return const SizedBox.shrink();
                            }

                            final msg = _messages[msgIndex];
                            // 使用 GlobalKey 确保消息稳定性
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
                          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : AppTheme.aiBubbleBorderLight, 
                            width: 1
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_downward, 
                            color: isDark ? const Color(0xFFF95685) : const Color(0xFFFF5A7E), 
                            size: 20
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
            color: isDark ? AppTheme.messageInputBackgroundDark : AppTheme.messageInputBackgroundLight,
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
                        color: isDark ? Colors.grey[400] : Colors.grey[700]
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
                          color: isDark ? AppTheme.messageFieldBackgroundDark : AppTheme.messageFieldBackgroundLight,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: isDark ? AppTheme.messageFieldBorderDark : AppTheme.messageFieldBorderLight, 
                            width: 1
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black
                          ),
                          decoration: InputDecoration(
                            hintText: "输入消息...",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(
                              color: isDark ? Colors.grey[500] : const Color(0xFF8E8E93)
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
                          gradient: const LinearGradient(colors: [Color(0xFFFF5A7E), Color(0xFFFF8E9E)]),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

  void _showAISetting(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                  color: isDark ? Colors.grey[700] : const Color(0xFFC7C7CC), 
                  borderRadius: BorderRadius.circular(2.5)
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "$_characterName 人物设定", 
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black
              )
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _systemPrompt,
                  style: TextStyle(
                    fontSize: 15, 
                    height: 1.6, 
                    color: isDark ? Colors.grey[300] : const Color(0xFF3C3C43)
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A7E),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("关闭", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}