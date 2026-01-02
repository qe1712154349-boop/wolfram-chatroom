import 'package:flutter/material.dart';

class MoodDay extends StatelessWidget {
  const MoodDay({  // 确保有 const 关键字
    super.key,
    required this.day,
    required this.emoji,
    required this.hasMood,
  });

  final String day;
  final String emoji;
  final bool hasMood;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasMood ? const Color(0xFFFFD1DC) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
      ],
    );
  }
}