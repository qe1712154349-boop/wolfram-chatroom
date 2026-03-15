import 'package:flutter/material.dart';
import '../core/color_semantics.dart';
import '../tokens/semantic_mapper.dart';

/// 默认主题 - 你的粉色系设计
class DefaultTheme {
  static const String id = 'default';
  static const String name = '默认主题';
  static const String description = '清爽的粉色系设计，简约而温暖';
  static const IconData icon = Icons.favorite;

  /// 亮色模式颜色映射
  static Map<ColorSemantic, Color> get light {
    return SemanticMapper.defaultLight();
  }

  /// 暗色模式颜色映射
  static Map<ColorSemantic, Color> get dark {
    return SemanticMapper.defaultDark();
  }

  /// 获取当前亮度的颜色映射
  static Map<ColorSemantic, Color> getColors(bool isDark) {
    return isDark ? dark : light;
  }

  /// 获取特定语义的颜色
  static Color getColor(ColorSemantic semantic, bool isDark) {
    return getColors(isDark)[semantic] ?? Colors.grey;
  }

  /// 获取气泡相关颜色
  static Map<String, Color> getBubbleColors(bool isDark) {
    final colors = getColors(isDark);
    return {
      'userBubbleBackground': colors[ColorSemantic.userBubbleBackground]!,
      'userBubbleBorder': colors[ColorSemantic.userBubbleBorder]!,
      'userBubbleText': colors[ColorSemantic.userBubbleText]!,
      'aiBubbleBackground': colors[ColorSemantic.aiBubbleBackground]!,
      'aiBubbleBorder': colors[ColorSemantic.aiBubbleBorder]!,
      'aiBubbleText': colors[ColorSemantic.aiBubbleText]!,
    };
  }

  /// 获取带透明度的气泡颜色
  static Map<String, Color> getBubbleColorsWithOpacity(bool isDark) {
    final colors = getBubbleColors(isDark);
    return {
      'userBubbleBackground':
          colors['userBubbleBackground']!.withValues(alpha: 0.3),
      'userBubbleBorder': colors['userBubbleBorder']!,
      'userBubbleText': colors['userBubbleText']!,
      'aiBubbleBackground':
          colors['aiBubbleBackground']!.withValues(alpha: 0.3),
      'aiBubbleBorder': colors['aiBubbleBorder']!,
      'aiBubbleText': colors['aiBubbleText']!,
    };
  }

  /// 调试信息
  static void debugPrintInfo() {
    debugPrint('=== 默认主题 ===');
    debugPrint('ID: $id');
    debugPrint('名称: $name');
    debugPrint('描述: $description');

    debugPrint('\n亮色模式气泡颜色:');
    final lightBubbles = getBubbleColors(false);
    for (final entry in lightBubbles.entries) {
      debugPrint('  ${entry.key}: ${_colorToHex(entry.value)}');
    }

    debugPrint('\n暗色模式气泡颜色:');
    final darkBubbles = getBubbleColors(true);
    for (final entry in darkBubbles.entries) {
      debugPrint('  ${entry.key}: ${_colorToHex(entry.value)}');
    }
  }

  /// 将颜色转换为16进制字符串
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// 验证主题完整性
  static List<String> validate() {
    final errors = <String>[];

    // 检查亮色模式
    final lightMissing = SemanticMapper.validateMapping(light);
    if (lightMissing.isNotEmpty) {
      errors.add('亮色模式缺少: ${lightMissing.map((e) => e.name).join(', ')}');
    }

    // 检查暗色模式
    final darkMissing = SemanticMapper.validateMapping(dark);
    if (darkMissing.isNotEmpty) {
      errors.add('暗色模式缺少: ${darkMissing.map((e) => e.name).join(', ')}');
    }

    return errors;
  }
}
