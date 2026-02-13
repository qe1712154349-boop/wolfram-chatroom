import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/color_semantics.dart';
import '../core/color_resolver.dart';
import '../providers/app_theme_provider.dart';
import '../providers/theme_manager.dart';
import '../providers/brightness_provider.dart';
import '../core/theme_state.dart'; // 添加这行
import '../providers/color_override.dart'; // 添加这行
import '../extensions/semantic_colors_extension.dart'; // ← 加这一行

/// 上下文颜色扩展 - 在Widget中直接获取颜色
extension ThemeColors on BuildContext {
  // ========== 基础颜色获取 ==========

  /// 使用颜色解析器获取颜色
  Color themeColor(ColorSemantic semantic) {
    final ref = ProviderScope.containerOf(this);
    final themeState = ref.read(appThemeProvider);

    return ColorResolver.resolve(
      themeState: themeState,
      semantic: semantic,
    );
  }

  /// 获取用户气泡背景色（带30%透明度）
  Color get userBubbleBackground {
    final ref = ProviderScope.containerOf(this);
    final themeState = ref.read(appThemeProvider);
    final theme = ref.read(currentThemeProvider);

    return theme.getBubbleColorsWithOpacity(
        themeState.isDarkMode)['userBubbleBackground']!;
  }

  /// 获取用户气泡边框色
  Color get userBubbleBorder {
    return themeColor(ColorSemantic.userBubbleBorder);
  }

  /// 获取用户气泡文字色
  Color get userBubbleText {
    return themeColor(ColorSemantic.userBubbleText);
  }

  /// 获取AI气泡背景色（带30%透明度）
  Color get aiBubbleBackground {
    final ref = ProviderScope.containerOf(this);
    final themeState = ref.read(appThemeProvider);
    final theme = ref.read(currentThemeProvider);

    return theme.getBubbleColorsWithOpacity(
        themeState.isDarkMode)['aiBubbleBackground']!;
  }

  /// 获取AI气泡边框色
  Color get aiBubbleBorder {
    return themeColor(ColorSemantic.aiBubbleBorder);
  }

  /// 获取AI气泡文字色
  Color get aiBubbleText {
    return themeColor(ColorSemantic.aiBubbleText);
  }

  // ========== 气泡装饰 ==========

  /// 获取用户气泡装饰
  BoxDecoration get userBubbleDecoration {
    final ref = ProviderScope.containerOf(this);
    return ref.read(userBubbleDecorationProvider);
  }

  /// 获取AI气泡装饰
  BoxDecoration get aiBubbleDecoration {
    final ref = ProviderScope.containerOf(this);
    return ref.read(aiBubbleDecorationProvider);
  }

  /// 获取用户气泡文字样式
  TextStyle get userBubbleTextStyle {
    final ref = ProviderScope.containerOf(this);
    return ref.read(userBubbleTextStyleProvider);
  }

  /// 获取AI气泡文字样式
  TextStyle get aiBubbleTextStyle {
    final ref = ProviderScope.containerOf(this);
    return ref.read(aiBubbleTextStyleProvider);
  }

  // ========== 常用颜色快捷方式 ==========

  /// 获取主色
  Color get themePrimary => themeColor(ColorSemantic.primary);

  /// 获取背景色
  Color get themeBackground => themeColor(ColorSemantic.background);

  /// 获取表面色
  Color get themeSurface => themeColor(ColorSemantic.surface);

  /// 获取主要文字色
  Color get themeTextPrimary => themeColor(ColorSemantic.textPrimary);

  /// 获取次要文字色
  Color get themeTextSecondary => themeColor(ColorSemantic.textSecondary);

  /// 获取边框色
  Color get themeBorder => themeColor(ColorSemantic.border);

  // ========== 状态颜色 ==========

  Color get themeSuccess => themeColor(ColorSemantic.success);
  Color get themeWarning => themeColor(ColorSemantic.warning);
  Color get themeError => themeColor(ColorSemantic.error);
  Color get themeInfo => themeColor(ColorSemantic.info);

  // ========== 主题状态信息 ==========

  /// 是否是暗色模式
  bool get isDarkMode {
    final ref = ProviderScope.containerOf(this);
    return ref.read(isDarkModeProvider);
  }

// 改为：
  /// 是否有图片提取色
  bool get hasExtractedColors {
    final ref = ProviderScope.containerOf(this);
    final themeState = ref.read(appThemeProvider);
    return themeState.hasExtractedColors;
  }

  /// 获取当前主题名称
  String get currentThemeName {
    final ref = ProviderScope.containerOf(this);
    final manager = ref.read(themeManagerProvider);
    return manager.currentThemeName;
  }

  // ========== 工具方法 ==========

  /// 获取合适的文字颜色（基于背景色）
  Color getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 获取带透明度的颜色
  Color withBubbleOpacity(Color color) {
    return color.withOpacity(0.3);
  }

  /// 创建气泡装饰
  BoxDecoration createBubbleDecoration({
    required Color backgroundColor,
    required Color borderColor,
    double borderRadius = 18,
    double borderWidth = 1,
    bool withOpacity = true,
  }) {
    return BoxDecoration(
      color: withOpacity ? backgroundColor.withOpacity(0.3) : backgroundColor,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // 新增：直接获取 AppSemanticColors 对象（放在 extension 内部末尾）
  AppSemanticColors get semanticColors {
    return Theme.of(this).extension<AppSemanticColors>()!;
  }

  // 更短的别名（推荐用这个）
  AppSemanticColors get sem => semanticColors;
}

/// WidgetRef扩展 - 在ConsumerWidget中直接获取颜色
extension ThemeColorsRef on WidgetRef {
  // ========== 基础颜色获取 ==========

  /// 使用颜色解析器获取颜色
  Color themeColor(ColorSemantic semantic) {
    final themeState = read(appThemeProvider);

    return ColorResolver.resolve(
      themeState: themeState,
      semantic: semantic,
    );
  }

  /// 获取用户气泡背景色（带30%透明度）
  Color get userBubbleBackground {
    final themeState = read(appThemeProvider);
    final theme = read(currentThemeProvider);

    return theme.getBubbleColorsWithOpacity(
        themeState.isDarkMode)['userBubbleBackground']!;
  }

  /// 获取用户气泡边框色
  Color get userBubbleBorder {
    return themeColor(ColorSemantic.userBubbleBorder);
  }

  /// 获取用户气泡文字色
  Color get userBubbleText {
    return themeColor(ColorSemantic.userBubbleText);
  }

  /// 获取AI气泡背景色（带30%透明度）
  Color get aiBubbleBackground {
    final themeState = read(appThemeProvider);
    final theme = read(currentThemeProvider);

    return theme.getBubbleColorsWithOpacity(
        themeState.isDarkMode)['aiBubbleBackground']!;
  }

  /// 获取AI气泡边框色
  Color get aiBubbleBorder {
    return themeColor(ColorSemantic.aiBubbleBorder);
  }

  /// 获取AI气泡文字色
  Color get aiBubbleText {
    return themeColor(ColorSemantic.aiBubbleText);
  }

  // ========== 气泡装饰 ==========

  /// 获取用户气泡装饰
  BoxDecoration get userBubbleDecoration {
    return read(userBubbleDecorationProvider);
  }

  /// 获取AI气泡装饰
  BoxDecoration get aiBubbleDecoration {
    return read(aiBubbleDecorationProvider);
  }

  /// 获取用户气泡文字样式
  TextStyle get userBubbleTextStyle {
    return read(userBubbleTextStyleProvider);
  }

  /// 获取AI气泡文字样式
  TextStyle get aiBubbleTextStyle {
    return read(aiBubbleTextStyleProvider);
  }

  // ========== 主题装饰 ==========

  /// 获取当前主题的所有装饰
  ThemeDecorations get themeDecorations {
    return read(currentThemeDecorationsProvider);
  }

  // ========== 主题状态信息 ==========

  /// 是否是暗色模式
  bool get isDarkMode {
    return read(isDarkModeProvider);
  }

// 改为：
  /// 是否有图片提取色
  bool get hasExtractedColors {
    final themeState = read(appThemeProvider);
    return themeState.hasExtractedColors;
  }

  /// 获取当前主题名称
  String get currentThemeName {
    final manager = read(themeManagerProvider);
    return manager.currentThemeName;
  }

  /// 获取主题管理器
  ThemeManager get themeManager {
    return read(themeManagerProvider);
  }

  // ========== 工具方法 ==========

  /// 切换UI主题
  Future<void> switchUITheme(UIThemeType uiTheme) async {
    final notifier = read(appThemeProvider.notifier);
    await notifier.updateUITheme(uiTheme);
  }

  /// 切换主题模式
  Future<void> switchThemeMode(AppThemeMode themeMode) async {
    final notifier = read(appThemeProvider.notifier);
    await notifier.updateThemeMode(themeMode);
  }

  /// 切换亮暗模式
  Future<void> toggleDarkMode() async {
    final manager = read(themeManagerProvider);
    await manager.toggleDarkMode();
  }

  /// 应用图片提取色
  Future<void> applyExtractedColors(Map<String, Color> colors) async {
    final notifier = read(extractedColorsUtilsProvider);
    final extractedColors = notifier.convertFromStringMap(colors);
    await notifier.updateColors(extractedColors);
  }

  /// 重置主题
  Future<void> resetTheme() async {
    final notifier = read(appThemeProvider.notifier);
    await notifier.reset();
  }

  /// 调试打印主题信息
  void debugPrintThemeInfo() {
    final manager = read(themeManagerProvider);
    manager.debugPrintInfo();
  }
}

/// Color扩展 - 添加主题相关功能
extension ThemeColorExtensions on Color {
  /// 获取对比色（黑或白）
  Color get contrastColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// 获取适合做文字的颜色（确保可读性）
  Color get readableTextColor {
    final luminance = computeLuminance();
    if (luminance > 0.7) {
      return Colors.black; // 亮背景用深色文字
    } else if (luminance < 0.3) {
      return Colors.white; // 暗背景用浅色文字
    } else {
      // 中等亮度，使用对比色
      return contrastColor;
    }
  }

  /// 调整亮度
  Color withBrightness(double delta) {
    final hsl = HSLColor.fromColor(this);
    final newLightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// 创建深色版本
  Color get darken => withBrightness(-0.2);

  /// 创建浅色版本
  Color get lighten => withBrightness(0.2);

  /// 降低饱和度
  Color get desaturate {
    final hsl = HSLColor.fromColor(this);
    final newSaturation = (hsl.saturation * 0.7).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  /// 创建气泡颜色（带30%透明度）
  Color get asBubbleColor => withOpacity(0.3);

  /// 创建边框颜色（带20%透明度）
  Color get asBorderColor => withOpacity(0.2);
}

/// TextStyle扩展 - 添加主题相关功能
extension ThemeTextStyleExtensions on TextStyle {
  /// 使用主题颜色
  TextStyle withThemeColor(Color color) {
    return copyWith(color: color);
  }

  /// 使用用户气泡文字颜色
  TextStyle withUserBubbleColor(BuildContext context) {
    return copyWith(color: context.userBubbleText);
  }

  /// 使用AI气泡文字颜色
  TextStyle withAiBubbleColor(BuildContext context) {
    return copyWith(color: context.aiBubbleText);
  }

  /// 使用主题主色
  TextStyle withPrimaryColor(BuildContext context) {
    return copyWith(color: context.themePrimary);
  }
}

/// BoxDecoration扩展 - 添加主题相关功能
extension ThemeDecorationExtensions on BoxDecoration {
  /// 使用用户气泡样式
  BoxDecoration withUserBubbleStyle(BuildContext context) {
    return copyWith(
      color: context.userBubbleBackground,
      border: Border.all(
        color: context.userBubbleBorder,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }

  /// 使用AI气泡样式
  BoxDecoration withAiBubbleStyle(BuildContext context) {
    return copyWith(
      color: context.aiBubbleBackground,
      border: Border.all(
        color: context.aiBubbleBorder,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }
}

/// 快速创建气泡Widget的扩展
extension ThemeBubbleWidgetExtensions on Widget {
  /// 包装为用户气泡
  Widget asUserBubble(BuildContext context, {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: context.userBubbleDecoration,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DefaultTextStyle(
        style: context.userBubbleTextStyle,
        child: this,
      ),
    );
  }

  /// 包装为AI气泡
  Widget asAiBubble(BuildContext context, {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: context.aiBubbleDecoration,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DefaultTextStyle(
        style: context.aiBubbleTextStyle,
        child: this,
      ),
    );
  }
}

/// 调试工具
class ThemeDebugTools {
  /// 打印所有主题颜色
  static void printAllThemeColors(WidgetRef ref) {
    final manager = ref.themeManager;
    manager.debugPrintInfo();

    debugPrint('\n=== 扩展方法测试 ===');
    debugPrint('用户气泡文字色: ${ref.userBubbleText.toHex()}');
    debugPrint('AI气泡文字色: ${ref.aiBubbleText.toHex()}');
    debugPrint('暗色模式: ${ref.isDarkMode}');
    debugPrint('有提取色: ${ref.hasExtractedColors}');
  }

  /// 在控制台显示颜色方块（用于调试）
  static void showColorPalette(WidgetRef ref) {
    final colors = <String, Color>{
      '用户气泡背景': ref.userBubbleBackground,
      '用户气泡边框': ref.userBubbleBorder,
      '用户气泡文字': ref.userBubbleText,
      'AI气泡背景': ref.aiBubbleBackground,
      'AI气泡边框': ref.aiBubbleBorder,
      'AI气泡文字': ref.aiBubbleText,
      '主色': ref.themeColor(ColorSemantic.primary),
      '背景色': ref.themeColor(ColorSemantic.background),
    };

    debugPrint('\n=== 颜色调色板 ===');
    for (final entry in colors.entries) {
      final hex = entry.value.toHex();
      debugPrint('${entry.key.padRight(12)}: $hex');
    }
  }
}

/// 颜色转16进制字符串扩展
extension ColorToHexExtension on Color {
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// 输入框边框扩展（全局默认边框）
extension ThemeInput on BuildContext {
  InputBorder get inputBorder {
    // 默认边框：圆角 12，1px 主题边框色
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: themeColor(ColorSemantic.inputBorder),
        width: 1,
      ),
    );
  }

  InputBorder get noBorder {
    return InputBorder.none;
  }

  // 如果你想为不同主题定义不同默认边框，可在这里加逻辑
  // 例如：
  // final uiTheme = ref.read(appThemeProvider).uiTheme;
  // if (uiTheme == UIThemeType.strawberryCandy) return InputBorder.none;
  // return OutlineInputBorder(...);
}
