import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({  // 确保有 const 关键字
    super.key,
    required this.title,
    required this.subtitle,
    required this.isLocked,
  });

  final String title;
  final String subtitle;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.white : Colors.white.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Icon(isLocked ? Icons.lock_outline : Icons.check_circle, color: const Color(0xFFFFD1DC)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: isLocked ? null : TextDecoration.lineThrough,
                    color: isLocked ? Colors.black87 : Colors.grey,
                  )),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.radio_button_unchecked, color: Color(0xFFF2F2F2)),
        ],
      ),
    );
  }
}