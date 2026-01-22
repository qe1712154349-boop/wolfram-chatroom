// lib/main.dart
// 完全適配 flutter_foreground_task 9.2.0 的版本
// 沒有任何舊版參數、舊版方法、舊版返回值判斷

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/splash_page.dart';  // ← 新增这一行
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'services/isar_service.dart';
import 'services/foreground_task_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 intl（日期格式化）
  await initializeDateFormatting('zh_CN', null);

  // 初始化前台服務（9.2.0 寫法）
  await _initForegroundTask();

  // Isar 初始化交給 provider 處理

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MyBunnyApp(),
    ),
  );
}

// 9.2.0 正確的初始化方式
Future<void> _initForegroundTask() async {
  try {
    FlutterForegroundTask.init(  // ← 去掉 await
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
      foregroundTaskOptions: ForegroundTaskOptions(  // 已經去掉 const，正確
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());

    if (kDebugMode) {
      print('✅ 前台服務初始化完成 (9.2.0)');
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('❌ 前台服務初始化失敗: $e');
      print(stack);
    }
  }
}

// 監聽前台服務發來的資料（callback 方式）
void _onForegroundTaskData(Object? data) {
  if (kDebugMode) {
    print('收到前台服務資料: $data');
  }

  if (data is Map<String, dynamic>) {
    final type = data['type'] as String?;
    switch (type) {
      case 'heartbeat':
        // 心跳，可以在這裡更新 UI 或記錄
        break;
      case 'service_stopped':
        // 服務被停止，可選擇重啟
        _startForegroundService();
        break;
      case 'notification_clicked':
        // 用戶點擊通知，可以導航到聊天頁面
        break;
    }
  }
}

// 啟動前台服務（9.2.0 寫法）
Future<void> _startForegroundService() async {
  try {
    // 先檢查是否已經在運行
    if (await FlutterForegroundTask.isRunningService) {
      if (kDebugMode) print('前台服務已在運行');
      return;
    }

    // 啟動服務
    // 替换这段：
final ServiceRequestResult result = await FlutterForegroundTask.startService(
  notificationTitle: '小猫',
  notificationText: '在线等待你的消息...',
  notificationIcon: const NotificationIcon(
    metaDataName: 'foreground_icon',
  ),
  notificationInitialRoute: '/chat_room',
);

if (result is ServiceRequestSuccess) {  // ← 改成 is 类型检查
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
      print('啟動前台服務異常: $e');
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

    // 啟動前台服務
    _startForegroundService();

    // 註冊監聽（確保每次 initState 都註冊）
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  @override
  void dispose() {
    // 移除監聽（避免記憶體洩漏）
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
          style: TextButton.styleFrom(
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
          ),
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
          style: TextButton.styleFrom(
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
          ),
        ),
      ),
      themeMode: _themeMode,
      navigatorKey: _navigatorKey,
      home: const SplashPage(),  // ✅ 正确的！先显示启动页
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}