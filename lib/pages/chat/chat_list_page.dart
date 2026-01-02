import 'package:flutter/material.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F8),
        elevation: 0,
        title: const Text("聊天", style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 20, fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.search, color: Color(0xFFFF5A7E))],
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatRoomPage()));
            },
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.pinkAccent,
            ),
            title: const Text("Master", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("iyaa bebil, aku di sini", style: TextStyle(color: Colors.grey)),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("22:04", style: TextStyle(color: Colors.grey, fontSize: 12)),
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