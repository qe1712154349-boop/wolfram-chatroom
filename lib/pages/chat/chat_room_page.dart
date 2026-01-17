// lib/pages/chat/chat_room_page.dart - 完整替换
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
  
  final FocusNode _focusNode = FocusNode();
  
  String _characterName = 'name';
  String? _avatarPath;
  String? _userAvatarPath;
 
  final String _currentStatus = '空白';  // 改为 final
  bool _showUserAvatar = true;
  String _systemPrompt = '';
  bool _narrationCentered = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacterData();
    _loadNarrationCentered();
    _loadUserSettings();
    _loadHistory();
    
    _scrollController.addListener(() {
      if (!mounted) return;
      
      final double currentScroll = _scrollController.position.pixels;
      
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom(animate: false);
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _focusNode.unfocus();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    
if (_scrollController.hasClients && _messages.isNotEmpty) {
  final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
  
  if (keyboardVisible) {
    _scrollToBottom(isKeyboard: true);
  } else {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);  // 改为 maxScrollExtent
  }
}
    
    super.didChangeMetrics();
  }

void _scrollWithSpring() {
  if (!mounted || !_scrollController.hasClients) return;
  
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent,  // 改为 maxScrollExtent
    duration: const Duration(milliseconds: 380),
    curve: Curves.elasticOut,
  );
}

  void _scrollToBottom({bool animate = true, bool isKeyboard = false}) {
  if (!mounted) return;
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      if (animate) {
        if (isKeyboard) {
          _scrollWithSpring();
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,  // 改为 maxScrollExtent
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
          );
        }
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);  // 改为 maxScrollExtent
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

  // 修复：确保开场白能显示在聊天列表
  Future<void> _loadOpeningMessage() async {
    final opening = await _storage.getCharacterOpening();
    if (opening.isEmpty) return;
    
    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    // 关键修改：明确设置displayContent
    final msg = Message(
      id: 'opening_${now.millisecondsSinceEpoch}',
      role: 'assistant',
      rawContent: opening,
      displayContent: opening, // 明确设置displayContent
      timestamp: timestamp,
      messageType: MessageType.ai_dialogue,
    );
    
    if (mounted) {
      setState(() {
        _messages.add(msg);
      });
      await _saveHistory(); // 保存到历史记录，确保聊天列表能读取
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);
    
    final MessageType messageType = text.trim().startsWith('/') 
        ? MessageType.user_narration 
        : MessageType.user_dialogue;

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

    _scrollToBottom(isKeyboard: false);
    await _saveHistory();

    try {
      // 不再传入currentTime参数，因为已经在StorageService中删除
      final systemPrompt = await _storage.getCharacterSystemPrompt();
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

      final aiReply = await _apiService.sendChatMessage(apiMessages, model: 'deepseek-chat');
      final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());

      if (mounted) {
        final aiMessages = await _parseAiResponse(aiReply ?? '', aiTimestamp);
        setState(() {
          _messages.addAll(aiMessages);
        });

        await _saveHistory();
        _scrollToBottom(isKeyboard: false);
      }
    } catch (e) {
      final errorTimestamp = DateFormat('HH:mm').format(DateTime.now());
      if (mounted) {
        setState(() {
          _messages.add(Message(
            id: 'ai_error_${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            rawContent: '出错啦… $e',  // 修复字符串插值
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
      final String content = msg.role == 'assistant' 
          ? msg.rawContent
          : msg.displayContent;
      
      apiMessages.add({
        'role': msg.role,
        'content': content.trim(),
      });
    }

    return apiMessages;
  }
  
  // 修复：添加自定义格式与XML解析的联动
  Future<List<Message>> _parseAiResponse(String aiContent, String timestamp) async {
    final List<Message> messages = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    // 获取当前是否启用自定义格式
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
        messageType: MessageType.ai_dialogue,
      ));
      return messages;
    }

    // 如果启用自定义格式，尝试解析XML
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
          displayContent: rawContent,
          timestamp: timestamp,
          messageType: MessageType.ai_dialogue,
        ));
      }
    } else {
      // 未启用自定义格式，整个作为普通对话
      messages.add(Message(
        id: 'ai_${now}_simple',
        role: 'assistant',
        rawContent: rawContent,
        displayContent: rawContent,
        timestamp: timestamp,
        messageType: MessageType.ai_dialogue,
      ));
    }

    return messages;
  }

  Widget _buildMessageWidget(Message msg) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 改为动态主题
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: isDark 
            ? Colors.grey[900] // 暗色模式下的聊天室顶部颜色
            : AppTheme.chatRoomTopLight, // 亮色模式下的粉色
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
          // 聊天区域
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                     reverse: false,  // 改为 false
                   padding: const EdgeInsets.only(top: 20, bottom: 80),  // top改为20,让第一条消息不贴顶
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {  // Loading在最后
  return Padding(
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
  );
}

if (index >= _messages.length) {
  return const SizedBox.shrink();
}

final msg = _messages[index];  // 直接使用 index，不再需要 reversedIndex
return GestureDetector(
  onLongPress: () => _showDeleteDialog(index),  // 改为 index
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
                            _scrollToBottom(isKeyboard: false);
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
          
          // 底部输入区域
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
                        constraints: const BoxConstraints(minHeight: 36),  // 从40改成36或34
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.messageFieldBackgroundDark : AppTheme.messageFieldBackgroundLight,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: isDark ? AppTheme.messageFieldBorderDark : AppTheme.messageFieldBorderLight, 
                            width: 1
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),//输入框最里面嵌入宽vertical高度
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
                            enabledBorder: InputBorder.none,    // 加这行：关闭非焦点灰线
                            focusedBorder: InputBorder.none,    // 加这行：关闭焦点玫红线
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