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
import 'dart:io';
import 'providers/chat_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme/core/color_resolver.dart';
import 'theme/core/color_semantics.dart';
import 'theme/core/theme_state.dart'; // 🆕 加这一行
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

  // 🔥 关键：监听系统亮度变化
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    if (mounted) {
      // 用更底层的 View API（绕过 MIUI bug）
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

  @override
  Widget build(BuildContext context) {
    log.i('🎨 [build] 重新构建');

    final themeState = ref.watch(appThemeProvider);
    log.i(
        '🎨 [build] appThemeProvider.themeMode = ${themeState.themeMode.displayName}');
    log.i(
        '🎨 [build] appThemeProvider.effectiveBrightness = ${themeState.effectiveBrightness.name}');

    final effectiveBrightness = themeState.effectiveBrightness;

    final primaryColor = ColorResolver.resolve(
      themeState: themeState,
      semantic: ColorSemantic.primary,
    );

    final semanticColors = AppSemanticColors.fromThemeState(themeState);

    final currentTheme = effectiveBrightness == Brightness.light
        ? ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
            ),
            extensions: <ThemeExtension<dynamic>>[semanticColors],
          )
        : ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            ),
            extensions: <ThemeExtension<dynamic>>[semanticColors],
          );

    final finalThemeMode = switch (effectiveBrightness) {
      Brightness.light => ThemeMode.light,
      Brightness.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    log.i('🎨 [build] MaterialApp.themeMode 设置为: $finalThemeMode');

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
