import 'package:flutter/material.dart';
import '../theme/theme.dart' as app_theme;

class MoodDay extends StatelessWidget {
  const MoodDay({
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
        Text(
          day,
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.textSecondary),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasMood
                ? context.themeColor(app_theme.ColorSemantic.primaryContainer)
                : context.themeColor(app_theme.ColorSemantic.surfaceVariant),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ],
    );
  }
}
