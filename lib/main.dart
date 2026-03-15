// lib/main.dart - 秒开优化完整版
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'utils/logger.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme/core/color_resolver.dart';
import 'theme/core/color_semantics.dart';
import 'theme/core/theme_state.dart';
import 'theme/providers/app_theme_provider.dart';
import 'theme/extensions/semantic_colors_extension.dart';
import 'theme/providers/brightness_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  runApp(
    const ProviderScope(
      child: MyBunnyApp(),
    ),
  );

  _startBackgroundInitialization();
}

Future<void> _startBackgroundInitialization() async {
  try {
    await Future.delayed(const Duration(milliseconds: 300));

    await Future.wait([
      initializeDateFormatting('zh_CN', null),
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    ]);

    if (kDebugMode) {
      log.i('✅ 后台初始化任务完成');
    }
  } catch (e) {
    if (kDebugMode) {
      log.e('后台初始化失败: $e');
    }
  }
}

class MyBunnyApp extends ConsumerStatefulWidget {
  const MyBunnyApp({super.key});

  @override
  ConsumerState<MyBunnyApp> createState() => _MyBunnyAppState();
}

class _MyBunnyAppState extends ConsumerState<MyBunnyApp>
    with WidgetsBindingObserver {
  final StorageService _storage = StorageService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    log.i('🚀 [initState] 应用启动');

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewBrightness =
            View.of(context).platformDispatcher.platformBrightness;
        log.i('📱 [initState] 初始化平台亮度: ${viewBrightness.name}');
        ref.read(platformBrightnessProvider.notifier).state = viewBrightness;
      }
    });

    _loadUserPreferencesInBackground();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _storage.saveAppState();
        break;
      case AppLifecycleState.detached:
        break;
      default:
        break;
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    if (mounted) {
      final viewBrightness =
          View.of(context).platformDispatcher.platformBrightness;

      log.w('⚡ 系统亮度已切换: ${viewBrightness.name}');

      ref.read(platformBrightnessProvider.notifier).state = viewBrightness;
    }
  }

  Future<void> _loadUserPreferencesInBackground() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final savedMode = await _storage.getThemeMode();

      if (mounted) {
        ref.read(appThemeProvider);
      }

      if (kDebugMode) {
        log.i('✅ 用户偏好设置加载完成: $savedMode');
      }
    } catch (e) {
      if (kDebugMode) {
        log.w('用户偏好加载失败: $e');
      }
    }
  }

  /// ✅ 辅助方法：从 themeState 解析颜色
  Color _resolve(ThemeState themeState, ColorSemantic semantic) {
    return ColorResolver.resolve(
      themeState: themeState,
      semantic: semantic,
    );
  }

  @override
  Widget build(BuildContext context) {
    log.i('🎨 [build] 重新构建');

    final themeState = ref.watch(appThemeProvider);
    final effectiveBrightness = themeState.effectiveBrightness;

    // ✅ 从主题系统统一获取颜色
    final primaryColor = _resolve(themeState, ColorSemantic.primary);
    final backgroundColor = _resolve(themeState, ColorSemantic.background);
    final surfaceColor = _resolve(themeState, ColorSemantic.surface);
    final textPrimaryColor = _resolve(themeState, ColorSemantic.textPrimary);
    final textSecondaryColor =
        _resolve(themeState, ColorSemantic.textSecondary);
    final errorColor = _resolve(themeState, ColorSemantic.error);

    final semanticColors = AppSemanticColors.fromThemeState(themeState);

    // ✅ 亮色和暗色都用主题系统的颜色构建
    final currentTheme = ThemeData(
      useMaterial3: true,
      brightness: effectiveBrightness,
      colorScheme: effectiveBrightness == Brightness.light
          ? ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              secondary: primaryColor.withValues(alpha: 0.7),
              onSecondary: Colors.white,
              surface: surfaceColor,
              onSurface: textPrimaryColor,
              error: errorColor,
              onError: Colors.white,
            )
          : ColorScheme.dark(
              primary: primaryColor,
              onPrimary: Colors.white,
              secondary: primaryColor.withValues(alpha: 0.7),
              onSecondary: Colors.white,
              surface: surfaceColor,
              onSurface: textPrimaryColor,
              error: errorColor,
              onError: Colors.white,
            ),
      scaffoldBackgroundColor: backgroundColor, // ✅ 关键：统一背景色
      appBarTheme: AppBarTheme(
        backgroundColor: _resolve(themeState, ColorSemantic.appBarBackground),
        foregroundColor: _resolve(themeState, ColorSemantic.appBarText),
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor, // ✅ 选中用主色
        unselectedItemColor: textSecondaryColor, // ✅ 未选中用次要文字色
        backgroundColor: surfaceColor, // ✅ 底栏背景用表面色
      ),
      dividerColor: _resolve(themeState, ColorSemantic.divider),
      cardColor: surfaceColor,
      extensions: <ThemeExtension<dynamic>>[semanticColors],
    );

    final finalThemeMode = switch (effectiveBrightness) {
      Brightness.light => ThemeMode.light,
      Brightness.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      theme: currentTheme,
      darkTheme: currentTheme,
      themeMode: finalThemeMode,
      navigatorKey: _navigatorKey,
      home: const MainScreen(initialIndex: 1),
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
      builder: (context, child) {
        final scaler = MediaQuery.textScalerOf(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaler.scale(1.0).clamp(0.8, 1.5)),
          ),
          child: child!,
        );
      },
    );
  }
}
