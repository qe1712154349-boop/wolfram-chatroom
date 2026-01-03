// lib/app/app.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import '../pages/main_screen.dart';
import '../pages/chat/chat_character_edit_page.dart'; // 导入角色编辑页面
import '../pages/me/profile_settings_page.dart'; // 导入用户资料设置页面

class MyBunnyApp extends StatelessWidget {
  const MyBunnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      // 添加路由配置
      routes: {
        '/character-edit': (context) => const ChatCharacterEditPage(),
        '/profile-settings': (context) => const ProfileSettingsPage(),
      },
    );
  }
}