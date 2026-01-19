// lib/main.dart - 支持即时主题切换
import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'pages/main_screen.dart';
import 'pages/chat/chat_character_edit_page.dart';
import 'pages/me/profile_settings_page.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MyBunnyApp());
}

class MyBunnyApp extends StatefulWidget {
  const MyBunnyApp({super.key});

  @override
  State<MyBunnyApp> createState() => _MyBunnyAppState();
}

class _MyBunnyAppState extends State<MyBunnyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final StorageService _storage = StorageService();

  // 🎨 新增：全局Key用于刷新整个应用
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final savedMode = await _storage.getThemeMode();
    _updateThemeMode(savedMode);
  }

  // 🎨 新增：更新主题模式
  void _updateThemeMode(String savedMode) {
    setState(() {
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  // 🎨 新增：外部调用来更新主题（从设置页面调用）
  void changeTheme(String mode) {
    _updateThemeMode(mode);
  }

  // 🎨 新增：获取当前主题设置
  Future<String> getCurrentTheme() async {
    return await _storage.getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      navigatorKey: _navigatorKey, // 🎨 新增：设置导航键
      home: const MainScreen(),
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}