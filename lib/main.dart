// lib/main.dart - 秒开优化完整版
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'utils/logger.dart';
import 'dart:io'; // ✅ 添加这一行
// 导入 providers
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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

  // 用于主题颜色变化跟踪
  Map<String, Color>? _lastCustomColors;

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
    // ✅ 监听自定义颜色变化
    final customColors = ref.watch(customColorsProvider);

    // ✅ 调试信息：只在颜色变化时打印
    if (kDebugMode && customColors != _lastCustomColors) {
      log.d('🎨 主题颜色变化: ${customColors != null ? "自定义" : "默认"}');
      _lastCustomColors = customColors;
    }

    // ✅ 根据自定义颜色动态调整主题
    ThemeData lightTheme =
        _applyCustomColors(AppTheme.lightTheme, customColors);
    ThemeData darkTheme = _applyCustomColors(AppTheme.darkTheme, customColors);

    // ✅ 直接返回主应用，没有任何加载判断
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      showSemanticsDebugger: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      navigatorKey: _navigatorKey,

      // ✅ 立即显示聊天界面
      home: const MainScreen(initialIndex: 1),

      // 路由配置
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },

      // ✅ 文本缩放限制
      builder: (context, child) {
        final currentScaler = MediaQuery.textScalerOf(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              currentScaler.scale(1.0).clamp(0.8, 1.5),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  // ✅ 应用自定义颜色的辅助方法
  ThemeData _applyCustomColors(
      ThemeData baseTheme, Map<String, Color>? customColors) {
    if (customColors == null || customColors['primary'] == null) {
      return baseTheme;
    }

    final primaryColor = customColors['primary']!;

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: primaryColor.withValues(alpha: 0.8),
        surface: primaryColor.withValues(
            alpha: baseTheme.brightness == Brightness.light ? 0.05 : 0.1),
        primaryContainer: primaryColor.withValues(
            alpha: baseTheme.brightness == Brightness.light ? 0.1 : 0.2),
        onPrimaryContainer: Colors.white,
        surfaceContainerHighest: primaryColor.withValues(
          alpha: baseTheme.brightness == Brightness.light ? 0.08 : 0.15,
        ),
      ),
      primaryColor: primaryColor,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: primaryColor.withValues(
          alpha: baseTheme.brightness == Brightness.light ? 0.05 : 0.1,
        ),
        foregroundColor: primaryColor,
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      switchTheme: baseTheme.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primaryColor
              : Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.5);
        }),
      ),
      iconTheme: baseTheme.iconTheme.copyWith(
        color: primaryColor,
      ),
    );
  }
}

// ✅ 后台服务初始化（如果需要的话）
Future<void> _initializeBackgroundServices() async {
  // 如果你需要其他后台服务，在这里初始化
  // 比如：推送通知、分析工具、数据库等

  // 示例：
  /*
  await Future.wait([
    Firebase.initializeApp(),
    setupAnalytics(),
    initializeDatabase(),
  ]);
  */
}
