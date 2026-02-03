// lib/theme/theme_facade.dart
// 主题系统的友好 facade - 只 import barrel，不直接 import 具体文件

import 'theme.dart' as theme; // import 自己的 barrel

class ThemeSystem {
  static Map<String, List<String>> validate() {
    return theme.ThemeUtils.validateThemeSystem();
  }

  static void debugPrintAllThemes() {
    theme.ThemeRegistry().debugPrintAllThemes();
  }

  static void debugPrintAllColors({bool isDark = false}) {
    theme.ThemeUtils.debugPrintAllThemeColors(isDark);
  }

  static List<theme.ThemeDefinition> getAllThemes() {
    return theme.ThemeRegistry().getAllThemes();
  }
}

class Theme {
  static theme.ColorResolver get resolver => theme.ColorResolver();

  static theme.ColorUtils get colors => theme.ColorUtils();

  static theme.BrightnessUtils get brightness => theme.BrightnessUtils();

  static theme.ThemeUtils get utils => theme.ThemeUtils();

  static theme.ThemeRegistry get registry => theme.ThemeRegistry();
}
