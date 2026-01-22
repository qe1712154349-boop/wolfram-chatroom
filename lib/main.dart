// lib/main.dart - 完整修复版：适配 flutter_foreground_task 9.2.0 + Riverpod + Isar 兼容
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // ★ 新增导入 intl 初始化
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';
import 'services/isar_service.dart'; // 必须导入，用于 isarProvider
import 'services/foreground_task_handler.dart'; // 新增：前台任务处理器


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ 新增：全局初始化 intl locale（必须 await，否则 DateFormat('zh_CN') 会崩溃）
  await initializeDateFormatting('zh_CN', null);
  
  // ★ 修改：使用 9.2.0 新版初始化
  await _initForegroundTask();

  // Isar 初始化交给 isarProvider 自动 await（无需手动调用）

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

// ★ 修改：更新为 9.2.0 新版初始化方法
Future<void> _initForegroundTask() async {
  try {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'chat_foreground_channel',
        channelName: '聊天保活通知',
        channelDescription: '保持聊天後台運行與訊息接收',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',  // 對應 android/app/src/main/res/mipmap-*/ic_launcher.png
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,           // 心跳間隔 5 秒
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // 這行確保 isolate 能找到你的 handler class
    FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());

    if (kDebugMode) {
      print('FlutterForegroundTask 初始化完成 (v9.2.0)');
    }
  } catch (e, stack) {
    if (kDebugMode) {
      print('FlutterForegroundTask 初始化失敗: $e');
      print(stack);
    }
  }
}


// ★ 注意：MyForegroundTaskHandler 类已移动到单独的 handler 文件中
// 原类的代码已删除，使用 ChatForegroundTaskHandler 替代

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

  // ★ 修改：更新为 9.2.0 新版启动方法
  Future<void> _startForegroundService() async {
    try {
      // 检查是否已在运行
      if (await FlutterForegroundTask.isRunningService) {
        if (kDebugMode) {
          print('前台服务已在运行');
        }
        return;
      }

      // 启动服务（9.2.0 新版参数）
      final started = await FlutterForegroundTask.startService(
        notificationTitle: '小猫',
        notificationText: '在线等待你的消息...',
        // 使用 metaDataName 指定图标
        notificationIcon: const NotificationIcon(
          metaDataName: 'foreground_icon',
        ),
      );

      if (started) {
        if (kDebugMode) {
          print('前台服务启动成功');
        }
        
        // 开始监听来自服务的数据
        FlutterForegroundTask.receivePort?.listen((data) {
          if (kDebugMode) {
            print('收到前台服务数据: $data');
          }
        });
      } else {
        if (kDebugMode) {
          print('前台服务启动失败');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('启动前台服务失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ★ 修改：WithForegroundTask 组件在 9.x 中不需要了
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
      home: const MainScreen(),
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}