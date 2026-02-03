import 'package:flutter/material.dart';
import 'color_semantics.dart';
import 'theme_state.dart';

/// 颜色解析器 - 整个主题系统的核心引擎
/// 负责按照优先级获取正确的颜色值：
/// 1. 图片提取色 (最高优先级)
/// 2. UI主题色
/// 3. 默认主题色
/// 4. Material 3系统色 (fallback)
class ColorResolver {
  /// 主解析方法：根据主题状态获取颜色
  static Color resolve({
    required ThemeState themeState,
    required ColorSemantic semantic,
    Color? explicitOverride, // 显式覆盖（用于特殊情况）
  }) {
    // 1. 显式覆盖（最高优先级）
    if (explicitOverride != null) {
      return explicitOverride;
    }

    // 2. 图片提取色
    if (themeState.hasExtractedColors) {
      final extractedColor = _resolveFromExtractedColors(
        extractedColors: themeState.extractedColors!,
        semantic: semantic,
        isDarkMode: themeState.isDarkMode,
      );
      if (extractedColor != null) {
        return extractedColor;
      }
    }

    // 3. UI主题色
    final themeColor = _resolveFromUITheme(
      uiTheme: themeState.uiTheme,
      semantic: semantic,
      isDarkMode: themeState.isDarkMode,
    );
    if (themeColor != null) {
      return themeColor;
    }

    // 4. 默认主题色
    final defaultColor = _resolveFromDefaultTheme(
      semantic: semantic,
      isDarkMode: themeState.isDarkMode,
    );
    if (defaultColor != null) {
      return defaultColor;
    }

    // 5. Material 3 fallback
    return _fallbackToMaterial3(semantic, themeState.isDarkMode);
  }

  /// 从图片提取的颜色中解析
  static Color? _resolveFromExtractedColors({
    required Map<ExtractedColorType, Color> extractedColors,
    required ColorSemantic semantic,
    required bool isDarkMode,
  }) {
    try {
      // 使用映射器将提取的颜色转换为语义颜色
      final semanticColors =
          ExtractedColorMapper.mapToSemantics(extractedColors);
      final color = semanticColors[semantic];

      if (color != null) {
        // 如果是暗色模式，适当调整颜色
        return isDarkMode ? _adjustColorForDarkMode(color) : color;
      }
    } catch (e) {
      debugPrint('从提取色解析失败: $e');
    }

    return null;
  }

  /// 从UI主题解析
  static Color? _resolveFromUITheme({
    required UIThemeType uiTheme,
    required ColorSemantic semantic,
    required bool isDarkMode,
  }) {
    // 这里会从主题定义文件中获取颜色
    // 具体的颜色映射在 theme/definitions/ 中定义
    // 暂时返回null，等主题定义文件创建后再实现
    return null;
  }

  /// 从默认主题解析
  static Color? _resolveFromDefaultTheme({
    required ColorSemantic semantic,
    required bool isDarkMode,
  }) {
    // 默认主题的硬编码颜色
    const defaultLightColors = {
      // 气泡颜色
      ColorSemantic.userBubbleBackground: Color(0xFFFEEBEF),
      ColorSemantic.userBubbleBorder: Color(0xFFE8DADD),
      ColorSemantic.userBubbleText: Color(0xFFA53A67),
      ColorSemantic.aiBubbleBackground: Color(0xFFFFFFFF),
      ColorSemantic.aiBubbleBorder: Color(0xFFE6E0E0),
      ColorSemantic.aiBubbleText: Color(0xFF1D1D1F),

      // 应用颜色
      ColorSemantic.primary: Color(0xFFFF5A7E),
      ColorSemantic.secondary: Color(0xFFFFB6C1),
      ColorSemantic.accent: Color(0xFFFF5A7E),
      ColorSemantic.background: Color(0xFFFDF7F7),
      ColorSemantic.surface: Colors.white,
      ColorSemantic.surfaceVariant: Color(0xFFF5F5F5),
      ColorSemantic.textPrimary: Color(0xFF1D1D1F),
      ColorSemantic.textSecondary: Color(0xFF6D6D6F),
      ColorSemantic.textHint: Color(0xFF9E9E9E),
      ColorSemantic.border: Color(0xFFE0E0E0),
      ColorSemantic.divider: Color(0xFFF0F0F0),

      // 按钮颜色
      ColorSemantic.buttonPrimary: Color(0xFFFF5A7E),
      ColorSemantic.buttonPrimaryText: Colors.white,
      ColorSemantic.buttonSecondary: Color(0xFFF5F5F5),
      ColorSemantic.buttonSecondaryText: Color(0xFF1D1D1F),

      // 组件颜色
      ColorSemantic.appBarBackground: Colors.white,
      ColorSemantic.appBarText: Color(0xFF1D1D1F),
      ColorSemantic.inputBackground: Colors.white,
      ColorSemantic.inputBorder: Color(0xFFE0E0E0),
      ColorSemantic.inputText: Color(0xFF1D1D1F),
      ColorSemantic.switchActive: Color(0xFFFF5A7E),
      ColorSemantic.switchInactive: Color(0xFF757575),

      // 状态颜色
      ColorSemantic.success: Color(0xFF4CAF50),
      ColorSemantic.warning: Color(0xFFFF9800),
      ColorSemantic.error: Color(0xFFF44336),
      ColorSemantic.info: Color(0xFF2196F3),
    };

    const defaultDarkColors = {
      // 气泡颜色
      ColorSemantic.userBubbleBackground: Color(0xFF2A1A1F),
      ColorSemantic.userBubbleBorder: Color(0xFF443339),
      ColorSemantic.userBubbleText: Color(0xFFF8BBD0),
      ColorSemantic.aiBubbleBackground: Color(0xFF1A1A1A),
      ColorSemantic.aiBubbleBorder: Color(0xFF333333),
      ColorSemantic.aiBubbleText: Color(0xFFE0E0E0),

      // 应用颜色
      ColorSemantic.primary: Color(0xFFF95685),
      ColorSemantic.secondary: Color(0xFF3A1F25),
      ColorSemantic.accent: Color(0xFFF95685),
      ColorSemantic.background: Color(0xFF060405),
      ColorSemantic.surface: Color(0xFF1A1A1A),
      ColorSemantic.surfaceVariant: Color(0xFF2D2D2D),
      ColorSemantic.textPrimary: Colors.white,
      ColorSemantic.textSecondary: Color(0xFFAAAAAA),
      ColorSemantic.textHint: Color(0xFF757575),
      ColorSemantic.border: Color(0xFF424242),
      ColorSemantic.divider: Color(0xFF333333),

      // 按钮颜色
      ColorSemantic.buttonPrimary: Color(0xFFF95685),
      ColorSemantic.buttonPrimaryText: Colors.white,
      ColorSemantic.buttonSecondary: Color(0xFF2D2D2D),
      ColorSemantic.buttonSecondaryText: Colors.white,

      // 组件颜色
      ColorSemantic.appBarBackground: Color(0xFF1A1A1A),
      ColorSemantic.appBarText: Colors.white,
      ColorSemantic.inputBackground: Color(0xFF252525),
      ColorSemantic.inputBorder: Color(0xFF444444),
      ColorSemantic.inputText: Colors.white,
      ColorSemantic.switchActive: Color(0xFFF95685),
      ColorSemantic.switchInactive: Color(0xFF757575),

      // 状态颜色（暗色模式下更柔和）
      ColorSemantic.success: Color(0xFF66BB6A),
      ColorSemantic.warning: Color(0xFFFFB74D),
      ColorSemantic.error: Color(0xFFEF5350),
      ColorSemantic.info: Color(0xFF42A5F5),
    };

    final colors = isDarkMode ? defaultDarkColors : defaultLightColors;
    return colors[semantic];
  }

  /// Material 3 fallback颜色
  static Color _fallbackToMaterial3(ColorSemantic semantic, bool isDarkMode) {
    // 这些是Material 3的默认颜色
    // 当所有其他方式都失败时使用
    final materialColors =
        isDarkMode ? _getMaterial3DarkColors() : _getMaterial3LightColors();

    return materialColors[semantic] ?? Colors.grey;
  }

  /// 获取Material 3亮色
  static Map<ColorSemantic, Color> _getMaterial3LightColors() {
    return {
      ColorSemantic.primary: const Color(0xFF6750A4),
      ColorSemantic.secondary: const Color(0xFF625B71),
      ColorSemantic.background: const Color(0xFFFFFBFE),
      ColorSemantic.surface: const Color(0xFFFFFBFE),
      ColorSemantic.surfaceVariant: const Color(0xFFE7E0EC),
      ColorSemantic.textPrimary: const Color(0xFF1C1B1F),
      ColorSemantic.textSecondary: const Color(0xFF49454F),
      ColorSemantic.border: const Color(0xFF79747E),
    };
  }

  /// 获取Material 3暗色
  static Map<ColorSemantic, Color> _getMaterial3DarkColors() {
    return {
      ColorSemantic.primary: const Color(0xFFD0BCFF),
      ColorSemantic.secondary: const Color(0xFFCCC2DC),
      ColorSemantic.background: const Color(0xFF1C1B1F),
      ColorSemantic.surface: const Color(0xFF1C1B1F),
      ColorSemantic.surfaceVariant: const Color(0xFF49454F),
      ColorSemantic.textPrimary: const Color(0xFFE6E1E5),
      ColorSemantic.textSecondary: const Color(0xFFCAC4D0),
      ColorSemantic.border: const Color(0xFF938F99),
    };
  }

  /// 为暗色模式调整颜色
  static Color _adjustColorForDarkMode(Color color) {
    // 如果是亮色，调暗一些
    final hsl = HSLColor.fromColor(color);

    // 降低亮度
    final adjustedLightness = hsl.lightness * 0.7;

    // 稍微降低饱和度，使颜色在暗色模式下更柔和
    final adjustedSaturation = hsl.saturation * 0.8;

    return hsl
        .withLightness(adjustedLightness.clamp(0.0, 1.0))
        .withSaturation(adjustedSaturation.clamp(0.0, 1.0))
        .toColor();
  }

  /// 批量解析多个颜色
  static Map<ColorSemantic, Color> resolveMultiple({
    required ThemeState themeState,
    required List<ColorSemantic> semantics,
  }) {
    final result = <ColorSemantic, Color>{};

    for (final semantic in semantics) {
      result[semantic] = resolve(
        themeState: themeState,
        semantic: semantic,
      );
    }

    return result;
  }

  /// 解析气泡相关的所有颜色
  static Map<String, Color> resolveBubbleColors({
    required ThemeState themeState,
    bool withOpacity = true,
  }) {
    final semantics = [
      ColorSemantic.userBubbleBackground,
      ColorSemantic.userBubbleBorder,
      ColorSemantic.userBubbleText,
      ColorSemantic.aiBubbleBackground,
      ColorSemantic.aiBubbleBorder,
      ColorSemantic.aiBubbleText,
    ];

    final colors = resolveMultiple(
      themeState: themeState,
      semantics: semantics,
    );

    // 如果需要透明度，应用30%透明度
    if (withOpacity) {
      final userBubbleBg = colors[ColorSemantic.userBubbleBackground];
      final aiBubbleBg = colors[ColorSemantic.aiBubbleBackground];

      if (userBubbleBg != null) {
        colors[ColorSemantic.userBubbleBackground] =
            userBubbleBg.withOpacity(0.3);
      }
      if (aiBubbleBg != null) {
        colors[ColorSemantic.aiBubbleBackground] = aiBubbleBg.withOpacity(0.3);
      }
    }

    // 转换为更方便使用的格式
    return {
      'userBubbleBackground': colors[ColorSemantic.userBubbleBackground]!,
      'userBubbleBorder': colors[ColorSemantic.userBubbleBorder]!,
      'userBubbleText': colors[ColorSemantic.userBubbleText]!,
      'aiBubbleBackground': colors[ColorSemantic.aiBubbleBackground]!,
      'aiBubbleBorder': colors[ColorSemantic.aiBubbleBorder]!,
      'aiBubbleText': colors[ColorSemantic.aiBubbleText]!,
    };
  }

  /// 调试方法：打印当前所有颜色
  static void debugPrintColors(ThemeState themeState) {
    debugPrint('=== 主题状态 ===');
    debugPrint('UI主题: ${themeState.uiTheme.displayName}');
    debugPrint('主题模式: ${themeState.themeMode.displayName}');
    debugPrint('暗色模式: ${themeState.isDarkMode}');
    debugPrint('有提取色: ${themeState.hasExtractedColors}');

    debugPrint('\n=== 气泡颜色 ===');
    final bubbleColors = resolveBubbleColors(themeState: themeState);
    for (final entry in bubbleColors.entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }

    debugPrint('\n=== 其他重要颜色 ===');
    final otherSemantics = [
      ColorSemantic.primary,
      ColorSemantic.background,
      ColorSemantic.surface,
      ColorSemantic.textPrimary,
    ];

    for (final semantic in otherSemantics) {
      final color = resolve(themeState: themeState, semantic: semantic);
      debugPrint('${semantic.name}: $color');
    }
  }
}

/// 颜色解析器的简化版本（用于ConsumerWidget）
class ColorResolverNotifier {
  final ThemeState themeState;

  ColorResolverNotifier(this.themeState);

  /// 快速获取用户气泡颜色
  Color get userBubbleBg => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.userBubbleBackground,
      );

  Color get userBubbleText => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.userBubbleText,
      );

  /// 快速获取AI气泡颜色
  Color get aiBubbleBg => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.aiBubbleBackground,
      );

  Color get aiBubbleText => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.aiBubbleText,
      );

  /// 获取带透明度的气泡背景
  Color get userBubbleBgWithOpacity => userBubbleBg.withOpacity(0.3);
  Color get aiBubbleBgWithOpacity => aiBubbleBg.withOpacity(0.3);

  /// 获取气泡装饰
  BoxDecoration get userBubbleDecoration => BoxDecoration(
        color: userBubbleBgWithOpacity,
        border: Border.all(color: userBubbleBorder, width: 1),
        borderRadius: BorderRadius.circular(18),
      );

  BoxDecoration get aiBubbleDecoration => BoxDecoration(
        color: aiBubbleBgWithOpacity,
        border: Border.all(color: aiBubbleBorder, width: 1),
        borderRadius: BorderRadius.circular(18),
      );

  /// 获取边框颜色
  Color get userBubbleBorder => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.userBubbleBorder,
      );

  Color get aiBubbleBorder => ColorResolver.resolve(
        themeState: themeState,
        semantic: ColorSemantic.aiBubbleBorder,
      );
}
