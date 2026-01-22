// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'services/foreground_task_handler.dart';

// top-level entry-point（callback: true 时插件自动调用，确保 Isolate 安全）
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 并行初始化（不阻塞 UI）
  Future.wait([
    initializeDateFormatting('zh_CN', null),
    _initForegroundTask(),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]).then((_) {
    runApp(const ProviderScope(child: MyBunnyApp()));
  });
}

// 前台服务初始化（只执行一次）
Future<void> _initForegroundTask() async {
  try {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'chat_foreground_service',
        channelName: '聊天保活通知',
        channelDescription: '保持聊天后台运行与新消息即时接收',
        channelImportance: NotificationChannelImportance.DEFAULT, // 平衡可见与低打扰
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true, // 通知只首次提醒，避免重复打扰
        // 图标已移除字段 → 依赖 AndroidManifest meta-data foreground_icon
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 每5秒心跳
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());
  } catch (e) {
    if (kDebugMode) {
      print('前台服务初始化失败（不阻塞启动）: $e');
    }
  }
}

// 全局启动函数（可重复调用，检查运行状态）
Future<void> startForegroundServiceIfNeeded() async {
  if (!Platform.isAndroid) return;

  try {
    if (await FlutterForegroundTask.isRunningService) {
      if (kDebugMode) print('前台服务已在运行');
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 256, // required：唯一标识服务，避免冲突
      notificationTitle: '小猫在线',
      notificationText: '一直陪着你，等你的消息～',
      notificationIcon: null, // null → fallback 到 Manifest foreground_icon
      notificationInitialRoute: '/chat_room',
      callback: true, // true → 调用 top-level startCallback()
    );

    if (result is ServiceRequestSuccess) {
      if (kDebugMode) print('前台服务启动成功');
    } else {
      if (kDebugMode) print('启动失败: $result');
    }
  } catch (e) {
    if (kDebugMode) print('启动前台服务异常: $e');
  }
}

// 带权限检查的启动封装（聊天页等调用）
Future<void> startForegroundServiceWithPermissions() async {
  if (!Platform.isAndroid) return;

  try {
    var status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      status = await FlutterForegroundTask.requestNotificationPermission();
      // 第一次系统弹窗，后续 granted 则跳过
    }
    await startForegroundServiceIfNeeded();
  } catch (e) {
    if (kDebugMode) print('权限/服务启动异常: $e');
  }
}

// 前台服务数据回调（全局统一管理）
void _onForegroundTaskData(Object? data) {
  if (kDebugMode) print('收到前台服务数据: $data');

  if (data is Map<String, dynamic>) {
    final type = data['type'] as String?;
    switch (type) {
      case 'heartbeat':
        // 可用于记录活跃或 UI 刷新
        break;
      case 'service_stopped':
        startForegroundServiceIfNeeded(); // 被杀自动重启
        break;
      case 'notification_clicked':
        // 点击通知可导航（需 navigatorKey）
        // _navigatorKey.currentState?.pushNamed('/chat_room');
        break;
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

    // 启动服务 + 注册监听
    startForegroundServiceWithPermissions();
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
        startForegroundServiceWithPermissions(); // 复活时确保运行
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
      if (savedMode == 'dark') _themeMode = ThemeMode.dark;
      else if (savedMode == 'light') _themeMode = ThemeMode.light;
      else _themeMode = ThemeMode.system;
    });
  }

  void changeTheme(String mode) => _updateThemeMode(mode);

  Future<String> getCurrentTheme() async => await _storage.getThemeMode();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(elevation: 0),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(elevation: 0),
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(elevation: 0),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(elevation: 0),
        ),
      ),
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