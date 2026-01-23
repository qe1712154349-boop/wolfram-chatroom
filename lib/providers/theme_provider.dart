// lib/providers/theme_provider.dart
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
        'custom_primary', colors['primary']!.value.toRadixString(16));
  }

  Future<void> reset() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_primary');
  }
}

final dynamicAppThemeProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final custom = ref.watch(customColorsProvider);
  final primaryOverride = custom?['primary'];

  // fallback：永远保证 ThemeData 非 null
  ThemeData light = AppTheme.lightTheme;
  ThemeData dark = AppTheme.darkTheme;

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
  } catch (e, stack) {
    debugPrint('Theme 计算异常，使用 fallback: $e\n$stack');
    // fallback 已设置，不再抛异常
  }

  return mode == ThemeMode.dark ? dark : light;
});
