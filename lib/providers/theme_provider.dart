// lib/providers/theme_provider.dart - 修复版
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';

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
      'custom_primary',
      colors['primary']!.toARGB32().toRadixString(16), // ← 改这里
    );
  }

  Future<void> reset() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_primary');
  }
}

// ✅ 移除 family，使用普通 provider
final pageThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final custom = ref.watch(customColorsProvider);
  final primaryOverride = custom?['primary'];

  // 获取系统主题（通过 GlobalKey）
  final context = ref.read(appContextProvider);
  final platformBrightness = MediaQuery.platformBrightnessOf(context);
  final systemDark = platformBrightness == Brightness.dark;

  // fallback 静态主题
  var light = AppTheme.lightTheme;
  var dark = AppTheme.darkTheme;

  try {
    if (primaryOverride != null) {
      light = light.copyWith(
        colorScheme: light.colorScheme.copyWith(
          primary: primaryOverride,
          secondary: primaryOverride.withAlpha((0.8 * 255).round()),
          surface: primaryOverride.withAlpha((0.02 * 255).round()),
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
          secondary: primaryOverride.withAlpha((0.8 * 255).round()),
          surface: primaryOverride.withAlpha((0.04 * 255).round()),
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
  } catch (e) {
    debugPrint('Theme 计算异常，使用 fallback: $e');
  }

  // 根据主题模式选择
  if (mode == ThemeMode.dark) {
    return dark;
  } else if (mode == ThemeMode.light) {
    return light;
  } else {
    // 跟随系统
    return systemDark ? dark : light;
  }
});

// ✅ 添加全局 context provider（用于获取 MediaQuery）
final appContextProvider = Provider<BuildContext>((ref) {
  throw UnimplementedError('appContextProvider 需要在 main.dart 中设置');
});
