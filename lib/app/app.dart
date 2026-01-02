import 'package:flutter/material.dart';
import 'theme.dart';
import '../pages/main_screen.dart';

class MyBunnyApp extends StatelessWidget {
  const MyBunnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}