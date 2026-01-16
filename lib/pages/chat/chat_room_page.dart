// lib/pages/chat/chat_room_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // 物理动画（现在不需要了，但保留也没关系）
import 'package:flutter/foundation.dart';
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
  
  // 新增：用于控制输入框焦点
  final FocusNode _focusNode = FocusNode();
  
  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;
 
  String _currentStatus = '空白';   // 当前状态，默认空白
  bool _showUserAvatar = true;
  String _systemPrompt = '';
  bool _narrationCentered = true;  // 默认居中对齐 ← 新增变量

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacterData();
    _loadNarrationCentered();  // 加载旁白对齐设置
    _loadUserSettings();
    _loadHistory();
    
    _scrollController.addListener(() {
      if (!mounted) return;
      
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.position.pixels;
      
      // 修改：因为 reversed: true，所以滚动到顶部（index 0）时显示滚动按钮
      if (currentScroll > 300.0) {
        if (!_showScrollToBottomButton) {
          setState(() {
            _showScrollToBottomButton = true;
          });
          _scrollButtonTimer?.cancel();
          _scrollButtonTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && _showScrollToBottomButton) {
              setState(() {
                _showScrollToBottomButton = false;
              });
            }
          });
        }
      } else {
        if (_showScrollToBottomButton) {
          setState(() {
            _showScrollToBottomButton = false;
          });
          _scrollButtonTimer?.cancel();
        }
      }
    });
    
    // 首次加载后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom(animate: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();  // 新增：释放 FocusNode
    _scrollController.dispose();
    _controller.dispose();
    _scrollButtonTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App进入后台（息屏、切换App）时：移除输入框焦点
      // 这样iOS/Andoid恢复时就不会自动弹出键盘
      _focusNode.unfocus();
      // 双重保险：确保所有焦点都被移除
      FocusScope.of(context).unfocus();
    }
  }

     @override
  void didChangeMetrics() {
    if (!mounted) return;
    
    // 立即执行，不要等待下一帧
    if (_scrollController.hasClients && _messages.isNotEmpty) {
      // 检测键盘是否显示
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      
      // 键盘弹出：用弹簧动画
      if (keyboardVisible) {
        _scrollToBottom(isKeyboard: true); // 用弹性动画
      }
      // 键盘收起：直接跳转，不要动画！
      else {
        _scrollController.jumpTo(0.0);
      }
    }
    
    super.didChangeMetrics();
  }

  // 修改：简化弹簧滚动方法，使用内置弹性曲线
  void _scrollWithSpring({double velocity = 0.0}) {
    if (!mounted || !_scrollController.hasClients) return;
    
    // 使用内置的弹性曲线模拟弹簧效果
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 380), // 比普通动画稍长
      curve: Curves.elasticOut, // 内置的弹性曲线，有回弹效果
    );
  }

  // 修改：区分键盘弹出和其他滚动
  void _scrollToBottom({bool animate = true, bool isKeyboard = false}) {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          if (isKeyboard) {
            // 键盘弹出：用弹性动画，模拟"被顶"的感觉
            _scrollWithSpring();
          } else {
            // 其他情况：快速平滑的普通动画
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 200), // 快速但不突兀
              curve: Curves.fastOutSlowIn,
            );
          }
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
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
    
    _scrollToBottom(animate: false);
  }

  Future<void> _loadOpeningMessage() async {
    final opening = await _storage.getCharacterOpening();
    if (opening.isEmpty) return;
    
    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    // 简化：直接将开场白作为一条AI对话消息
    final msg = Message(
      id: 'opening_${now.millisecondsSinceEpoch}',
      role: 'assistant',
      rawContent: opening,
      timestamp: timestamp,
      messageType: MessageType.ai_dialogue,
    );
    
    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
    }
  }

  Future<void> _saveHistory() async {
    await _storage.saveChatHistory(_messages);
    print('保存聊天历史成功，消息数: ${_messages.length}');
  }

  // 新增：加载旁白对齐设置
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    final MessageType messageType = text.trim().startsWith('/') 
        ? MessageType.user_narration 
        : MessageType.user_dialogue;

    // 处理内容：旁白去掉斜杠，对话保持不变
    final processedContent = messageType == MessageType.user_narration
        ? text.trim().substring(1).trim()
        : text.trim();

    final userMessage = Message(
      id: 'user_${now.millisecondsSinceEpoch}',
      role: 'user',
      rawContent: processedContent,
      timestamp: timestamp,
      messageType: messageType,
    );

    if (!mounted) return;
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom(isKeyboard: false); // 发送消息用普通动画
    await _saveHistory();

    try {
      final currentTimeForAI = DateFormat('yyyy年MM月dd日 HH时mm分').format(now);
      final systemPrompt = await _storage.getCharacterSystemPrompt(currentTime: currentTimeForAI);
      _systemPrompt = systemPrompt;

      List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': systemPrompt},
      ];

      final contextMessages = _buildContextMessages();
      apiMessages.addAll(
        contextMessages.map((msg) => {
          'role': msg['role']!,
          'content': msg['content']!,
        }),
      );

      // 模型固定为 deepseek-chat
      final aiReply = await _apiService.sendChatMessage(apiMessages, model: 'deepseek-chat');

      final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());

      if (mounted) {
        final aiMessages = await _parseAiResponse(aiReply ?? '', aiTimestamp);
        setState(() {
          _messages.addAll(aiMessages);
        });

        await _saveHistory();
        _scrollToBottom(isKeyboard: false); // AI回复也用普通动画
      }
    } catch (e) {
      final errorTimestamp = DateFormat('HH:mm').format(DateTime.now());
      if (mounted) {
        setState(() {
          _messages.add(Message(
            id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            rawContent: '出错啦… $e',
            timestamp: errorTimestamp,
            messageType: MessageType.ai_dialogue,
          ));
        });
      }
      await _saveHistory();
      _scrollToBottom(isKeyboard: false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // 发送消息后键盘保持打开，用户可以直接输入下一条消息
        // 如果想隐藏键盘，用户可以点击聊天区域其他地方
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

  List<Map<String, String>> _buildContextMessages({int maxCount = 8}) {
    if (_messages.isEmpty) return [];

    final contextCandidates = _messages.where((m) {
      return m.messageType != MessageType.system_time;
    }).toList();

    if (contextCandidates.isEmpty) return [];

    final lastUserMessage = contextCandidates.lastWhere(
      (m) => m.messageType == MessageType.user_dialogue || m.messageType == MessageType.user_narration,
      orElse: () => contextCandidates.last,
    );

    final background = contextCandidates
        .where((m) => m != lastUserMessage)
        .toList()
        .reversed
        .take(maxCount - 1)
        .toList()
        .reversed
        .toList();

    final List<Map<String, String>> apiMessages = [];

    for (final msg in [...background, lastUserMessage]) {
      // 关键：AI消息发送原始XML，用户消息发送纯文本
      final String content = msg.role == 'assistant' 
          ? msg.rawContent  // AI消息：发送原始XML格式
          : msg.displayContent; // 用户消息：发送纯文本
      
      apiMessages.add({
        'role': msg.role,
        'content': content.trim(),
      });
    }

    return apiMessages;
  }
  
  Future<List<Message>> _parseAiResponse(String aiContent, String timestamp) async {
    final List<Message> messages = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    // 保存AI的原始回复（带XML标签）
    final String rawContent = aiContent.trim();

    // 空回复兜底
    if (rawContent.isEmpty) {
      messages.add(Message(
        id: 'ai_${now}_empty',
        role: 'assistant',
        rawContent: '（思考中……）',
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
      return messages;
    }

    // 尝试解析XML格式用于UI显示
    String displayEnvironment = '';
    String displayDialogue = '';

    final startResponse = rawContent.indexOf('<response>');
    final endResponse = rawContent.lastIndexOf('</response>');
    
    if (startResponse != -1 && endResponse != -1 && endResponse > startResponse) {
      final responseInner = rawContent.substring(
        startResponse + '<response>'.length,
        endResponse,
      ).trim();

      // 提取environment显示文本
      final envStart = responseInner.indexOf('<environment>');
      final envEnd = responseInner.indexOf('</environment>');
      if (envStart != -1 && envEnd != -1 && envEnd > envStart) {
        displayEnvironment = responseInner
            .substring(envStart + '<environment>'.length, envEnd)
            .trim();
      }

      // 提取dialogue显示文本
      final diaStart = responseInner.indexOf('<dialogue>');
      final diaEnd = responseInner.indexOf('</dialogue>');
      if (diaStart != -1 && diaEnd != -1 && diaEnd > diaStart) {
        displayDialogue = responseInner
            .substring(diaStart + '<dialogue>'.length, diaEnd)
            .trim();
      }
    } else {
      // 没有XML标签，整个作为对话显示
      displayDialogue = rawContent;
    }

    // 创建AI旁白消息（如果存在环境描述）
    if (displayEnvironment.isNotEmpty) {
      messages.add(Message(
        id: 'ai_nar_${now}',
        role: 'assistant',
        rawContent: rawContent,
        displayContent: displayEnvironment,
        timestamp: timestamp,
        messageType: MessageType.ai_narration,
      ));
    }

    // 创建AI对话消息（如果存在对话）
    if (displayDialogue.isNotEmpty) {
      messages.add(Message(
        id: 'ai_dia_${now}',
        role: 'assistant',
        rawContent: rawContent,
        displayContent: displayDialogue,
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    }

    // 兜底：如果什么都没解析出来
    if (messages.isEmpty) {
      messages.add(Message(
        id: 'ai_${now}_raw',
        role: 'assistant',
        rawContent: rawContent,
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    }

    return messages;
  }

  Widget _buildMessageWidget(Message msg) {
    // 使用displayContent显示，而不是rawContent
    final displayText = msg.displayContent;
    
    switch (msg.messageType) {
      case MessageType.user_narration:
        return NarrationMessage(
          text: displayText,
          isAI: false,
          isCentered: _narrationCentered,
        );

      case MessageType.ai_narration:
        return NarrationMessage(
          text: displayText,
          isAI: true,
          isCentered: _narrationCentered,
        );

      case MessageType.user_dialogue:
        return SentMessage(
          text: displayText,
          userAvatarPath: _userAvatarPath,
          showUserAvatar: _showUserAvatar,
        );

      case MessageType.ai_dialogue:
        return ReceivedMessage(
          text: displayText,
          avatarPath: _avatarPath,
        );

      case MessageType.system_time:
        return SystemTimeMessage(text: displayText);

      case MessageType.system_state:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      resizeToAvoidBottomInset: false, // 关键修改：键盘不压缩界面
      appBar: AppBar(
        backgroundColor: AppTheme.chatRoomTop,
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
                backgroundColor: const Color(0xFFFFD2DD),
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _characterName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '状态：$_currentStatus',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
          // 聊天区域
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFFFD2DD),
                                backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                                child: _avatarPath == null ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD2DD),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text("正在输入...", style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4)),
                              ),
                            ],
                          ),
                        );
                      }

                      final messageIndex = _isLoading ? index - 1 : index;
                      final reversedIndex = _messages.length - 1 - messageIndex;
                      
                      if (reversedIndex < 0 || reversedIndex >= _messages.length) {
                        return const SizedBox.shrink();
                      }
                      
                      final msg = _messages[reversedIndex];
                      return GestureDetector(
                        onLongPress: () => _showDeleteDialog(reversedIndex),
                        child: _buildMessageWidget(msg),
                      );
                    },
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
                          color: Colors.white,
                          border: Border.all(color: AppTheme.aiBubbleBorder, width: 1),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_downward, color: Color(0xFFFF5A7E), size: 20),
                          onPressed: () {
                            _scrollToBottom(isKeyboard: false); // 点击按钮用普通动画
                            setState(() => _showScrollToBottomButton = false);
                            _scrollButtonTimer?.cancel();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 底部浅粉色区域（固定高度，不会被键盘压缩）
          AnimatedContainer(
             duration: const Duration(milliseconds: 80), // 超快速动画
            color: AppTheme.messageInputBackground, // 浅粉色延伸到屏幕底部
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // 给键盘留出空间
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      color: Colors.grey[700],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        decoration: BoxDecoration(
                          color: AppTheme.messageFieldBackground,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: AppTheme.messageFieldBorder, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: "输入消息...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFC7C7CC), borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
            const SizedBox(height: 20),
            Text("$_characterName 人物设定", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _systemPrompt,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF3C3C43)),
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