// lib/main.dart - 稳定版（根不 watch 动态，避免白屏）
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'services/isar_service.dart';
import 'services/foreground_task_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('zh_CN', null),
    _initForegroundTaskInBackground(),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);

  runApp(
    const ProviderScope(
      child: MyBunnyApp(),
    ),
  );
}

// ✅ 静默的前台服务初始化
Future<void> _initForegroundTaskInBackground() async {
  try {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'chat_foreground_channel',
        channelName: '聊天保活通知',
        channelDescription: '保持聊天後台運行與訊息接收',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());

    if (kDebugMode) {
      print('✅ 前台服务初始化完成');
    }
  } catch (e) {
    // 静默失败，不影响启动
    if (kDebugMode) {
      print('❌ 前台服务初始化失败（不影响启动）: $e');
    }
  }
}

// 监听前台服务数据
void _onForegroundTaskData(Object? data) {
  if (kDebugMode) {
    print('收到前台服务数据: $data');
  }

  if (data is Map<String, dynamic>) {
    final type = data['type'] as String?;
    switch (type) {
      case 'heartbeat':
        break;
      case 'service_stopped':
        _startForegroundService();
        break;
      case 'notification_clicked':
        break;
    }
  }
}

// 启动前台服务
Future<void> _startForegroundService() async {
  try {
    if (await FlutterForegroundTask.isRunningService) {
      if (kDebugMode) print('前台服务已在运行');
      return;
    }

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
      notificationTitle: '小猫',
      notificationText: '在线等待你的消息...',
      notificationIcon: const NotificationIcon(
        metaDataName: 'foreground_icon',
      ),
      notificationInitialRoute: '/chat_room',
    );

    if (result is ServiceRequestSuccess) {
      if (kDebugMode) {
        print('前台服务启动成功 - 通知应该出现了');
      }
      FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
    } else {
      if (kDebugMode) {
        print('前台服务启动失败: $result');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('启动前台服务异常: $e');
    }
  }
}

class MyBunnyApp extends StatefulWidget {
  const MyBunnyApp({super.key});

  @override
  State<MyBunnyApp> createState() => _MyBunnyAppState();
}

class _MyBunnyAppState extends State<MyBunnyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  final StorageService _storage = StorageService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();

    // 延迟启动前台服务（让UI先出来）
    Future.delayed(const Duration(seconds: 2), () {
      _startForegroundService();
    });

    // 注册监听
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _startForegroundService();
        _storage.saveAppState();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _storage.saveAppState();
        break;
      case AppLifecycleState.detached:
        FlutterForegroundTask.stopService();
        break;
      default:
        break;
    }
  }

  Future<void> _loadThemeMode() async {
    final savedMode = await _storage.getThemeMode();
    _updateThemeMode(savedMode);
  }

  void _updateThemeMode(String savedMode) {
    setState(() {
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light')
        _themeMode = ThemeMode.light;
      else
        _themeMode = ThemeMode.system;
    });
  }

  void changeTheme(String mode) => _updateThemeMode(mode);

  Future<String> getCurrentTheme() async => await _storage.getThemeMode();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      navigatorKey: _navigatorKey,
      home: const MainScreen(initialIndex: 1),
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}
