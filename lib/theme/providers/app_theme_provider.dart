import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../core/theme_state.dart';
import '../definitions/theme_registry.dart';
import 'color_override.dart';
import 'brightness_provider.dart';
import '../core/color_semantics.dart'; // 添加这行

/// 主主题Provider - 管理整个应用的主题状态
final appThemeProvider = StateNotifierProvider<AppThemeNotifier, ThemeState>(
  (ref) {
    return AppThemeNotifier(ref);
  },
);

/// 主题状态Notifier
class AppThemeNotifier extends StateNotifier<ThemeState> {
  final Ref _ref;
  final StorageService _storage = StorageService();

  AppThemeNotifier(this._ref) : super(ThemeState.initial()) {
    // 初始化时加载保存的设置
    _loadSavedSettings();

    // 监听平台亮度变化
    _ref.listen<Brightness>(
      platformBrightnessProvider,
      (previous, next) {
        _updateEffectiveBrightness();
      },
    );

    // 监听图片提取色变化
    _ref.listen<Map<ExtractedColorType, Color>?>(
      extractedColorsProvider,
      (previous, next) {
        if (next != null) {
          state = state.copyWith(extractedColors: next);
        } else {
          state = state.copyWith(extractedColors: null);
        }
      },
    );
  }

  /// 加载保存的设置
  Future<void> _loadSavedSettings() async {
    try {
      // 加载UI主题设置
      final themeString = await _storage.getUITheme();
      final uiTheme = UIThemeTypeExtensions.fromString(themeString);

      // 加载主题模式设置
      final themeModeString = await _storage.getThemeMode();
      final themeMode = _themeModeFromString(themeModeString);

      // 更新状态
      state = state.copyWith(
        uiTheme: uiTheme,
        themeMode: themeMode,
      );

      // 更新实际亮度
      _updateEffectiveBrightness();
    } catch (e) {
      debugPrint('加载主题设置失败: $e');
      // 保持默认状态
    }
  }

  /// 更新UI主题
  Future<void> updateUITheme(UIThemeType uiTheme) async {
    try {
      // 保存到本地存储
      final themeString = uiTheme.id;
      await _storage.saveUITheme(themeString);

      // 更新状态
      state = state.copyWith(uiTheme: uiTheme);

      debugPrint('UI主题已更新: ${uiTheme.displayName}');
    } catch (e) {
      debugPrint('更新UI主题失败: $e');
    }
  }

  /// 更新主题模式（亮/暗/系统）
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    try {
      // 保存到本地存储
      final modeString = _themeModeToString(themeMode);
      await _storage.saveThemeMode(modeString);

      // 更新状态
      state = state.copyWith(themeMode: themeMode);

      // 更新实际亮度
      _updateEffectiveBrightness();

      debugPrint('主题模式已更新: ${themeMode.displayName}');
    } catch (e) {
      debugPrint('更新主题模式失败: $e');
    }
  }

  /// 更新实际亮度
  void _updateEffectiveBrightness() {
    final platformBrightness = _ref.read(platformBrightnessProvider);
    final effectiveBrightness = calculateEffectiveBrightness(
      state.themeMode,
      platformBrightness,
    );

    state = state.copyWith(effectiveBrightness: effectiveBrightness);
  }

  /// 重置所有主题设置
  Future<void> reset() async {
    try {
      // 清除图片提取色
      // 改为：
      final utils = _ref.read(extractedColorsUtilsProvider);
      await utils.reset();

      // 重置到默认设置
      await updateUITheme(UIThemeType.defaultTheme);
      await updateThemeMode(AppThemeMode.system);

      debugPrint('主题设置已重置');
    } catch (e) {
      debugPrint('重置主题设置失败: $e');
    }
  }

// 第138行附近：
  /// 获取当前主题定义
  ThemeDefinition get currentThemeDefinition {
    // return ThemeRegistry.getThemeByType(state.uiTheme);  // 错误：静态调用
    return ThemeRegistry().getThemeByType(state.uiTheme); // 正确：实例调用
  }

  /// 获取当前气泡颜色
  Map<String, Color> get currentBubbleColors {
    return currentThemeDefinition.getBubbleColors(state.isDarkMode);
  }

  /// 获取带透明度的气泡颜色
  Map<String, Color> get currentBubbleColorsWithOpacity {
    return currentThemeDefinition.getBubbleColorsWithOpacity(state.isDarkMode);
  }

  /// 调试信息
  void debugPrintState() {
    debugPrint('=== 主题状态 ===');
    debugPrint('UI主题: ${state.uiTheme.displayName}');
    debugPrint('主题模式: ${state.themeMode.displayName}');
    debugPrint('实际亮度: ${state.isDarkMode ? "暗色" : "亮色"}');
    debugPrint('有图片提取色: ${state.hasExtractedColors}');

    if (state.hasExtractedColors) {
      debugPrint('图片提取色:');
      for (final entry in state.extractedColors!.entries) {
        debugPrint('  ${entry.key}: ${entry.value.toHex()}');
      }
    }

    debugPrint('\n当前气泡颜色:');
    final bubbleColors = currentBubbleColors;
    for (final entry in bubbleColors.entries) {
      debugPrint('  ${entry.key}: ${entry.value.toHex()}');
    }
  }

  /// 字符串转ThemeMode
  AppThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  /// ThemeMode转字符串
  String _themeModeToString(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }
}

// 第201行附近：
/// 简化Provider：获取当前主题定义
final currentThemeProvider = Provider<ThemeDefinition>((ref) {
  final state = ref.watch(appThemeProvider);
  // return ThemeRegistry.getThemeByType(state.uiTheme);  // 错误：静态调用
  return ThemeRegistry().getThemeByType(state.uiTheme); // 正确：实例调用
});

/// 简化Provider：获取当前气泡颜色
final currentBubbleColorsProvider = Provider<Map<String, Color>>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);
  return theme.getBubbleColors(state.isDarkMode);
});

/// 简化Provider：获取带透明度的气泡颜色
final currentBubbleColorsWithOpacityProvider =
    Provider<Map<String, Color>>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);
  return theme.getBubbleColorsWithOpacity(state.isDarkMode);
});

/// 简化Provider：获取用户气泡装饰
final userBubbleDecorationProvider = Provider<BoxDecoration>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);

  final colors = theme.getBubbleColorsWithOpacity(state.isDarkMode);

  return BoxDecoration(
    color: colors['userBubbleBackground']!,
    border: Border.all(
      color: colors['userBubbleBorder']!,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(18),
  );
});

/// 简化Provider：获取AI气泡装饰
final aiBubbleDecorationProvider = Provider<BoxDecoration>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);

  final colors = theme.getBubbleColorsWithOpacity(state.isDarkMode);

  return BoxDecoration(
    color: colors['aiBubbleBackground']!,
    border: Border.all(
      color: colors['aiBubbleBorder']!,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(18),
  );
});

/// 简化Provider：获取用户气泡文字样式
final userBubbleTextStyleProvider = Provider<TextStyle>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);

  final colors = theme.getBubbleColors(state.isDarkMode);

  return TextStyle(
    color: colors['userBubbleText']!,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.normal,
  );
});

/// 简化Provider：获取AI气泡文字样式
final aiBubbleTextStyleProvider = Provider<TextStyle>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);

  final colors = theme.getBubbleColors(state.isDarkMode);

  return TextStyle(
    color: colors['aiBubbleText']!,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.normal,
  );
});

/// 主题相关的工具Provider
final themeUtilsProvider = Provider<ThemeUtils>((ref) {
  return ThemeUtils();
});

/// 主题系统初始化Provider
final themeSystemInitializedProvider = FutureProvider<bool>((ref) async {
  try {
    // 等待主题状态加载完成
    await ref.watch(appThemeProvider.notifier)._loadSavedSettings();

    // 验证主题系统
    final errors = ThemeUtils.validateThemeSystem();

    if (errors.isNotEmpty) {
      debugPrint('主题系统初始化有警告: $errors');
      return false;
    }

    debugPrint('主题系统初始化完成 ✓');
    return true;
  } catch (e) {
    debugPrint('主题系统初始化失败: $e');
    return false;
  }
});
