import 'package:flutter/material.dart';
import 'dart:io';
import 'chat_room_page.dart';
import 'chat_character_edit_page.dart';
import '../../services/storage_service.dart';
import '../../app/theme.dart'; // 导入主题

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final StorageService _storage = StorageService();
  String _characterName = 'name';
  String _characterIntro = 'Character Profile';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    final name = await _storage.getCharacterNickname();
    final intro = await _storage.getCharacterIntro();
    final avatarPath = await _storage.getCharacterAvatarPath();
    
    setState(() {
      _characterName = name;
      _characterIntro = intro.isNotEmpty ? intro : 'Character Profile';
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
              );
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
            subtitle: Text(
              _characterIntro,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "22:04",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 4),
                CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF5A7E)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 80),
        ],
      ),
    );
  }
}