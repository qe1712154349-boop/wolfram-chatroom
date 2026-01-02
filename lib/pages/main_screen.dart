import 'package:flutter/material.dart';
import 'vow_page.dart';
import 'chat/chat_list_page.dart';
import 'entrance/entrance_main_page.dart';
import 'me/me_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    VowPage(),
    ChatListPage(),
    EntranceMainPage(),
    MePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5A7E),
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