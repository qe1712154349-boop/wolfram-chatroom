import 'package:flutter/material.dart';
import '../core/color_semantics.dart'; // 添加这行

/// 基础颜色令牌 - 所有硬编码的颜色常量
/// 这些是颜色的"原子"，主题定义会组合这些原子
abstract class BaseColorTokens {
  // ========== 粉色系 (默认主题) ==========
  static const Color pink50 = Color(0xFFFCE4EC);
  static const Color pink100 = Color(0xFFF8BBD0);
  static const Color pink200 = Color(0xFFF48FB1);
  static const Color pink300 = Color(0xFFF06292);
  static const Color pink400 = Color(0xFFEC407A);
  static const Color pink500 = Color(0xFFE91E63);
  static const Color pink600 = Color(0xFFD81B60);
  static const Color pink700 = Color(0xFFC2185B);
  static const Color pink800 = Color(0xFFAD1457);
  static const Color pink900 = Color(0xFF880E4F);

  // 你的特定粉色
  static const Color pinkPrimary = Color(0xFFFF5A7E); // 主粉色
  static const Color pinkPrimaryDark = Color(0xFFF95685); // 暗色主粉色
  static const Color pinkLight = Color(0xFFFFB6C1); // 浅粉色
  static const Color pinkSoft = Color(0xFFFFEAEF); // 柔和粉色
  static const Color pinkUserText = Color(0xFFA53A67); // 用户文字粉色
  static const Color pinkUserBubble = Color(0xFFFEEBEF); // 用户气泡粉色

  // ========== 绿色系 (酸菜牛奶) ==========
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  // 酸菜牛奶特定绿色
  static const Color pickleUserBubble = Color(0xFFF6C7D9); // 用户气泡
  static const Color pickleUserText = Color(0xFF372B2D); // 用户文字
  static const Color pickleAiBubble = Color(0xFFF8EDF3); // AI气泡
  static const Color pickleAiText = Color(0xFF855B40); // AI文字
  static const Color pickleBorder = Color(0xFFEF9CC3); // 边框

  // ========== 中性色 (灰度) ==========
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // 应用特定中性色
  static const Color backgroundLight = Color(0xFFFDF7F7);
  static const Color backgroundDark = Color(0xFF060405);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  // ========== 边框颜色 ==========
  static const Color borderLightPink = Color(0xFFE8DADD);
  static const Color borderLightGray = Color(0xFFE6E0E0);
  static const Color borderDarkPink = Color(0xFF443339);
  static const Color borderDarkGray = Color(0xFF333333);

  // ========== 文字颜色 ==========
  static const Color textPrimaryLight = Color(0xFF1D1D1F);
  static const Color textSecondaryLight = Color(0xFF6D6D6F);
  static const Color textHintLight = Color(0xFF9E9E9E);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textHintDark = Color(0xFF757575);

  // ========== 状态颜色 ==========
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);

  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);

  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFEF5350);

  static const Color infoLight = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF42A5F5);

  // ========== 其他功能色 ==========
  static const Color overlayLight = Color(0x0A000000); // 4% 黑色
  static const Color overlayDark = Color(0x0AFFFFFF); // 4% 白色

  static const Color shadowLight = Color(0x1A000000); // 10% 黑色
  static const Color shadowDark = Color(0x1A000000); // 10% 黑色

  // ========== 透明度工具 ==========
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// 30% 透明度（用于气泡）
  static Color withBubbleOpacity(Color color) {
    return color.withOpacity(0.3);
  }

  /// 获取对比色（黑色或白色）
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? black : white;
  }

  /// 获取安全文本颜色（确保可读性）
  static Color getSafeTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    if (luminance > 0.7) {
      return textPrimaryLight; // 亮背景用深色文字
    } else if (luminance < 0.3) {
      return textPrimaryDark; // 暗背景用浅色文字
    } else {
      // 中等亮度，使用计算对比色
      return getContrastColor(backgroundColor);
    }
  }
}

/// 颜色工具类
class ColorUtils {
  /// 混合两种颜色
  static Color blend(Color color1, Color color2, double ratio) {
    final r = (color1.red * (1 - ratio) + color2.red * ratio).round();
    final g = (color1.green * (1 - ratio) + color2.green * ratio).round();
    final b = (color1.blue * (1 - ratio) + color2.blue * ratio).round();
    final a = (color1.alpha * (1 - ratio) + color2.alpha * ratio).round();

    return Color.fromARGB(a, r, g, b);
  }

  /// 调整颜色亮度
  static Color adjustBrightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// 调整颜色饱和度
  static Color adjustSaturation(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation + delta).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  /// 创建颜色阴影（用于暗色模式）
  static Color createShadow(Color baseColor, {double opacity = 0.1}) {
    return blend(baseColor, BaseColorTokens.black, opacity);
  }

  /// 创建颜色高光（用于亮色模式）
  static Color createHighlight(Color baseColor, {double opacity = 0.1}) {
    return blend(baseColor, BaseColorTokens.white, opacity);
  }

  /// 生成颜色渐变
  static List<Color> generateGradient(Color start, Color end, int steps) {
    final gradient = <Color>[];

    for (var i = 0; i < steps; i++) {
      final ratio = i / (steps - 1);
      gradient.add(blend(start, end, ratio));
    }

    return gradient;
  }

  /// 判断颜色是否为亮色
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// 获取合适的文本颜色（基于背景色）
  static Color getTextColorForBackground(Color backgroundColor) {
    return isLightColor(backgroundColor)
        ? BaseColorTokens.textPrimaryLight
        : BaseColorTokens.textPrimaryDark;
  }

  /// 将颜色转换为16进制字符串
  static String toHexString(Color color, {bool withAlpha = false}) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    if (withAlpha) {
      return '#$hex';
    } else {
      return '#${hex.substring(2)}'; // 去掉alpha通道
    }
  }

  /// 从16进制字符串创建颜色
  static Color fromHexString(String hexString) {
    try {
      var hex = hexString.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // 添加全不透明alpha
      }
      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (e) {
      debugPrint('颜色解析失败: $hexString, 错误: $e');
      return BaseColorTokens.pinkPrimary; // 返回默认颜色
    }
  }
}

/// 预定义的调色板
class ColorPalettes {
  /// 默认粉色调色板
  static const List<Color> defaultPinkPalette = [
    BaseColorTokens.pink50,
    BaseColorTokens.pink100,
    BaseColorTokens.pink200,
    BaseColorTokens.pink300,
    BaseColorTokens.pink400,
    BaseColorTokens.pink500,
    BaseColorTokens.pink600,
    BaseColorTokens.pink700,
    BaseColorTokens.pink800,
    BaseColorTokens.pink900,
  ];

  /// 你的应用粉色调色板
  static const List<Color> appPinkPalette = [
    BaseColorTokens.pinkSoft,
    BaseColorTokens.pinkLight,
    BaseColorTokens.pinkPrimary,
    BaseColorTokens.pinkUserText,
    BaseColorTokens.pinkPrimaryDark,
  ];

  /// 绿色调色板（酸菜牛奶）
  static const List<Color> greenPalette = [
    BaseColorTokens.green50,
    BaseColorTokens.green100,
    BaseColorTokens.green200,
    BaseColorTokens.green300,
    BaseColorTokens.green400,
    BaseColorTokens.green500,
    BaseColorTokens.green600,
    BaseColorTokens.green700,
    BaseColorTokens.green800,
    BaseColorTokens.green900,
  ];

  /// 灰度调色板
  static const List<Color> grayPalette = [
    BaseColorTokens.gray50,
    BaseColorTokens.gray100,
    BaseColorTokens.gray200,
    BaseColorTokens.gray300,
    BaseColorTokens.gray400,
    BaseColorTokens.gray500,
    BaseColorTokens.gray600,
    BaseColorTokens.gray700,
    BaseColorTokens.gray800,
    BaseColorTokens.gray900,
  ];

  /// 获取所有可用的调色板
  static Map<String, List<Color>> getAllPalettes() {
    return {
      'defaultPink': defaultPinkPalette,
      'appPink': appPinkPalette,
      'green': greenPalette,
      'gray': grayPalette,
    };
  }

  /// 从图片提取的颜色创建调色板
  static List<Color> createPaletteFromExtracted(
    Map<ExtractedColorType, Color> extractedColors,
  ) {
    return [
      extractedColors[ExtractedColorType.dominant]!,
      extractedColors[ExtractedColorType.vibrant]!,
      extractedColors[ExtractedColorType.lightVibrant]!,
      extractedColors[ExtractedColorType.darkVibrant]!,
      extractedColors[ExtractedColorType.muted]!,
    ];
  }
}

/// 扩展方法：方便地使用颜色
extension ColorExtensions on Color {
  /// 转换为带透明度的颜色
  Color withBubbleOpacity() {
    return BaseColorTokens.withBubbleOpacity(this);
  }

  /// 获取对比色
  Color get contrastColor {
    return BaseColorTokens.getContrastColor(this);
  }

  /// 获取安全文本颜色
  Color get safeTextColor {
    return BaseColorTokens.getSafeTextColor(this);
  }

  /// 转换为16进制字符串
  String toHex({bool withAlpha = false}) {
    return ColorUtils.toHexString(this, withAlpha: withAlpha);
  }

  /// 判断是否为亮色
  bool get isLight {
    return ColorUtils.isLightColor(this);
  }

  /// 调整亮度
  Color withBrightness(double delta) {
    return ColorUtils.adjustBrightness(this, delta);
  }

  /// 创建深色版本
  Color get darken {
    return ColorUtils.adjustBrightness(this, -0.2);
  }

  /// 创建浅色版本
  Color get lighten {
    return ColorUtils.adjustBrightness(this, 0.2);
  }

  /// 降低饱和度
  Color get desaturate {
    return ColorUtils.adjustSaturation(this, -0.3);
  }
}
