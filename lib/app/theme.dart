import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        primaryColor: const Color(0xFFFF5A7E),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFF5A7E),
          type: BottomNavigationBarType.fixed,
        ),
      );

  static const Color pinkAccent = Color(0xFFFF5A7E);
  static const Color lightPink = Color(0xFFFFF0F3);
  static const Color chatPink = Color(0xFFFFF5F8);
  static const Color bubblePink = Color(0xFFFFD1DC);
}