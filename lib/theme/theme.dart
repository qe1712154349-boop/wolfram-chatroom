// lib/theme/theme.dart （完整推荐 export 列表）
export 'providers/app_theme_provider.dart' show appThemeProvider;
export 'core/theme_state.dart' show UIThemeType;

// 核心类型与语义
export 'core/color_semantics.dart' show ColorSemantic, ExtractedColorType;
// 改成这样（补上 UIThemeTypeExtension）：
export 'core/theme_state.dart'; // 完整 export，让所有 extension 自动可见

export 'core/color_resolver.dart' show ColorResolver;

// 令牌
export 'tokens/base_tokens.dart'
    show BaseColorTokens, ColorUtils, ColorPalettes, ColorExtensions;

export 'tokens/semantic_mapper.dart';

// 主题定义
export 'definitions/default_theme.dart';
export 'definitions/strawberry_candy.dart';
export 'definitions/pickle_milk.dart';
export 'definitions/theme_registry.dart'
    show ThemeDefinition, ThemeRegistry, ThemePreview, ThemeUtils;

// Providers
export 'providers/app_theme_provider.dart' show appThemeProvider;
export 'providers/brightness_provider.dart' show BrightnessUtils;
export 'providers/color_override.dart';
export 'providers/theme_manager.dart';

// 扩展（关键！）
export 'extensions/context_extensions.dart'; // ← 加这个，让 context.themeColor 可用

// facade
export 'theme_facade.dart';
