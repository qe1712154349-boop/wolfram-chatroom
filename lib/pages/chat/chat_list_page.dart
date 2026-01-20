// lib/pages/chat/chat_list_page.dart - 完整替换
// lib/pages/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_room_page.dart';
import 'chat_character_edit_page.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';  // 导入 Message 类

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 使用主题背景色
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        elevation: 0,
        title: Text(
          "聊天",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF4A4A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Icon(Icons.search, color: Theme.of(context).primaryColor),
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
                backgroundColor: Theme.of(context).primaryColor,
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
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
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
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey, 
                          fontSize: 12
                        ),
                      ),
                      const SizedBox(height: 4),
                      CircleAvatar(
                        radius: 4, 
                        backgroundColor: Theme.of(context).primaryColor
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Divider(
            height: 1, 
            indent: 80,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
        ],
      ),
    );
  }
}