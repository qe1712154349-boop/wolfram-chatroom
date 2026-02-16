import 'package:flutter/material.dart';
import '../theme/theme.dart' as app_theme;

class OrderCard extends StatelessWidget {
  const OrderCard({
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
        color: isLocked
            ? context.themeColor(app_theme.ColorSemantic.surface)
            : context
                .themeColor(app_theme.ColorSemantic.surface)
                .withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.themeColor(app_theme.ColorSemantic.border),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock_outline : Icons.check_circle,
            color: context.themeColor(app_theme.ColorSemantic.primaryContainer),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: isLocked ? null : TextDecoration.lineThrough,
                    color: isLocked
                        ? context
                            .themeColor(app_theme.ColorSemantic.textPrimary)
                        : context
                            .themeColor(app_theme.ColorSemantic.textSecondary),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.themeColor(app_theme.ColorSemantic.error),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.radio_button_unchecked,
            color: context.themeColor(app_theme.ColorSemantic.surfaceVariant),
          ),
        ],
      ),
    );
  }
}
