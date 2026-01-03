// lib/pages/chat/chat_room_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'chat_components.dart';
import 'xml_message_parser.dart'; // 新增导入
// 导入新的聊天室设置页面
import 'chat_room_settings_page.dart';  // 确保这个文件存在且正确导出类

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _showScrollToBottomButton = false;
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  
  String _characterName = 'Master';
  String? _avatarPath;
  String _systemPrompt = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacterData();
    _loadHistory();
    
    _scrollController.addListener(() {
      if (!mounted) return; // 添加检查
      
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.position.pixels;
      
      if ((maxScroll - currentScroll) > 300.0) {
        if (!_showScrollToBottomButton && mounted) {
          setState(() {
            _showScrollToBottomButton = true;
          });
        }
      } else {
        if (_showScrollToBottomButton && mounted) {
          setState(() {
            _showScrollToBottomButton = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return; // 添加检查
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _messages.isNotEmpty && mounted) {
        _scrollToBottom();
      }
    });
    super.didChangeMetrics();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
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

  Future<void> _loadHistory() async {
    final history = await _storage.loadChatHistory();
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(history);
      });
      _scrollToBottom();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    // 解析用户输入
    final userInput = XmlMessageParser.parseUserInput(text);
    
    // 获取当前时间
    final now = DateTime.now();
    final timestamp = DateFormat('HH:mm').format(now);

    // 获取包含当前时间的系统提示
    final currentTimeForAI = DateFormat('yyyy年MM月dd日 HH时mm分').format(now);
    final systemPrompt = await _storage.getCharacterSystemPrompt(currentTime: currentTimeForAI);

    final userMessage = {
      'role': 'user', 
      'content': userInput['content']!, // 去掉/前缀的内容
      'displayText': userInput['displayText']!,
      'type': userInput['type'], // 旁白或对话
      'timestamp': timestamp,
    };

    if (!mounted) return;
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _systemPrompt = systemPrompt;
    });

    _scrollToBottom();
    await _saveHistory();

    try {
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
        'role': msg['role']! as String,
        'content': msg['content']! as String, // 只发送内容
      }));

      // 从StorageService获取选择的模型
      final selectedModel = await _storage.getSelectedModel();
      
      // 调用API时传入当前选择的模型
      final aiReply = await _apiService.sendChatMessage(apiMessages, model: selectedModel);

      // AI回复的时间
      final aiTimestamp = DateFormat('HH:mm').format(DateTime.now());

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant', 
            'content': aiReply ?? '…',
            'timestamp': aiTimestamp,
            'parsed': true, // 标记为需要解析
          });
        });
      }

      await _saveHistory();
      _scrollToBottom();
    } catch (e) {
      final errorTimestamp = DateFormat('HH:mm').format(DateTime.now());
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant', 
            'content': '出错啦… $e',
            'timestamp': errorTimestamp,
            'parsed': false,
          });
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
        title: const Text("删除这条消息？"),
        content: const Text("删除后无法恢复哦～"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
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

  /// 构建消息Widget
  Widget _buildMessageWidget(Map<String, dynamic> msg, bool isUser) {
    final content = msg['content']?.toString() ?? '';
    final timestamp = msg['timestamp']?.toString() ?? '';
    final type = msg['type']?.toString();
    final parsed = msg['parsed'] as bool? ?? false;

    // AI消息且需要解析
    if (!isUser && parsed && XmlMessageParser.isValidXml(content)) {
      final widgets = XmlMessageParser.parseXmlMessage(
        xmlContent: content,
        timestamp: timestamp,
        avatarPath: _avatarPath,
        characterName: _characterName,
        isAI: true,
      );
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      );
    }
    
    // 用户消息
    if (isUser) {
      if (type == 'narration') {
        // 用户旁白
        return XmlMessageParser.parseXmlMessage(
          xmlContent: XmlMessageParser.createUserNarrationXml(msg['displayText']?.toString() ?? content),
          timestamp: timestamp,
          avatarPath: null, // 用户旁白不需要头像
          characterName: '你',
          isAI: false,
        ).first;
      } else {
        // 用户对话
        return XmlMessageParser.parseXmlMessage(
          xmlContent: XmlMessageParser.createUserDialogueXml(msg['displayText']?.toString() ?? content),
          timestamp: timestamp,
          avatarPath: null, // 用户对话不需要头像
          characterName: '你',
          isAI: false,
        ).first;
      }
    }
    
    // 默认的AI消息显示（用于解析失败的情况）
    return ReceivedMessage(
      text: content,
      time: timestamp,
      avatarPath: _avatarPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => _showAISetting(context),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pinkAccent,
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null
                    ? const Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _characterName,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  const Text("在线", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              // 跳转到聊天室设置页面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomSettingsPage(
                    characterName: _characterName,
                    avatarPath: _avatarPath,
                  ),
                ),
              );
              
              // 如果返回true，表示清空了聊天记录，需要刷新界面
              if (result == true && mounted) {
                await _clearAllMessages();
              }
            },
          ),
        ],
      ),
      body: Stack(
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
                      return ReceivedMessage(
                        text: "$_characterName正在思考...",
                        time: DateFormat('HH:mm').format(DateTime.now()),
                        avatarPath: _avatarPath,
                      );
                    }

                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';

                    return GestureDetector(
                      onLongPress: () => _showDeleteDialog(index),
                      child: _buildMessageWidget(msg, isUser),
                    );
                  },
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _controller,
                            maxLines: 5,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: "输入消息（以/开头表示旁白）...",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (value) {
                              final text = _controller.text.trim();
                              if (text.isNotEmpty) {
                                _sendMessage(text);
                                _controller.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFFFF5A7E)),
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            _sendMessage(text);
                            _controller.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showScrollToBottomButton)
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFFFF5A7E),
                onPressed: _scrollToBottom,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "$_characterName 人物设定",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _systemPrompt,
                  style: const TextStyle(fontSize: 15, height: 1.6),
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
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text("关闭", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}