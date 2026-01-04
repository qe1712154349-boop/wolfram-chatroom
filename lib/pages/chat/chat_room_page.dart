// lib/pages/chat/chat_room_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart' as xml;
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';
import '../../app/theme.dart'; // 添加导入
import 'chat_components.dart';
import 'chat_room_settings_page.dart';
// 移除 xml_message_parser.dart 导入，因为不再需要

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
  
  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;
  bool _showUserAvatar = true;
  String _systemPrompt = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacterData();
    _loadUserSettings();
    _loadHistory();
    
    _scrollController.addListener(() {
      if (!mounted) return;
      
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.position.pixels;
      
      if ((maxScroll - currentScroll) > 300.0) {
        if (!_showScrollToBottomButton) {
          setState(() {
            _showScrollToBottomButton = true;
          });
          // 启动3秒后隐藏计时器
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _controller.dispose();
    _scrollButtonTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
    super.didChangeMetrics();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      // 检查是否需要添加时间戳消息
      final List<Message> messagesWithTime = [];
      
      for (final msg in history) {
        // 由于消息没有存储准确时间，我们暂时不添加时间戳
        messagesWithTime.add(msg);
      }
      
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messagesWithTime);
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveHistory() async {
    await _storage.saveChatHistory(_messages);
  }

  Future<void> _clearAllMessages() async {
    if (!mounted) return;
    
    setState(() {
      _messages.clear();
    });
    await _storage.clearChatHistory();
  }

  /// 检查并插入时间戳消息
  void _checkAndInsertTimestampMessage(DateTime currentTime) {
    if (_messages.isEmpty) return;
    
    // 这里应该比较最后一条消息的时间
    // 由于我们没有存储准确时间，暂时跳过时间戳插入逻辑
    
    // 如果要实现时间戳，可以这样添加：
    // if (shouldInsertTimestamp) {
    //   final timestampMessage = Message(
    //     id: 'timestamp_${currentTime.millisecondsSinceEpoch}',
    //     role: 'system',
    //     content: DateFormat('HH:mm').format(currentTime),
    //     timestamp: DateFormat('HH:mm').format(currentTime),
    //     messageType: MessageType.system_time,
    //   );
    //   _messages.add(timestampMessage);
    // }
  }

  /// 解析AI回复，生成对应的Message对象
  List<Message> _parseAiResponse(String xmlContent, String timestamp) {
    final List<Message> messages = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final document = xml.XmlDocument.parse(xmlContent);
      final messageElement = document.findElements('message').first;
      final children = messageElement.children
          .whereType<xml.XmlElement>()
          .toList();

      for (int i = 0; i < children.length; i++) {
        final node = children[i];
        final text = node.innerText.trim();
        final String content = text;
        
        if (node.name.local == 'narration') {
          // AI旁白
          messages.add(Message(
            id: 'ai_${now}_narration_$i',
            role: 'assistant',
            content: content,
            timestamp: timestamp,
            messageType: MessageType.ai_narration,
          ));
        } else if (node.name.local == 'dialogue') {
          // AI对话
          messages.add(Message(
            id: 'ai_${now}_dialogue_$i',
            role: 'assistant',
            content: content,
            timestamp: timestamp,
            messageType: MessageType.ai_dialogue,
          ));
        }
      }
    } catch (e) {
      // 解析失败时，创建一个默认的AI对话消息
      messages.add(Message(
        id: 'ai_${now}_fallback',
        role: 'assistant',
        content: xmlContent,
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    }
    
    return messages;
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    // 检查是否需要添加时间戳消息
    _checkAndInsertTimestampMessage(now);
    
    // 根据架构规则确定消息类型（核心逻辑）
    final MessageType messageType;
    final String role = 'user';
    String displayContent = text.trim();
    
    if (displayContent.startsWith('/')) {
      // 以/开头 → user_narration
      messageType = MessageType.user_narration;
      displayContent = displayContent.substring(1).trim();
    } else {
      // 否则 → user_dialogue
      messageType = MessageType.user_dialogue;
    }
    
    // 创建Message对象（必须包含显式messageType）
    final userMessage = Message(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: role,
      content: displayContent,
      timestamp: timestamp,
      messageType: messageType,
      metadata: {
        'originalText': text,
      },
    );

    if (!mounted) return;
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();
    await _saveHistory();

    try {
      // 获取包含当前时间的系统提示
      final currentTimeForAI = DateFormat('yyyy年MM月dd日 HH时mm分').format(now);
      final systemPrompt = await _storage.getCharacterSystemPrompt(currentTime: currentTimeForAI);
      _systemPrompt = systemPrompt;

      // 构建发送给API的完整上下文
      List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': systemPrompt},
      ];

      // 只添加对话内容给AI，不包括类型信息
      final int historyLimit = 20;
      final recent = _messages.length > historyLimit 
          ? _messages.sublist(_messages.length - historyLimit) 
          : _messages;

      apiMessages.addAll(recent.map((msg) => {
        'role': msg.role,
        'content': msg.content,
      }));

      // 从StorageService获取选择的模型
      final selectedModel = await _storage.getSelectedModel();
      
      // 调用API时传入当前选择的模型
      final aiReply = await _apiService.sendChatMessage(apiMessages, model: selectedModel);

      // AI回复的时间
      final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());

      if (mounted) {
        // 解析AI回复，生成多个Message
        final aiMessages = _parseAiResponse(aiReply ?? '', aiTimestamp);
        setState(() {
          _messages.addAll(aiMessages);
        });
      }

      await _saveHistory();
      _scrollToBottom();
    } catch (e) {
      final errorTimestamp = DateFormat('HH:mm').format(DateTime.now());
      if (mounted) {
        setState(() {
          _messages.add(Message(
            id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: '出错啦… $e',
            timestamp: errorTimestamp,
            messageType: MessageType.ai_dialogue,
          ));
        });
      }
      await _saveHistory();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          "删除消息",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          "确定要删除这条消息吗？",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "取消",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteMessage(index);
              Navigator.pop(context);
            },
            child: const Text(
              "删除",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

 /// 构建消息Widget - 使用正确的组件
Widget _buildMessageWidget(Message msg) {
  // 根据messageType渲染，使用正确的UI组件
  switch (msg.messageType) {
    case MessageType.user_narration:
      // 用户旁白 - 使用新的旁白组件
      return NarrationMessage(
        text: msg.content,
        isAI: false,
        isCentered: false, // 用户旁白偏右
      );

    case MessageType.ai_narration:
      // AI旁白 - 使用新的旁白组件
      return NarrationMessage(
        text: msg.content,
        isAI: true,
        isCentered: true, // AI旁白居中
      );
      
    case MessageType.user_dialogue:
      // 用户对话
      return SentMessage(
        text: msg.content,
        userAvatarPath: _userAvatarPath,
        showUserAvatar: _showUserAvatar,
      );
      
    case MessageType.ai_dialogue:
      // AI对话
      return ReceivedMessage(
        text: msg.content,
        avatarPath: _avatarPath,
      );
      
    case MessageType.system_time:
      // 系统时间消息
      return SystemTimeMessage(text: msg.content);
      
    case MessageType.system_state:
      // 系统状态消息（当前未实现）
      return Container();
  }
}

 // 修复后的 lib/pages/chat/chat_room_page.dart 的 build 方法部分
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.appBackground,
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
                const Text(
                  "在线",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
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
    body: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFFFD2DD),
                              backgroundImage: _avatarPath != null
                                  ? FileImage(File(_avatarPath!))
                                  : null,
                              child: _avatarPath == null
                                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD2DD),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Text(
                                "正在输入...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = _messages[index];
                    return GestureDetector(
                      onLongPress: () => _showDeleteDialog(index),
                      child: _buildMessageWidget(msg),
                    );
                  },
                ),
              ),
              // 底部输入区域
              Container(
                color: AppTheme.messageInputBackground,
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
                            border: Border.all(
                              color: AppTheme.messageFieldBorder,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          child: TextField(
                            controller: _controller,
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
                            onChanged: (value) {
                              // 可以在这里添加实时搜索或其他功能
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 发送按钮 - 改为圆形更可爱
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5A7E), Color(0xFFFF8E9E)],
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 滚动到底部按钮
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
                  border: Border.all(
                    color: AppTheme.aiBubbleBorder,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_downward, color: Color(0xFFFF5A7E), size: 20),
                  onPressed: () {
                    _scrollToBottom();
                    setState(() {
                      _showScrollToBottomButton = false;
                    });
                    _scrollButtonTimer?.cancel();
                  },
                ),
              ),
            ),
        ],
      ),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFC7C7CC),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "$_characterName 人物设定",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _systemPrompt,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF3C3C43),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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