import 'package:flutter/material.dart';
import 'color_semantics.dart';

/// 主题模式：亮色、暗色、跟随系统
enum AppThemeMode {
  light,
  dark,
  system,
}

// 🆕 只保留这一个扩展（包含 displayName 和 icon）
extension AppThemeModeExtensions on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return '亮色';
      case AppThemeMode.dark:
        return '暗色';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_suggest;
    }
  }
}

/// UI主题类型
enum UIThemeType {
  defaultTheme,
  strawberryCandy,
  pickleMilk,
}

extension UIThemeTypeExtensions on UIThemeType {
  String get id {
    switch (this) {
      case UIThemeType.defaultTheme:
        return 'default';
      case UIThemeType.strawberryCandy:
        return 'strawberryCandy';
      case UIThemeType.pickleMilk:
        return 'pickleMilk';
    }
  }

  String get displayName {
    switch (this) {
      case UIThemeType.defaultTheme:
        return '默认主题';
      case UIThemeType.strawberryCandy:
        return '草莓糖心🍓';
      case UIThemeType.pickleMilk:
        return '酸菜牛奶🥛';
    }
  }

  String get description {
    switch (this) {
      case UIThemeType.defaultTheme:
        return '清爽的粉色系设计';
      case UIThemeType.strawberryCandy:
        return '少女心满满的草莓风格';
      case UIThemeType.pickleMilk:
        return '优雅的酸菜牛奶配色';
    }
  }

  IconData get icon {
    switch (this) {
      case UIThemeType.defaultTheme:
        return Icons.favorite;
      case UIThemeType.strawberryCandy:
        return Icons.cake;
      case UIThemeType.pickleMilk:
        return Icons.local_cafe;
    }
  }

  static UIThemeType fromString(String value) {
    switch (value) {
      case 'strawberryCandy':
        return UIThemeType.strawberryCandy;
      case 'pickleMilk':
        return UIThemeType.pickleMilk;
      default:
        return UIThemeType.defaultTheme;
    }
  }
}

/// ============ 新增：独立的主题记忆对象 ============

/// 【核心】单个 Brightness 下的主题记忆
/// 记录：最后选的主题 / 最后提取的图片色 / 最后操作类型
@immutable
class ThemeMemory {
  final UIThemeType uiTheme; // 最后选的主题
  final Map<ExtractedColorType, Color>? extractedColors; // 最后提取的图片色
  final ThemeMemoryOperationType lastOperationType; // 最后操作类型

  const ThemeMemory({
    required this.uiTheme,
    this.extractedColors,
    required this.lastOperationType,
  });

  factory ThemeMemory.initial() {
    return ThemeMemory(
      uiTheme: UIThemeType.defaultTheme,
      extractedColors: null,
      lastOperationType: ThemeMemoryOperationType.themeSwitch,
    );
  }

  ThemeMemory copyWith({
    UIThemeType? uiTheme,
    Map<ExtractedColorType, Color>? extractedColors,
    ThemeMemoryOperationType? lastOperationType,
  }) {
    return ThemeMemory(
      uiTheme: uiTheme ?? this.uiTheme,
      extractedColors: extractedColors ?? this.extractedColors,
      lastOperationType: lastOperationType ?? this.lastOperationType,
    );
  }

  bool get hasExtractedColors =>
      extractedColors != null && extractedColors!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeMemory &&
        other.uiTheme == uiTheme &&
        other.lastOperationType == lastOperationType &&
        _mapsEqual(other.extractedColors, extractedColors);
  }

  @override
  int get hashCode => Object.hash(
        uiTheme,
        lastOperationType,
        _mapHashCode(extractedColors),
      );

  static bool _mapsEqual(
      Map<ExtractedColorType, Color>? a, Map<ExtractedColorType, Color>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }

  static int _mapHashCode(Map<ExtractedColorType, Color>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'ThemeMemory(uiTheme: $uiTheme, hasExtracted: $hasExtractedColors, lastOp: $lastOperationType)';
  }
}

/// 最后操作类型（核心：用这个决定"记住什么"）
enum ThemeMemoryOperationType {
  themeSwitch, // 最后一次是切主题
  imageExtract, // 最后一次是提取图片
}

/// ============ 新增：全局主题总状态 ============

/// 【核心】应用的完整主题状态
/// 包含：亮色记忆、暗色记忆、当前 brightness、主题模式
@immutable
class ThemeState {
  final ThemeMemory lightMemory; // 亮色模式下的记忆
  final ThemeMemory darkMemory; // 暗色模式下的记忆
  final AppThemeMode themeMode; // 亮/暗/系统
  final Brightness effectiveBrightness; // 实际生效的亮度

  const ThemeState({
    required this.lightMemory,
    required this.darkMemory,
    required this.themeMode,
    required this.effectiveBrightness,
  });

  factory ThemeState.initial() {
    return ThemeState(
      lightMemory: ThemeMemory.initial(),
      darkMemory: ThemeMemory.initial(),
      themeMode: AppThemeMode.system,
      effectiveBrightness: Brightness.light,
    );
  }

  ThemeState copyWith({
    ThemeMemory? lightMemory,
    ThemeMemory? darkMemory,
    AppThemeMode? themeMode,
    Brightness? effectiveBrightness,
  }) {
    return ThemeState(
      lightMemory: lightMemory ?? this.lightMemory,
      darkMemory: darkMemory ?? this.darkMemory,
      themeMode: themeMode ?? this.themeMode,
      effectiveBrightness: effectiveBrightness ?? this.effectiveBrightness,
    );
  }

  /// 获取当前 brightness 对应的 memory
  ThemeMemory get currentMemory => isDarkMode ? darkMemory : lightMemory;

  bool get isDarkMode => effectiveBrightness == Brightness.dark;

  /// 获取当前生效的主题配置
  UIThemeType get currentUITheme => currentMemory.uiTheme;

  Map<ExtractedColorType, Color>? get currentExtractedColors =>
      currentMemory.extractedColors;

  bool get hasExtractedColors => currentMemory.hasExtractedColors;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.lightMemory == lightMemory &&
        other.darkMemory == darkMemory &&
        other.themeMode == themeMode &&
        other.effectiveBrightness == effectiveBrightness;
  }

  @override
  int get hashCode => Object.hash(
        lightMemory,
        darkMemory,
        themeMode,
        effectiveBrightness,
      );

  @override
  String toString() {
    return 'ThemeState(isDark: $isDarkMode, light: $lightMemory, dark: $darkMemory)';
  }
}

/// 计算实际亮度模式
Brightness calculateEffectiveBrightness(
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
