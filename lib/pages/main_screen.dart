// lib/pages/main_screen.dart - 最终零错误版

import 'dart:io'; // Platform
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'vow_page.dart';
import 'chat/chat_list_page.dart';
import 'entrance/entrance_main_page.dart';
import 'me/me_page.dart';
import '../services/foreground_task_handler.dart';
import '../services/storage_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  bool _isLoadingData = true;
  final StorageService _storage = StorageService();

  final List<Widget> _pages = const [
    VowPage(),
    ChatListPage(),
    EntranceMainPage(),
    MePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadInitialData();

    // 只保留一个initState，这里启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupForegroundService();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _storage.getThemeMode(),
        _storage.getCharacterNickname(),
        _storage.getCharacterAvatarPath(),
        _storage.getUserProfile(),
        _storage.getShowUserAvatar(),
        _storage.getCharacterOpening(),
        _storage.getCharacterSystemPrompt(),
      ]);
    } catch (e) {
      debugPrint('数据加载失败: $e');
    }

    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _setupForegroundService() async {
    if (Platform.isAndroid) {
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        FlutterForegroundTask.requestNotificationPermission(); // void
      }

      final ignoring =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!ignoring) {
        FlutterForegroundTask.requestIgnoreBatteryOptimization(); // void
      }
    }

    // 去掉 await，因为 init 返回 void
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_chat_service',
        channelName: '聊天保活',
        channelDescription: '保持小猫在线接收消息',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
      ),
    );

    // 下面可以继续 await，因为 start/restart 返回 Future
    if (await FlutterForegroundTask.isRunningService) {
      final result = await FlutterForegroundTask.restartService();
      if (result is ServiceRequestSuccess) {
        debugPrint('前台服务重启成功（续命）');
      } else {
        debugPrint('重启失败');
      }
    } else {
      final result = await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: '小猫在线中～',
        notificationText: '监听你的消息...',
        notificationIcon: null,
        notificationInitialRoute: '/chat_room',
        notificationButtons: [
          NotificationButton(id: 'open', text: '打开App'),
        ],
        callback: startForegroundTask,
      );

      if (result is ServiceRequestSuccess) {
        debugPrint('前台服务启动成功');
      } else {
        debugPrint('启动失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD2DD), Color(0xFFFFB6C1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: '心事'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: '聊天'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined), label: '入口'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
