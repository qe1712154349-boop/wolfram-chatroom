// lib/main.dart - 修改为支持即时主题切换
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

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _setupThemeListener();
  }

  Future<void> _loadThemeMode() async {
    final savedMode = await _storage.getThemeMode();
    _updateThemeMode(savedMode);
  }

  // 🎨 新增：设置主题监听器
  void _setupThemeListener() {
    // 这里可以添加监听器，当主题改变时重新加载
    // 由于SharedPreferences没有内置的监听，我们使用轮询或其他方式
    // 为了简化，我们可以在每次返回设置页面时重新加载
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

  // 🎨 新增：外部调用来更新主题
  void changeTheme(String mode) {
    _updateThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const MainScreen(),
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}