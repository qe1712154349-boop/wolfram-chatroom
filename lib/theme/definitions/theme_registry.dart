/// theme_registry.dart - 结构化版本
library;
import 'package:flutter/material.dart';
import '../core/color_semantics.dart';
import '../tokens/semantic_mapper.dart';
import '../core/theme_state.dart'; // 添加这行

// ========== 接口和基类 ==========

/// 主题定义接口
abstract class ThemeDefinition {
  String get id;
  String get name;
  String get description;
  IconData get icon;

  Map<ColorSemantic, Color> getColors(bool isDark);
  Map<String, Color> getBubbleColors(bool isDark);
  Map<String, Color> getBubbleColorsWithOpacity(bool isDark);
  List<Color> getPreviewColors(bool isDark);
  List<String> validate();
}

/// 主题基类 - 提供通用实现
abstract class BaseThemeDefinition implements ThemeDefinition {
  @override
  Map<String, Color> getBubbleColors(bool isDark) {
    final colors = getColors(isDark);
    return {
      'userBubbleBackground': colors[ColorSemantic.userBubbleBackground]!,
      'userBubbleBorder': colors[ColorSemantic.userBubbleBorder]!,
      'userBubbleText': colors[ColorSemantic.userBubbleText]!,
      'aiBubbleBackground': colors[ColorSemantic.aiBubbleBackground]!,
      'aiBubbleBorder': colors[ColorSemantic.aiBubbleBorder]!,
      'aiBubbleText': colors[ColorSemantic.aiBubbleText]!,
    };
  }

  @override
  Map<String, Color> getBubbleColorsWithOpacity(bool isDark) {
    final colors = getBubbleColors(isDark);
    return {
      'userBubbleBackground': colors['userBubbleBackground']!.withOpacity(0.3),
      'userBubbleBorder': colors['userBubbleBorder']!,
      'userBubbleText': colors['userBubbleText']!,
      'aiBubbleBackground': colors['aiBubbleBackground']!.withOpacity(0.3),
      'aiBubbleBorder': colors['aiBubbleBorder']!,
      'aiBubbleText': colors['aiBubbleText']!,
    };
  }

  @override
  List<Color> getPreviewColors(bool isDark) {
    final colors = getColors(isDark);
    return [
      colors[ColorSemantic.primary]!,
      colors[ColorSemantic.secondary]!,
      colors[ColorSemantic.background]!,
      colors[ColorSemantic.userBubbleBackground]!,
      colors[ColorSemantic.aiBubbleBackground]!,
    ];
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    // 检查亮色模式
    final lightMapping = getColors(false);
    final lightMissing = SemanticMapper.validateMapping(lightMapping);
    if (lightMissing.isNotEmpty) {
      errors
          .add('$name亮色模式缺少: ${lightMissing.map((e) => e.name).join(', ')}');
    }

    // 检查暗色模式
    final darkMapping = getColors(true);
    final darkMissing = SemanticMapper.validateMapping(darkMapping);
    if (darkMissing.isNotEmpty) {
      errors.add('$name暗色模式缺少: ${darkMissing.map((e) => e.name).join(', ')}');
    }

    return errors;
  }
}

// ========== 具体主题实现 ==========

/// 默认主题
class DefaultThemeDefinition extends BaseThemeDefinition {
  @override
  String get id => 'default';

  @override
  String get name => '默认主题';

  @override
  String get description => '清爽的粉色系设计，简约而温暖';

  @override
  IconData get icon => Icons.favorite;

  @override
  Map<ColorSemantic, Color> getColors(bool isDark) {
    return SemanticMapper.getMapping(themeId: id, isDark: isDark);
  }
}

/// 草莓糖心主题
class StrawberryCandyThemeDefinition extends BaseThemeDefinition {
  @override
  String get id => 'strawberryCandy';

  @override
  String get name => '草莓糖心🍓';

  @override
  String get description => '少女心满满的草莓风格，甜美而清新';

  @override
  IconData get icon => Icons.cake;

  @override
  Map<ColorSemantic, Color> getColors(bool isDark) {
    return SemanticMapper.getMapping(themeId: id, isDark: isDark);
  }
}

/// 酸菜牛奶主题
class PickleMilkThemeDefinition extends BaseThemeDefinition {
  @override
  String get id => 'pickleMilk';

  @override
  String get name => '酸菜牛奶🥛';

  @override
  String get description => '优雅的酸菜牛奶配色，舒适而清新';

  @override
  IconData get icon => Icons.local_cafe;

  @override
  Map<ColorSemantic, Color> getColors(bool isDark) {
    return SemanticMapper.getMapping(themeId: id, isDark: isDark);
  }
}

// ========== 主题注册表 ==========

/// 主题注册表 - 统一管理和注册所有主题
class ThemeRegistry {
  static final ThemeRegistry _instance = ThemeRegistry._internal();
  factory ThemeRegistry() => _instance;

  final Map<String, ThemeDefinition> _themes = {};

  ThemeRegistry._internal() {
    _registerDefaultThemes();
  }

  /// 注册默认主题
  void _registerDefaultThemes() {
    registerTheme(DefaultThemeDefinition());
    registerTheme(StrawberryCandyThemeDefinition());
    registerTheme(PickleMilkThemeDefinition());
  }

  /// 注册新主题
  void registerTheme(ThemeDefinition theme) {
    _themes[theme.id] = theme;
  }

  /// 注销主题
  void unregisterTheme(String themeId) {
    _themes.remove(themeId);
  }

  /// 获取所有主题
  List<ThemeDefinition> getAllThemes() {
    return _themes.values.toList();
  }

  /// 根据ID获取主题
  ThemeDefinition? getThemeById(String id) {
    return _themes[id];
  }

  /// 根据UIThemeType获取主题  <--- 添加这个方法
  ThemeDefinition getThemeByType(UIThemeType type) {
    final themeId = type.id; // 使用扩展方法获取ID
    return getThemeById(themeId) ?? defaultTheme;
  }

  /// 获取默认主题
  ThemeDefinition get defaultTheme => _themes['default']!;

  /// 验证所有主题的完整性
  Map<String, List<String>> validateAllThemes() {
    final results = <String, List<String>>{};

    for (final theme in _themes.values) {
      final errors = theme.validate();
      if (errors.isNotEmpty) {
        results[theme.id] = errors;
      }
    }

    return results;
  }

  /// 打印所有主题信息（用于调试）
  void debugPrintAllThemes() {
    debugPrint('=== 主题注册表 ===');
    debugPrint('已注册主题数: ${_themes.length}');

    for (final theme in _themes.values) {
      debugPrint('\n--- ${theme.name} ---');
      debugPrint('ID: ${theme.id}');
      debugPrint('描述: ${theme.description}');
    }
  }

  /// 获取主题预览信息（用于设置页面）
  List<ThemePreview> getThemePreviews(bool isDark) {
    return _themes.values.map((theme) {
      return ThemePreview(
        id: theme.id,
        name: theme.name,
        description: theme.description,
        icon: theme.icon,
        previewColors: theme.getPreviewColors(isDark),
      );
    }).toList();
  }
}

// ========== 工具类和扩展 ==========

/// 主题预览信息
class ThemePreview {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<Color> previewColors;

  const ThemePreview({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.previewColors,
  });
}

/// 主题工具类
class ThemeUtils {
  static final ThemeRegistry _registry = ThemeRegistry();

  /// 获取主题注册表实例
  static ThemeRegistry get registry => _registry;

  /// 从字符串获取主题
  static ThemeDefinition? themeFromString(String value) {
    return _registry.getThemeById(value);
  }

  /// 获取所有主题
  static List<ThemeDefinition> getAllThemes() {
    return _registry.getAllThemes();
  }

  /// 验证主题系统
  static Map<String, List<String>> validateThemeSystem() {
    debugPrint('=== 验证主题系统 ===');

    final themeErrors = _registry.validateAllThemes();
    if (themeErrors.isNotEmpty) {
      debugPrint('发现主题错误:');
      for (final entry in themeErrors.entries) {
        debugPrint('  ${entry.key}:');
        for (final error in entry.value) {
          debugPrint('    - $error');
        }
      }
    } else {
      debugPrint('所有主题验证通过 ✓');
    }

    return themeErrors;
  }

  /// 调试打印所有主题的颜色
  static void debugPrintAllThemeColors(bool isDark) {
    debugPrint('=== 所有主题颜色 (${isDark ? '暗色' : '亮色'}模式) ===');

    for (final theme in _registry.getAllThemes()) {
      debugPrint('\n--- ${theme.name} ---');

      final colors = theme.getColors(isDark);
      final bubbleColors = theme.getBubbleColors(isDark);

      debugPrint('气泡颜色:');
      for (final entry in bubbleColors.entries) {
        final color = entry.value;
        debugPrint('  ${entry.key.padRight(25)}: ${_colorToHex(color)}');
      }

      debugPrint('\n重要颜色:');
      final importantSemantics = [
        ColorSemantic.primary,
        ColorSemantic.secondary,
        ColorSemantic.background,
        ColorSemantic.surface,
        ColorSemantic.textPrimary,
        ColorSemantic.textSecondary,
      ];

      for (final semantic in importantSemantics) {
        final color = colors[semantic];
        if (color != null) {
          debugPrint('  ${semantic.name.padRight(20)}: ${_colorToHex(color)}');
        }
      }
    }
  }

  /// 颜色转16进制字符串
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// 颜色扩展
extension ColorExtensions on Color {
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
