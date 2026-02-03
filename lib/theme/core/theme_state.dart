import 'package:flutter/material.dart';
import 'color_semantics.dart';

/// 主题模式：亮色、暗色、跟随系统
enum AppThemeMode {
  light, // 强制亮色
  dark, // 强制暗色
  system, // 跟随系统
}

/// 扩展方法：方便地获取枚举属性
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

/// UI主题类型：用户选择的视觉风格
enum UIThemeType {
  defaultTheme, // 默认主题（你的粉色系）
  strawberryCandy, // 草莓糖心🍓
  pickleMilk, // 酸菜牛奶🥛
}

/// 扩展方法：方便地获取枚举属性
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

  /// 从字符串转换
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
} // <--- 这里添加这个 } 来关闭 UIThemeTypeExtensions 扩展

/// 主题状态 - 包含所有主题相关的状态
@immutable
class ThemeState {
  final UIThemeType uiTheme; // 用户选择的UI主题
  final AppThemeMode themeMode; // 亮/暗/系统模式
  final Map<ExtractedColorType, Color>? extractedColors; // 图片提取的颜色
  final Brightness effectiveBrightness; // 实际生效的亮度模式

  const ThemeState({
    required this.uiTheme,
    required this.themeMode,
    this.extractedColors,
    required this.effectiveBrightness,
  });

  /// 创建初始状态
  factory ThemeState.initial() {
    return ThemeState(
      uiTheme: UIThemeType.defaultTheme,
      themeMode: AppThemeMode.system,
      extractedColors: null,
      effectiveBrightness: Brightness.light, // 默认为亮色
    );
  }

  /// 复制并更新部分属性
  ThemeState copyWith({
    UIThemeType? uiTheme,
    AppThemeMode? themeMode,
    Map<ExtractedColorType, Color>? extractedColors,
    Brightness? effectiveBrightness,
  }) {
    return ThemeState(
      uiTheme: uiTheme ?? this.uiTheme,
      themeMode: themeMode ?? this.themeMode,
      extractedColors: extractedColors ?? this.extractedColors,
      effectiveBrightness: effectiveBrightness ?? this.effectiveBrightness,
    );
  }

  /// 判断是否有图片提取的颜色
  bool get hasExtractedColors =>
      extractedColors != null && extractedColors!.isNotEmpty;

  /// 判断是否为暗色模式
  bool get isDarkMode => effectiveBrightness == Brightness.dark;

  /// 获取当前主题ID
  String get themeId => uiTheme.id;

  /// 获取显示名称
  String get displayName {
    if (hasExtractedColors) {
      return '图片主题 🎨';
    }
    return uiTheme.displayName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeState &&
        other.uiTheme == uiTheme &&
        other.themeMode == themeMode &&
        other.effectiveBrightness == effectiveBrightness &&
        _mapsEqual(other.extractedColors, extractedColors);
  }

  @override
  int get hashCode {
    return Object.hash(
      uiTheme,
      themeMode,
      effectiveBrightness,
      _mapHashCode(extractedColors),
    );
  }

  @override
  String toString() {
    return 'ThemeState(uiTheme: $uiTheme, themeMode: $themeMode, '
        'hasExtractedColors: $hasExtractedColors, isDarkMode: $isDarkMode)';
  }

  /// 比较两个颜色Map是否相等
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

  /// 计算颜色Map的hashCode
  static int _mapHashCode(Map<ExtractedColorType, Color>? map) {
    if (map == null) return 0;

    int hash = 0;
    for (final entry in map.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }
}

/// 主题状态变化监听器
typedef ThemeStateListener = void Function(ThemeState state);

/// 主题状态变化通知
class ThemeStateNotifier {
  ThemeState _state;
  final List<ThemeStateListener> _listeners = [];

  ThemeStateNotifier([ThemeState? initialState])
      : _state = initialState ?? ThemeState.initial();

  ThemeState get state => _state;

  /// 更新UI主题
  void updateUITheme(UIThemeType uiTheme) {
    _state = _state.copyWith(uiTheme: uiTheme);
    _notifyListeners();
  }

  /// 更新主题模式（亮/暗/系统）
  void updateThemeMode(AppThemeMode themeMode) {
    _state = _state.copyWith(themeMode: themeMode);
    _notifyListeners();
  }

  /// 更新图片提取的颜色
  void updateExtractedColors(Map<ExtractedColorType, Color> colors) {
    _state = _state.copyWith(extractedColors: colors);
    _notifyListeners();
  }

  /// 清空图片提取的颜色
  void clearExtractedColors() {
    _state = _state.copyWith(extractedColors: null);
    _notifyListeners();
  }

  /// 更新实际亮度模式
  void updateEffectiveBrightness(Brightness brightness) {
    _state = _state.copyWith(effectiveBrightness: brightness);
    _notifyListeners();
  }

  /// 重置所有设置
  void reset() {
    _state = ThemeState.initial();
    _notifyListeners();
  }

  /// 添加监听器
  void addListener(ThemeStateListener listener) {
    _listeners.add(listener);
  }

  /// 移除监听器
  void removeListener(ThemeStateListener listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_state);
    }
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
