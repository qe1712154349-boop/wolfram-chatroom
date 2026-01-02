import 'dart:io';  // 添加这行
import 'package:flutter/material.dart';

class ReceivedMessage extends StatelessWidget {
  const ReceivedMessage({
    super.key, 
    required this.text, 
    required this.time,
    this.avatarPath,  // 添加可选参数
  });

  final String text;
  final String time;
  final String? avatarPath;  // 添加这个

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 修改头像部分
          avatarPath != null && File(avatarPath!).existsSync()
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
          // 使用用户头像，如果没有则使用默认头像
          avatarPath != null 
              ? CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.pink,
                  backgroundImage: File(avatarPath!).existsSync() 
                      ? FileImage(File(avatarPath!)) 
                      : null,
                  child: !File(avatarPath!).existsSync()
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
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