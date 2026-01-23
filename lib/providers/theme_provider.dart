// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart'; // 用于 fallback 颜色

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final customColorsProvider =
    StateNotifierProvider<CustomColorsNotifier, Map<String, Color>?>(
  (ref) => CustomColorsNotifier(),
);

class CustomColorsNotifier extends StateNotifier<Map<String, Color>?> {
  CustomColorsNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryHex = prefs.getString('custom_primary');
    if (primaryHex != null && primaryHex.isNotEmpty) {
      try {
        state = {'primary': Color(int.parse(primaryHex, radix: 16))};
      } catch (_) {}
    }
  }

  Future<void> updateColors(Map<String, Color> colors) async {
    state = colors;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'custom_primary', colors['primary']!.value.toRadixString(16));
  }

  Future<void> reset() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_primary');
  }
}

// 动态 ThemeData 生成器（全部适配）
final dynamicAppThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final custom = ref.watch(customColorsProvider);
  final primaryOverride = custom?['primary'];

  final seedColor = primaryOverride ?? AppTheme.primaryLight;

  // 基础 light/dark
  var light = AppTheme.lightTheme;
  var dark = AppTheme.darkTheme;

  // 动态覆盖 colorScheme
  if (primaryOverride != null) {
    light = light.copyWith(
      colorScheme: light.colorScheme.copyWith(
        primary: primaryOverride,
        secondary: primaryOverride.withValues(alpha: 0.8),
        background: primaryOverride.withValues(alpha: 0.05),
        surface: primaryOverride.withValues(alpha: 0.02),
      ),
      primaryColor: primaryOverride,
      switchTheme: light.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primaryOverride
                : light.switchTheme.thumbColor!.resolve({})),
      ),
    );

    dark = dark.copyWith(
      colorScheme: dark.colorScheme.copyWith(
        primary: primaryOverride,
        secondary: primaryOverride.withValues(alpha: 0.8),
        background: primaryOverride.withValues(alpha: 0.08),
        surface: primaryOverride.withValues(alpha: 0.04),
      ),
      primaryColor: primaryOverride,
      switchTheme: dark.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primaryOverride
                : dark.switchTheme.thumbColor!.resolve({})),
      ),
    );
  }

  // 覆盖气泡等自定义颜色（通过扩展方法或全局访问）
  // 如果需要更彻底，可在 getAiBubbleColor 等方法里检查 custom

  return mode == ThemeMode.dark ? dark : light;
});
