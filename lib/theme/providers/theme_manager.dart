import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/color_resolver.dart';
import '../core/theme_state.dart';
import '../definitions/theme_registry.dart';
import 'app_theme_provider.dart';
import 'color_override.dart';
import '../core/color_semantics.dart'; // 添加这行

/// 主题管理器 - 提供高级主题操作
class ThemeManager {
  final Ref _ref;

  ThemeManager(this._ref);

  /// 获取当前主题状态
  ThemeState get currentState => _ref.read(appThemeProvider);

  /// 获取当前主题定义
  ThemeDefinition get currentTheme {
    return ThemeRegistry().getThemeByType(currentState.currentUITheme);
  }

  /// 获取当前气泡颜色
  Map<String, Color> get bubbleColors {
    return currentTheme.getBubbleColors(currentState.isDarkMode);
  }

  /// 获取带透明度的气泡颜色
  Map<String, Color> get bubbleColorsWithOpacity {
    return currentTheme.getBubbleColorsWithOpacity(currentState.isDarkMode);
  }

  /// 切换UI主题
  Future<void> switchUITheme(UIThemeType uiTheme) async {
    await _ref.read(appThemeProvider.notifier).updateUITheme(uiTheme);
  }

  /// 切换主题模式（亮/暗/系统）
  Future<void> switchThemeMode(AppThemeMode themeMode) async {
    await _ref.read(appThemeProvider.notifier).updateThemeMode(themeMode);
  }

  /// 应用图片提取色
  Future<void> applyExtractedColors(Map<String, Color> colors) async {
    // await _ref.read(extractedColorsProvider.notifier).updateColors(colors);  // 错误
    final utils = _ref.read(extractedColorsUtilsProvider);
    final extractedColors = utils.convertFromStringMap(colors);
    await utils.updateColors(extractedColors); // 正确
  }

  /// 重置所有主题设置
  Future<void> resetAll() async {
    await _ref.read(appThemeProvider.notifier).resetAll();
  }

  /// 切换亮暗模式
  Future<void> toggleDarkMode() async {
    final currentMode = currentState.themeMode;

    if (currentMode == AppThemeMode.system) {
      // 如果当前是系统模式，切换到与系统相反的模式
      final isCurrentlyDark = currentState.isDarkMode;
      await switchThemeMode(
        isCurrentlyDark ? AppThemeMode.light : AppThemeMode.dark,
      );
    } else if (currentMode == AppThemeMode.light) {
      await switchThemeMode(AppThemeMode.dark);
    } else {
      await switchThemeMode(AppThemeMode.light);
    }
  }

  /// 获取颜色（使用颜色解析器）
  Color getColor(ColorSemantic semantic) {
    return ColorResolver.resolve(
      themeState: currentState,
      semantic: semantic,
    );
  }

  /// 获取多个颜色
  Map<ColorSemantic, Color> getColors(List<ColorSemantic> semantics) {
    return ColorResolver.resolveMultiple(
      themeState: currentState,
      semantics: semantics,
    );
  }

  /// 获取用户气泡装饰
  BoxDecoration getUserBubbleDecoration() {
    final colors = bubbleColorsWithOpacity;
    return BoxDecoration(
      color: colors['userBubbleBackground']!,
      border: Border.all(
        color: colors['userBubbleBorder']!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }

  /// 获取AI气泡装饰
  BoxDecoration getAiBubbleDecoration() {
    final colors = bubbleColorsWithOpacity;
    return BoxDecoration(
      color: colors['aiBubbleBackground']!,
      border: Border.all(
        color: colors['aiBubbleBorder']!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    );
  }

  /// 获取用户气泡文字样式
  TextStyle getUserBubbleTextStyle() {
    final colors = bubbleColors;
    return TextStyle(
      color: colors['userBubbleText']!,
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.normal,
    );
  }

  /// 获取AI气泡文字样式
  TextStyle getAiBubbleTextStyle() {
    final colors = bubbleColors;
    return TextStyle(
      color: colors['aiBubbleText']!,
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.normal,
    );
  }

  /// 判断是否有图片提取色
  bool get hasExtractedColors => currentState.hasExtractedColors;

  /// 判断当前是否为暗色模式
  bool get isDarkMode => currentState.isDarkMode;

  /// 获取当前主题ID
  String get currentThemeId => currentState.currentUITheme.id;

  /// 获取当前主题名称
  String get currentThemeName {
    if (hasExtractedColors) {
      return '图片主题 🎨';
    }
    return currentTheme.name;
  }

  /// 获取所有可用主题
  List<ThemeDefinition> getAllThemes() {
    return ThemeRegistry().getAllThemes(); // 正确
  }

  /// 获取主题预览
  List<ThemePreview> getThemePreviews() {
    return ThemeRegistry().getThemePreviews(isDarkMode); // 正确
  }

  /// 调试信息
  void debugPrintInfo() {
    debugPrint('=== 主题管理器 ===');
    debugPrint('当前主题: ${currentTheme.name}');
    debugPrint('主题模式: ${currentState.themeMode.displayName}');
    debugPrint('暗色模式: $isDarkMode');
    debugPrint('有提取色: $hasExtractedColors');

    debugPrint('\n气泡颜色:');
    final bubbles = bubbleColors;
    for (final entry in bubbles.entries) {
      debugPrint('  ${entry.key}: ${entry.value.toHex()}');
    }

    debugPrint('\n所有可用主题:');
    for (final theme in getAllThemes()) {
      debugPrint('  ${theme.name} (${theme.id})');
    }
  }
}

/// 主题管理器Provider
final themeManagerProvider = Provider<ThemeManager>((ref) {
  return ThemeManager(ref);
});

/// 简化Provider：获取当前主题装饰
final currentThemeDecorationsProvider = Provider<ThemeDecorations>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);

  final colors = theme.getBubbleColorsWithOpacity(state.isDarkMode);
  final textColors = theme.getBubbleColors(state.isDarkMode);

  return ThemeDecorations(
    userBubbleDecoration: BoxDecoration(
      color: colors['userBubbleBackground']!,
      border: Border.all(
        color: colors['userBubbleBorder']!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    aiBubbleDecoration: BoxDecoration(
      color: colors['aiBubbleBackground']!,
      border: Border.all(
        color: colors['aiBubbleBorder']!,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    userBubbleTextStyle: TextStyle(
      color: textColors['userBubbleText']!,
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.normal,
    ),
    aiBubbleTextStyle: TextStyle(
      color: textColors['aiBubbleText']!,
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.normal,
    ),
  );
});

/// 主题装饰数据类
class ThemeDecorations {
  final BoxDecoration userBubbleDecoration;
  final BoxDecoration aiBubbleDecoration;
  final TextStyle userBubbleTextStyle;
  final TextStyle aiBubbleTextStyle;

  const ThemeDecorations({
    required this.userBubbleDecoration,
    required this.aiBubbleDecoration,
    required this.userBubbleTextStyle,
    required this.aiBubbleTextStyle,
  });
}

/// 主题系统工具
class ThemeSystemUtils {
  /// 初始化主题系统
  static Future<void> initialize(WidgetRef ref) async {
    debugPrint('正在初始化主题系统...');

    try {
      // 验证主题系统
      final errors = ThemeUtils.validateThemeSystem();
      if (errors.isNotEmpty) {
        debugPrint('主题系统验证有警告:');
        for (final entry in errors.entries) {
          debugPrint('  ${entry.key}: ${entry.value.join(', ')}');
        }
      }

      // 主题状态会在 AppThemeNotifier 构造函数中自动加载
      // 不需要手动调用私有方法
      debugPrint('主题系统初始化完成 ✓');
    } catch (e) {
      debugPrint('主题系统初始化失败: $e');
    }
  }

  /// 切换主题
  static Future<void> switchTheme({
    required WidgetRef ref,
    UIThemeType? uiTheme,
    AppThemeMode? themeMode,
  }) async {
    final manager = ref.read(themeManagerProvider);

    if (uiTheme != null) {
      await manager.switchUITheme(uiTheme);
    }

    if (themeMode != null) {
      await manager.switchThemeMode(themeMode);
    }
  }

  /// 应用测试主题
  static Future<void> applyTestTheme(WidgetRef ref) async {
    final manager = ref.read(themeManagerProvider);

    // 切换到草莓糖心主题
    await manager.switchUITheme(UIThemeType.strawberryCandy);

    // 应用测试颜色
    final utils = ref.read(extractedColorsUtilsProvider);
    await utils.applyTestColor(const Color.fromARGB(255, 217, 77, 136));

    debugPrint('测试主题已应用');
  }

  /// 重置主题
  static Future<void> resetTheme(WidgetRef ref) async {
    await ref.read(appThemeProvider.notifier).resetAll();
    debugPrint('主题已重置');
  }

  /// 打印调试信息
  static void debugPrintThemeInfo(WidgetRef ref) {
    final manager = ref.read(themeManagerProvider);
    manager.debugPrintInfo();

    // 打印提取颜色
    final extractedColors = ref.read(extractedColorsProvider);
    if (extractedColors != null) {
      debugPrint('\n提取颜色:');
      for (final entry in extractedColors.entries) {
        debugPrint('  ${entry.key}: ${entry.value.toHex()}');
      }
    }
  }
}
