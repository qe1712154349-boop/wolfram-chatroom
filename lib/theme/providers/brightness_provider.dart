import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme_state.dart';
import 'app_theme_provider.dart';
import '../../utils/logger.dart'; // 添加日志导入

/// 平台亮度Provider - 监听系统亮度变化
final platformBrightnessProvider = StateProvider<Brightness>((ref) {
  log.i('🌞 [platformBrightnessProvider] 初始化，默认值: light');
  return Brightness.light;
});

/// 有效亮度Provider - 根据主题模式计算的实际亮度
final effectiveBrightnessProvider = Provider<Brightness>((ref) {
  final themeState = ref.watch(appThemeProvider);
  log.i(
      '🌞 [effectiveBrightnessProvider] 计算有效亮度: ${themeState.effectiveBrightness.name}');
  return themeState.effectiveBrightness;
});

/// 暗色模式Provider - 方便使用的布尔值
final isDarkModeProvider = Provider<bool>((ref) {
  final brightness = ref.watch(effectiveBrightnessProvider);
  return brightness == Brightness.dark;
});

/// 亮度变化监听器 - 用于在Widget中监听系统亮度变化
class BrightnessListener extends StateNotifier<Brightness> {
  BrightnessListener() : super(Brightness.light);

  void update(Brightness brightness) {
    state = brightness;
  }
}

final brightnessListenerProvider =
    StateNotifierProvider<BrightnessListener, Brightness>(
  (ref) => BrightnessListener(),
);

/// 亮度工具类
class BrightnessUtils {
  /// 获取当前主题模式的实际亮度
  static Brightness getEffectiveBrightness(
    AppThemeMode themeMode,
    Brightness platformBrightness,
  ) {
    switch (themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return platformBrightness;
    }
  }

  /// 判断是否为暗色模式
  static bool isDarkMode(Brightness brightness) {
    return brightness == Brightness.dark;
  }

  /// 获取合适的文字颜色
  static Color getTextColorForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// 获取合适的背景颜色
  static Color getBackgroundColorForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);
  }

  /// 调整颜色以适应亮度
  static Color adjustColorForBrightness(Color color, Brightness brightness) {
    if (brightness == Brightness.dark) {
      // 暗色模式下降低亮度
      final hsl = HSLColor.fromColor(color);
      final adjustedLightness = hsl.lightness * 0.7;
      return hsl.withLightness(adjustedLightness.clamp(0.0, 1.0)).toColor();
    }
    return color;
  }

  /// 创建对比色
  static Color getContrastColor(Color color, Brightness brightness) {
    final luminance = color.computeLuminance();

    if (brightness == Brightness.dark) {
      return luminance > 0.3 ? Colors.black : Colors.white;
    } else {
      return luminance > 0.6 ? Colors.black : Colors.white;
    }
  }
}

/// 亮度扩展方法
extension BrightnessExtensions on Brightness {
  /// 获取显示名称
  String get displayName {
    return this == Brightness.dark ? '暗色' : '亮色';
  }

  /// 获取图标
  IconData get icon {
    return this == Brightness.dark ? Icons.dark_mode : Icons.light_mode;
  }

  /// 是否是暗色模式
  bool get isDark => this == Brightness.dark;

  /// 是否是亮色模式
  bool get isLight => this == Brightness.light;

  /// 获取相反亮度
  Brightness get opposite {
    return this == Brightness.dark ? Brightness.light : Brightness.dark;
  }
}
