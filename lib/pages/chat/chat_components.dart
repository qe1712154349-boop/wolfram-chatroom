import 'dart:io';  // 这行必须添加在顶部
import 'package:flutter/material.dart';

class ReceivedMessage extends StatelessWidget {
  const ReceivedMessage({
    super.key, 
    required this.text, 
    required this.time,
    this.avatarPath,
  });

  final String text;
  final String time;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 修改头像部分 - 移除了 existsSync() 调用
          avatarPath != null
              ? CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.pinkAccent,
                  backgroundImage: FileImage(File(avatarPath!)),
                )
              : CircleAvatar(
                  radius: 18, 
                  backgroundColor: Colors.pinkAccent,
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD1DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class SentMessage extends StatelessWidget {
  const SentMessage({
    super.key, 
    required this.text, 
    required this.time,
    this.avatarPath,
  });

  final String text;
  final String time;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 5)],
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          // 使用用户头像，如果没有则使用默认头像 - 移除了 existsSync() 调用
          avatarPath != null 
              ? CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.pink,
                  backgroundImage: FileImage(File(avatarPath!)),
                )
              : CircleAvatar(
                  radius: 18, 
                  backgroundColor: Colors.pink,
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
        ],
      ),
    );
  }
}