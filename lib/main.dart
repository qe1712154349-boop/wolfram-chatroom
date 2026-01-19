// lib/main.dart - 最终稳定版（flutter_foreground_task 6.1.3 兼容）
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';

// 前台任务入口（6.x 必须）
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initForegroundTask();  // 去掉 await

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyBunnyApp());
}

Future<void> _initForegroundTask() async {
  try {
    FlutterForegroundTask.init(  // 去掉 await
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'wolf_chat_foreground',
        channelName: '沃夫朗聊天',
        channelDescription: '保持聊天室活跃，随时响应消息',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    if (kDebugMode) {
      print('✅ 前台服务初始化成功');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ 前台服务初始化失败: $e');
    }
  }
}

class MyForegroundTaskHandler extends TaskHandler {
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) {
    if (kDebugMode) print('Foreground service started at $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {  // 改为 onRepeatEvent
    if (kDebugMode) print('Heartbeat at $timestamp');
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    if (kDebugMode) print('Foreground service destroyed at $timestamp');
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
    _startForegroundService();
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
      if (savedMode == 'dark') _themeMode = ThemeMode.dark;
      else if (savedMode == 'light') _themeMode = ThemeMode.light;
      else _themeMode = ThemeMode.system;
    });
  }

  void changeTheme(String mode) => _updateThemeMode(mode);

  Future<String> getCurrentTheme() async => await _storage.getThemeMode();

  Future<void> _startForegroundService() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.startService(
        notificationTitle: '沃夫朗聊天室',
        notificationText: '在线等待你的消息...',
        callback: startCallback,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        navigatorKey: _navigatorKey,
        home: const MainScreen(),
        routes: {
          '/character-edit': (context) => const ChatCharacterEditPage(),
          '/profile-settings': (context) => const ProfileSettingsPage(),
        },
      ),
    );
  }
}