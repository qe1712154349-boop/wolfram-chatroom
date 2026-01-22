// lib/pages/main_screen.dart - 完整版本
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'vow_page.dart';
import 'chat/chat_list_page.dart';
import 'entrance/entrance_main_page.dart';
import 'me/me_page.dart';
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
  }

  Future<void> _loadInitialData() async {
    try {
      // 并行加载必要数据
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
      // 静默失败，不影响启动
      debugPrint('数据加载失败: $e');
    }

    // 延迟启动前台服务（让UI先出来）
    Future.delayed(const Duration(milliseconds: 500), () {
      _startForegroundService();
    });

    if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _startForegroundService() async {
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        final result = await FlutterForegroundTask.startService(
          notificationTitle: '小猫',
          notificationText: '在线等待你的消息...',
          notificationIcon: const NotificationIcon(metaDataName: 'foreground_icon'),
          notificationInitialRoute: '/chat_room',
        );
        if (result is ServiceRequestSuccess) {
          debugPrint('前台服务启动成功');
        }
      }
    } catch (e) {
      debugPrint('前台服务启动失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 显示极简的加载指示器（如果数据还在加载）
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 简单的猫咪图标
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

    // 正常显示主界面
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
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: '心事'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '聊天'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: '入口'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}