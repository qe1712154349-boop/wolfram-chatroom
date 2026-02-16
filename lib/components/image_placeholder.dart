// lib/components/image_placeholder.dart
import 'package:flutter/material.dart';
import '../theme/theme.dart' as app_theme;

class ImagePlaceholder extends StatelessWidget {
  final double size;
  final Color? color; // ✅ 改为可空，不再硬编码默认值
  final IconData? icon;
  final String? text;

  const ImagePlaceholder({
    super.key,
    this.size = 40,
    this.color, // ✅ 默认为 null
    this.icon = Icons.person,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 如果未传入 color，使用主题主色
    final effectiveColor =
        color ?? context.themeColor(app_theme.ColorSemantic.primary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: text != null
            ? Text(
                text!,
                style: TextStyle(
                  color: Colors.white, // ⚠️ 保留：在主色背景上的白色文字
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Icon(
                icon,
                color: Colors.white, // ⚠️ 保留：在主色背景上的白色图标
                size: size * 0.6,
              ),
      ),
    );
  }
}
