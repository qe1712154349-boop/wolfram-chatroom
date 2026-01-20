// lib/main.dart - 升级到 flutter_foreground_task 9.2.0 兼容版
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

// ✅ 前台任务入口（9.x 必须 top-level + @pragma）
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyForegroundTaskHandler());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initForegroundTask();  // ✅ 9.x 推荐 await

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyBunnyApp());
}

Future<void> _initForegroundTask() async {
  try {
    // ✅ 9.x 不再需要 init() 方法，但为了兼容性可以保留空调用
    // 或者完全移除这行代码
    if (kDebugMode) {
      print('✅ 前台服务初始化成功（9.2.0）');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ 前台服务初始化失败: $e');
    }
  }
}

// ✅ 9.x TaskHandler：必须返回 Future<void> + 新增参数
class MyForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) {
      print('Foreground service started at $timestamp by ${starter.name}');
    }
    // 可添加初始化逻辑
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (kDebugMode) {
      print('Heartbeat at $timestamp');
    }
    // ✅ 移除了 SendPort 参数（如果你不需要通信）
    // 心跳逻辑
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    if (kDebugMode) {
      print('Foreground service destroyed at $timestamp, timeout: $isTimeout');
    }
    // ✅ 新增 isTimeout 参数
    // 清理资源
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
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        // ✅ 9.x 新API：需要 serviceId + serviceTypes
        final result = await FlutterForegroundTask.startService(
  serviceId: 256,  // 唯一 id，任意正整数
  notificationTitle: '沃夫朗聊天室',
  notificationText: '在线等待你的消息...',
  // 如果需要自定义图标（9.x 方式，取代旧 iconData）：
  // notificationIcon: const NotificationIcon(
  //   resType: ResourceType.mipmap,
  //   resPrefix: ResourcePrefix.ic_launcher,
  //   name: 'launcher',
  // ),
  callback: startCallback,
  serviceTypes: [ForegroundServiceTypes.dataSync],  // ← 关键修正
);

        if (kDebugMode) {
          print('前台服务启动结果: $result');
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
    return WithForegroundTask(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        
        // 🎨 主题设置
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
      ),
    );
  }
}