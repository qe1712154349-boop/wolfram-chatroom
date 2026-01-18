// lib/main.dart - 完整修复版本
import 'package:flutter/material.dart';
import 'app/theme.dart';  // 使用修复后的 AppTheme
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

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final storage = StorageService();
    final savedMode = await storage.getThemeMode();
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 使用修复后的主题（已添加 useMaterial3: true）
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