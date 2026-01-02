import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'chat_components.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();
  
  String _characterName = 'Master';
  String? _avatarPath;
  String _systemPrompt = '';

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _loadHistory();
  }

  Future<void> _loadCharacterData() async {
    // 加载角色数据
    final name = await _storage.getCharacterNickname();
    final avatarPath = await _storage.getCharacterAvatarPath();
    final systemPrompt = await _storage.getCharacterSystemPrompt();
    
    setState(() {
      _characterName = name;
      _avatarPath = avatarPath;
      _systemPrompt = systemPrompt;
    });
  }

  Future<void> _loadHistory() async {
    final history = await _storage.loadChatHistory();
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.addAll(history);
      });
    }
  }

  Future<void> _saveHistory() async {
    await _storage.saveChatHistory(_messages);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = {'role': 'user', 'content': text};

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    await _saveHistory(); // 每次发送都存一次（简单可靠）

    try {
      // 构建发送给API的完整上下文：系统提示 + 最近50条
      List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': _systemPrompt},
      ];

      // 取最后50条（不含本次刚刚加的user消息也可以，但包含更自然）
      final recent = _messages.length > 50 ? _messages.sublist(_messages.length - 50) : _messages;
      apiMessages.addAll(recent);

      final aiReply = await _apiService.sendChatMessage(apiMessages);

      setState(() {
        _messages.add({'role': 'assistant', 'content': aiReply ?? '…'});
      });

      await _saveHistory();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '出错啦… $e'});
      });
      await _saveHistory();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteMessage(int index) {
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
        actions: const [Icon(Icons.more_vert)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return ReceivedMessage(
                    text: "$_characterName正在思考...",
                    time: "",
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(index),
                  child: isUser
                      ? SentMessage(text: msg['content']!, time: "刚刚")
                      : ReceivedMessage(text: msg['content']!, time: "刚刚"),
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
                          hintText: "跟Master说点什么吧...",
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
    );
  }

  // AI设定弹窗，显示完整的系统提示
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}