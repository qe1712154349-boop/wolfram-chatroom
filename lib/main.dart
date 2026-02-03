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
import 'dart:io'; // ✅ 添加这一行
import 'theme/theme.dart' as appTheme; // ← 用 as 前缀，避免 Theme 冲突
// 导入 providers
import 'providers/chat_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme/core/color_semantics.dart' show ExtractedColorType;

void main() {
  // ✅ 1. 最小必要初始化
  WidgetsFlutterBinding.ensureInitialized();

// ✅ 新增这一行：初始化通信端口（UI <-> 后台服务通信必须）
  FlutterForegroundTask.initCommunicationPort();

  // ✅ 2. 立即启动应用（不等待任何异步操作）
  runApp(
    const ProviderScope(
      child: MyBunnyApp(),
    ),
  );

  // ✅ 3. 所有非紧急初始化在后台静默进行
  _startBackgroundInitialization();
}

// ✅ 后台初始化任务（不影响启动速度）
Future<void> _startBackgroundInitialization() async {
  try {
    // 延迟一点，确保主界面已经显示
    await Future.delayed(const Duration(milliseconds: 300));

    // 并行执行所有非必要初始化
    await Future.wait([
      // 日期格式化（非紧急）
      initializeDateFormatting('zh_CN', null),

      // 屏幕方向（用户可能感觉不到延迟）
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),

      // 其他后台初始化可以加在这里
      // _initializeOtherServices(),
    ]);

    if (kDebugMode) {
      log.i('✅ 后台初始化任务完成');
    }
  } catch (e) {
    // 静默失败，不影响用户体验
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
  // ✅ 使用默认主题立即启动
  ThemeMode _themeMode = ThemeMode.system;
  final StorageService _storage = StorageService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 监听应用生命周期（用于自动保存等）
    WidgetsBinding.instance.addObserver(this);

    // ✅ 在后台异步加载用户设置（不阻塞UI）
    _loadUserPreferencesInBackground();

    // ✅ 预热聊天数据（后台进行）
    // _preheatChatDataInBackground();  // 暂时关掉
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 根据应用状态自动保存数据
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _storage.saveAppState();
        break;
      case AppLifecycleState.detached:
        // 应用被销毁前的清理
        break;
      default:
        break;
    }
  }

  // ✅ 后台加载用户偏好设置
  Future<void> _loadUserPreferencesInBackground() async {
    try {
      // 延迟一点，确保主界面优先显示
      await Future.delayed(const Duration(milliseconds: 500));

      // 1. 加载主题设置
      final savedMode = await _storage.getThemeMode();

      if (mounted) {
        setState(() {
          if (savedMode == 'dark') {
            _themeMode = ThemeMode.dark;
          } else if (savedMode == 'light') {
            _themeMode = ThemeMode.light;
          }
          // 如果是'system'或失败，保持默认的system
        });
      }

      // 2. 可以在这里加载其他用户设置
      // final otherSettings = await _storage.getOtherSettings();

      if (kDebugMode) {
        log.i('✅ 用户偏好设置加载完成: $savedMode');
      }
    } catch (e) {
      // 静默失败，用户无感知
      if (kDebugMode) {
        log.w('用户偏好加载失败: $e');
      }
    }
  }

  // ✅ 后台预热聊天数据
  Future<void> _preheatChatDataInBackground() async {
    try {
      // 延迟更多，确保用户已经看到界面
      await Future.delayed(const Duration(milliseconds: 1000));

      // 并行预热所有必要数据
      await Future.wait([
        // 加载聊天角色信息
        ref.read(chatCharacterProvider.future).then((character) {
          if (kDebugMode) {
            log.i('✅ 聊天角色预热完成: ${character.name}');
          }
          return character;
        }),

        // 预加载聊天历史
        ref.read(chatMessagesProvider.future).then((messages) {
          if (kDebugMode) {
            log.i('✅ 聊天历史预热完成: ${messages.length}条消息');
          }
          return messages;
        }),

        // 预加载最后一条消息
        ref.read(lastMessageProvider.future).then((lastMessage) {
          if (kDebugMode && lastMessage != null) {
            log.i('✅ 最后消息预热完成');
          }
          return lastMessage;
        }),
      ]);

      if (kDebugMode) {
        log.i('✅ 所有聊天数据预热完成');
      }
    } catch (e) {
      // 静默失败，不影响用户当前操作
      if (kDebugMode) {
        log.w('聊天数据预热失败: $e');
      }
    }
  }

  // ✅ 头像预缓存（在需要时调用）
  Future<void> _precacheAvatar(String? avatarPath, BuildContext context) async {
    if (avatarPath == null || avatarPath.isEmpty) return;

    try {
      final file = File(avatarPath);
      if (await file.exists() && mounted) {
        await precacheImage(FileImage(file), context);
        if (kDebugMode) {
          log.i('✅ 头像预缓存成功: $avatarPath');
        }
      }
    } catch (e) {
      // 失败也无妨
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听完整主题状态
    final themeState = ref.watch(appTheme.appThemeProvider);
    final effectiveBrightness = themeState.effectiveBrightness;

    // 动态取主色（优先提取色 > UI主题默认 > 固定粉色）
    Color primaryColor = const Color(0xFFFF5A7E); // 保底

    if (themeState.hasExtractedColors && themeState.extractedColors != null) {
      primaryColor = themeState.extractedColors![ExtractedColorType.dominant] ??
          primaryColor;
    } else if (themeState.uiTheme != appTheme.UIThemeType.defaultTheme) {
      // 从 ColorResolver 静态方法取主色（最优调用方式）
      primaryColor = appTheme.ColorResolver.resolve(
        themeState: themeState,
        semantic: appTheme.ColorSemantic.primary,
      );
    }

    // 动态构建 ThemeData
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: switch (effectiveBrightness) {
        Brightness.light => ThemeMode.light,
        Brightness.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
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
