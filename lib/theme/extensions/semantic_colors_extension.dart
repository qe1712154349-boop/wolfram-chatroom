// lib/theme/extensions/semantic_colors_extension.dart
import 'package:flutter/material.dart';
import '../core/color_semantics.dart';
import '../core/color_resolver.dart';
import '../core/theme_state.dart';

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Map<ColorSemantic, Color> colors;

  AppSemanticColors({required this.colors});

  // 工厂：从 ThemeState 实时计算所有 semantic 的最终颜色
  factory AppSemanticColors.fromThemeState(ThemeState state) {
    final map = <ColorSemantic, Color>{};
    for (final semantic in ColorSemantic.values) {
      map[semantic] = ColorResolver.resolve(
        themeState: state,
        semantic: semantic,
      );
    }
    return AppSemanticColors(colors: map);
  }

  // 必须实现 copyWith（Theme 系统要求）
  @override
  AppSemanticColors copyWith({Map<ColorSemantic, Color>? colors}) {
    return AppSemanticColors(
      colors: colors ?? this.colors,
    );
  }

  // 必须实现 lerp（主题切换动画核心）
  @override
  AppSemanticColors lerp(
      covariant ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;

    final lerpedColors = <ColorSemantic, Color>{};
    for (final semantic in ColorSemantic.values) {
      final c1 = colors[semantic] ?? Colors.transparent;
      final c2 = other.colors[semantic] ?? Colors.transparent;
      lerpedColors[semantic] = Color.lerp(c1, c2, t)!;
    }
    return AppSemanticColors(colors: lerpedColors);
  }

  // 强烈推荐：为所有常用 semantic 加 getter（IDE 补全最爽）
  Color get primary => colors[ColorSemantic.primary]!;
  Color get secondary => colors[ColorSemantic.secondary]!;
  Color get accent => colors[ColorSemantic.accent]!;
  Color get background => colors[ColorSemantic.background]!;
  Color get surface => colors[ColorSemantic.surface]!;
  Color get surfaceVariant => colors[ColorSemantic.surfaceVariant]!;
  Color get textPrimary => colors[ColorSemantic.textPrimary]!;
  Color get textSecondary => colors[ColorSemantic.textSecondary]!;
  Color get textHint => colors[ColorSemantic.textHint]!;
  Color get border => colors[ColorSemantic.border]!;
  Color get divider => colors[ColorSemantic.divider]!;

  // 气泡相关（常用）
  Color get userBubbleBackground => colors[ColorSemantic.userBubbleBackground]!;
  Color get userBubbleBorder => colors[ColorSemantic.userBubbleBorder]!;
  Color get userBubbleText => colors[ColorSemantic.userBubbleText]!;
  Color get aiBubbleBackground => colors[ColorSemantic.aiBubbleBackground]!;
  Color get aiBubbleBorder => colors[ColorSemantic.aiBubbleBorder]!;
  Color get aiBubbleText => colors[ColorSemantic.aiBubbleText]!;

  // 按钮 / 组件 / 状态（根据你的需求继续加）
  Color get buttonPrimary => colors[ColorSemantic.buttonPrimary]!;
  Color get success => colors[ColorSemantic.success]!;
  Color get warning => colors[ColorSemantic.warning]!;
  Color get error => colors[ColorSemantic.error]!;
  Color get info => colors[ColorSemantic.info]!;
}
