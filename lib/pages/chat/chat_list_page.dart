// lib/pages/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_room_page.dart';
import 'chat_character_edit_page.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';  // 导入 Message 类
import '../../app/theme.dart'; // 导入主题

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final StorageService _storage = StorageService();
  String _characterName = 'name';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    setState(() {});  // 强制刷新，让 FutureBuilder 立即加载最后消息
  }

  Future<void> _loadCharacterData() async {
    final name = await _storage.getCharacterNickname();
    final avatarPath = await _storage.getCharacterAvatarPath();
    
    setState(() {
      _characterName = name;
      _avatarPath = avatarPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, // 使用统一的背景色
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "聊天",
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Icon(Icons.search, color: Color(0xFFFF5A7E)),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatRoomPage()),
              ).then((_) {
                setState(() {});  // 返回时强制刷新整个列表页
              });
            },
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatCharacterEditPage(),
                  ),
                ).then((_) {
                  _loadCharacterData();
                });
              },
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.pinkAccent,
                backgroundImage: _avatarPath != null
                    ? FileImage(File(_avatarPath!))
                    : null,
                child: _avatarPath == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      )
                    : null,
              ),
            ),
            title: Text(
              _characterName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: FutureBuilder<List<Message>>(
              future: _storage.loadChatHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // 关键修改：使用 displayContent 而不是 content
                  final lastMsg = snapshot.data!.last.displayContent;
                  if (lastMsg.isEmpty) return const SizedBox.shrink();
                  
                  return Text(
                    lastMsg.length > 30 ? '${lastMsg.substring(0, 30)}...' : lastMsg,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return const SizedBox.shrink();  // 无消息时完全空白
              },
            ),
            trailing: FutureBuilder<List<Message>>(
              future: _storage.loadChatHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final lastTime = snapshot.data!.last.timestamp;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lastTime,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF5A7E)),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(height: 1, indent: 80),
        ],
      ),
    );
  }
}