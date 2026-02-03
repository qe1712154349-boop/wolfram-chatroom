import 'package:flutter/material.dart';
import '../core/color_semantics.dart';
import '../tokens/semantic_mapper.dart';

/// 草莓糖心主题 - 少女心满满的草莓风格
class StrawberryCandyTheme {
  static const String id = 'strawberryCandy';
  static const String name = '草莓糖心🍓';
  static const String description = '少女心满满的草莓风格，甜美而清新';
  static const IconData icon = Icons.cake;

  /// 亮色模式颜色映射
  static Map<ColorSemantic, Color> get light {
    return SemanticMapper.strawberryCandyLight();
  }

  /// 暗色模式颜色映射
  static Map<ColorSemantic, Color> get dark {
    return SemanticMapper.strawberryCandyDark();
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
      'userBubbleBackground': colors['userBubbleBackground']!.withOpacity(0.3),
      'userBubbleBorder': colors['userBubbleBorder']!,
      'userBubbleText': colors['userBubbleText']!,
      'aiBubbleBackground': colors['aiBubbleBackground']!.withOpacity(0.3),
      'aiBubbleBorder': colors['aiBubbleBorder']!,
      'aiBubbleText': colors['aiBubbleText']!,
    };
  }

  /// 主题特色：草莓糖心特有的样式
  static Map<String, dynamic> getThemeFeatures() {
    return {
      'hasRoundedCorners': true,
      'borderWidth': 1.0,
      'bubbleOpacity': 0.3,
      'shadowEnabled': false,
      'animationStyle': 'gentle',
    };
  }

  /// 获取主题预览颜色（用于展示）
  static List<Color> getPreviewColors(bool isDark) {
    final colors = getColors(isDark);
    return [
      colors[ColorSemantic.primary]!,
      colors[ColorSemantic.secondary]!,
      colors[ColorSemantic.background]!,
      colors[ColorSemantic.userBubbleBackground]!,
      colors[ColorSemantic.aiBubbleBackground]!,
    ];
  }

  /// 调试信息
  static void debugPrintInfo() {
    debugPrint('=== 草莓糖心主题 ===');
    debugPrint('ID: $id');
    debugPrint('名称: $name');
    debugPrint('描述: $description');

    final features = getThemeFeatures();
    debugPrint('主题特色:');
    for (final entry in features.entries) {
      debugPrint('  ${entry.key}: ${entry.value}');
    }
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
