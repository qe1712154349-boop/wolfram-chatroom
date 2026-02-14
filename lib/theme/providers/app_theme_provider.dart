import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../core/theme_state.dart';
import '../core/color_semantics.dart';
import '../definitions/theme_registry.dart';
import 'color_override.dart';
import 'brightness_provider.dart';
import 'theme_memory_manager.dart';

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
          _updateExtractedColorsInCurrentMemory(next);
        }
      },
    );
  }

  /// ========== 加载和初始化 ==========

  Future<void> _loadSavedSettings() async {
    try {
      final manager = _ref.read(themeMemoryManagerProvider);

      // 并行加载亮暗两套记忆
      final lightMemory =
          await manager.loadMemoryForBrightness(Brightness.light);
      final darkMemory = await manager.loadMemoryForBrightness(Brightness.dark);

      // 加载主题模式
      final themeModeStr = await _storage.getThemeMode();
      final themeMode = _themeModeFromString(themeModeStr);

      // 更新状态
      state = state.copyWith(
        lightMemory: lightMemory,
        darkMemory: darkMemory,
        themeMode: themeMode,
      );

      // 计算实际亮度
      _updateEffectiveBrightness();

      debugPrint('✅ 主题设置加载完成');
    } catch (e) {
      debugPrint('❌ 加载主题设置失败: $e');
    }
  }

  /// ========== UI主题切换（亮色/暗色分别记忆） ==========

  /// 切换UI主题 - 更新当前 brightness 对应的 memory
  Future<void> updateUITheme(UIThemeType uiTheme) async {
    try {
      final manager = _ref.read(themeMemoryManagerProvider);
      final currentMemory = state.currentMemory;

      // 更新当前 memory（根据当前 brightness）
      final updatedMemory =
          manager.updateThemeSwitchInMemory(currentMemory, uiTheme);

      // 保存到本地
      await manager.updateMemoryForBrightness(
        brightness: state.effectiveBrightness,
        newMemory: updatedMemory,
      );

      // 更新对应的 state（亮或暗）
      if (state.isDarkMode) {
        state = state.copyWith(darkMemory: updatedMemory);
      } else {
        state = state.copyWith(lightMemory: updatedMemory);
      }

      debugPrint(
          '✅ UI主题已更新: ${uiTheme.displayName} (${state.effectiveBrightness.name})');
    } catch (e) {
      debugPrint('❌ 更新UI主题失败: $e');
    }
  }

  /// ========== 提取图片色（亮色/暗色分别记忆） ==========

  /// 当 extractedColorsProvider 变化时，更新当前 memory
  Future<void> _updateExtractedColorsInCurrentMemory(
    Map<ExtractedColorType, Color> extractedColors,
  ) async {
    try {
      final manager = _ref.read(themeMemoryManagerProvider);
      final currentMemory = state.currentMemory;

      // 更新当前 memory（根据当前 brightness）
      final updatedMemory = manager.updateImageExtractInMemory(
        currentMemory,
        extractedColors,
      );

      // 保存到本地
      await manager.updateMemoryForBrightness(
        brightness: state.effectiveBrightness,
        newMemory: updatedMemory,
      );

      // 更新对应的 state（亮或暗）
      if (state.isDarkMode) {
        state = state.copyWith(darkMemory: updatedMemory);
      } else {
        state = state.copyWith(lightMemory: updatedMemory);
      }

      debugPrint('✅ 图片提取色已记忆 (${state.effectiveBrightness.name} 模式)');
    } catch (e) {
      debugPrint('❌ 记忆提取色失败: $e');
    }
  }

  /// ========== 主题模式切换（亮/暗/系统） ==========

  /// 更新主题模式（亮/暗/系统）
  /// 🔑 关键：切换时自动应用"另一个 brightness"对应的 memory
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    try {
      // 保存到本地存储
      final modeString = _themeModeToString(themeMode);
      await _storage.saveThemeMode(modeString);

      // 更新状态
      state = state.copyWith(themeMode: themeMode);

      // 更新实际亮度
      _updateEffectiveBrightness();

      debugPrint('✅ 主题模式已更新: ${themeMode.displayName}');
    } catch (e) {
      debugPrint('❌ 更新主题模式失败: $e');
    }
  }

  /// 更新实际亮度（计算 light/dark/system 的结果）
  void _updateEffectiveBrightness() {
    final platformBrightness = _ref.read(platformBrightnessProvider);
    final effectiveBrightness = calculateEffectiveBrightness(
      state.themeMode,
      platformBrightness,
    );

    state = state.copyWith(effectiveBrightness: effectiveBrightness);
  }

  /// ========== 重置 ==========

  /// 重置当前 brightness 对应的主题为默认
  Future<void> resetCurrentBrightness() async {
    try {
      final manager = _ref.read(themeMemoryManagerProvider);
      final defaultMemory = manager.resetMemoryToDefault();

      // 保存
      await manager.updateMemoryForBrightness(
        brightness: state.effectiveBrightness,
        newMemory: defaultMemory,
      );

      // 更新 state
      if (state.isDarkMode) {
        state = state.copyWith(darkMemory: defaultMemory);
      } else {
        state = state.copyWith(lightMemory: defaultMemory);
      }

      // 清除提取色
      final utils = _ref.read(extractedColorsUtilsProvider);
      await utils.reset();

      debugPrint('✅ 已重置 ${state.effectiveBrightness.name} 模式');
    } catch (e) {
      debugPrint('❌ 重置失败: $e');
    }
  }

  /// 重置全部（亮+暗）
  Future<void> resetAll() async {
    try {
      final manager = _ref.read(themeMemoryManagerProvider);
      final defaultMemory = manager.resetMemoryToDefault();

      // 保存亮暗两套
      await Future.wait([
        manager.updateMemoryForBrightness(
          brightness: Brightness.light,
          newMemory: defaultMemory,
        ),
        manager.updateMemoryForBrightness(
          brightness: Brightness.dark,
          newMemory: defaultMemory,
        ),
      ]);

      // 更新 state
      state = state.copyWith(
        lightMemory: defaultMemory,
        darkMemory: defaultMemory,
      );

      // 清除提取色
      final utils = _ref.read(extractedColorsUtilsProvider);
      await utils.reset();

      debugPrint('✅ 已重置所有主题设置');
    } catch (e) {
      debugPrint('❌ 全局重置失败: $e');
    }
  }

  /// ========== 工具方法 ==========

  /// 获取当前主题定义
  ThemeDefinition get currentThemeDefinition {
    return ThemeRegistry().getThemeByType(state.currentUITheme);
  }

  /// 获取当前气泡颜色
  Map<String, Color> get currentBubbleColors {
    return currentThemeDefinition.getBubbleColors(state.isDarkMode);
  }

  /// 获取带透明度的气泡颜色
  Map<String, Color> get currentBubbleColorsWithOpacity {
    return currentThemeDefinition.getBubbleColorsWithOpacity(state.isDarkMode);
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

  /// 调试信息
  void debugPrintState() {
    debugPrint('=== 主题状态 ===');
    debugPrint('当前亮度: ${state.isDarkMode ? "暗色" : "亮色"}');
    debugPrint('主题模式: ${state.themeMode.displayName}');
    debugPrint('\n亮色记忆: ${state.lightMemory}');
    debugPrint('暗色记忆: ${state.darkMemory}');
  }
}

/// ========== 简化Provider ==========

final currentThemeProvider = Provider<ThemeDefinition>((ref) {
  final state = ref.watch(appThemeProvider);
  return ThemeRegistry().getThemeByType(state.currentUITheme);
});

final currentBubbleColorsProvider = Provider<Map<String, Color>>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);
  return theme.getBubbleColors(state.isDarkMode);
});

final currentBubbleColorsWithOpacityProvider =
    Provider<Map<String, Color>>((ref) {
  final state = ref.watch(appThemeProvider);
  final theme = ref.watch(currentThemeProvider);
  return theme.getBubbleColorsWithOpacity(state.isDarkMode);
});

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
