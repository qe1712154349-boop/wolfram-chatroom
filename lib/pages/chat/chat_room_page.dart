// lib/pages/chat/chat_room_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
  
  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;
 
  String _currentStatus = '空白';   // 当前状态，默认空白
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
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
      }

    } else {
      await _loadOpeningMessage();
    }
    
    _scrollToBottom();
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
      content: opening,
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
    print('保存聊天历史成功，消息数: ${_messages.length}');  // ← 加这一行
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
  final String displayContent = messageType == MessageType.user_narration 
      ? text.trim().substring(1).trim() 
      : text.trim();

  final userMessage = Message(
    id: 'user_${now.millisecondsSinceEpoch}',
    role: 'user',
    content: displayContent,
    timestamp: timestamp,
    messageType: messageType,
    metadata: {'originalText': text},
  );

  if (!mounted) return;
  
  setState(() {
    _messages.add(userMessage);
    _isLoading = true;
  });

  _scrollToBottom();
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
        'role': msg.role,
        'content': msg.content,
      }),
    );

    // 清理后：模型固定为 deepseek-chat（后续加自定义时再改）
    final aiReply = await _apiService.sendChatMessage(apiMessages, model: 'deepseek-chat');

    final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());

    if (mounted) {
      // 简化：直接将AI回复作为一条对话消息
      final aiMessages = await _parseAiResponse(aiReply ?? '', aiTimestamp);
      setState(() {
        _messages.addAll(aiMessages);
      });

      await _saveHistory();
      _scrollToBottom();
    }
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

  List<Message> _buildContextMessages({int maxCount = 8}) {
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

    return [...background, lastUserMessage];
  }

  Future<List<Message>> _parseAiResponse(String aiContent, String timestamp) async {
    final List<Message> messages = [];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (kDebugMode) {
      debugPrint('=== AI 回复处理 ===');
      debugPrint('内容长度: ${aiContent.length}');
    }

    // 简化：直接将整个AI回复作为一条对话消息
    if (aiContent.isNotEmpty) {
      messages.add(Message(
        id: 'ai_${now}_dialogue',
        role: 'assistant',
        content: aiContent,
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    } else {
      messages.add(Message(
        id: 'ai_${now}_empty',
        role: 'assistant',
        content: '（思考中……）',
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    }
    
    // 提取状态（如果最后一行包含状态描述）
    if (messages.isNotEmpty) {
      final lastContent = messages.last.content.trim();
      if (lastContent.startsWith('状态：') && lastContent.length > 3) {
        final newStatus = lastContent.substring(3).trim();
        if (newStatus.isNotEmpty) {
          _currentStatus = newStatus;
          await _storage.saveLastStatus(newStatus);
        }
      }
    }

    return messages;
  }



Widget _buildMessageWidget(Message msg) {
  switch (msg.messageType) {
    case MessageType.user_narration:
      return NarrationMessage(
        text: msg.content, 
        isAI: false, 
        isCentered: true, // ← 改为 true 才能居中！
      );  // ✅ 用户旁白保留
    case MessageType.ai_narration:
      // ✅ AI旁白也显示为对话气泡
      return ReceivedMessage(text: msg.content, avatarPath: _avatarPath);
    case MessageType.user_dialogue:
      return SentMessage(text: msg.content, userAvatarPath: _userAvatarPath, showUserAvatar: _showUserAvatar);
    case MessageType.ai_dialogue:
      return ReceivedMessage(text: msg.content, avatarPath: _avatarPath);
    case MessageType.system_time:
      return SystemTimeMessage(text: msg.content);
    case MessageType.system_state:
      return Container();
  }
}

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

                      final msg = _messages[index];
                      return GestureDetector(
                        onLongPress: () => _showDeleteDialog(index),
                        child: _buildMessageWidget(msg),
                      );
                    },
                  ),
                ),
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
                              border: Border.all(color: AppTheme.messageFieldBorder, width: 1),
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
                    color: Colors.white,
                    border: Border.all(color: AppTheme.aiBubbleBorder, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_downward, color: Color(0xFFFF5A7E), size: 20),
                    onPressed: () {
                      _scrollToBottom();
                      setState(() => _showScrollToBottomButton = false);
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