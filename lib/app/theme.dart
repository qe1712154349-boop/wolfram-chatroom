// lib/app/theme.dart - 完整修复版本
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        // 修复1：添加 useMaterial3: true
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFDF7F7),
        primaryColor: const Color(0xFFFF5A7E),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDF7F7),
          elevation: 0,
          foregroundColor: Color(0xFF1D1D1F),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFFF5A7E),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1D1D1F)),
          bodyMedium: TextStyle(
            fontFamily: 'System',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.4,
            color: Color(0xFF1D1D1F),
          ),
          bodySmall: TextStyle(color: Color(0xFF6D6D6F)),
          titleMedium: TextStyle(color: Color(0xFF1D1D1F)),
          labelLarge: TextStyle(color: Color(0xFF1D1D1F)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
        dividerColor: Colors.grey[300],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFFFF5A7E)),
          ),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF5A7E),
          background: Color(0xFFFDF7F7),
          surface: Colors.white,
          onBackground: Color(0xFF1D1D1F),
          onSurface: Color(0xFF1D1D1F),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        // 修复2：添加 useMaterial3: true
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060405),
        primaryColor: const Color(0xFFF95685),       // 强调色（玫红）
        cardColor: const Color(0xFF1A1A1A),              // 卡片、ListTile 背景
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: Color(0xFFF95685),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.grey[100]),
          bodyMedium: TextStyle(color: Colors.grey[200], fontSize: 16, height: 1.4),
          bodySmall: TextStyle(color: Colors.grey[400], fontSize: 14),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.grey[300]),
        dividerColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF252525),
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFFF95685)),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF95685),
          background: Color(0xFF060405),
          surface: Color(0xFF1A1A1A),
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
      );

  // 保留你原来的常量，但添加暗色版本
  static const Color appBackgroundLight = Color(0xFFFDF7F7);
  static const Color appBackgroundDark = Color(0xFF060405);
  
  static const Color pinkAccent = Color(0xFFFF5A7E);
  static const Color pinkAccentDark = Color(0xFFF95685);
  
  // 亮色模式气泡颜色
  static const Color aiBubbleColorLight = Color(0xFFFFFFFF);
  static const Color aiBubbleBorderLight = Color(0xFFF1DCDE);
  static const Color userBubbleColorLight = Color(0xFFFFEAEF);
  static const Color userBubbleBorderLight = Color(0xFFEDD8DD);
  
  // 暗色模式气泡颜色
  static const Color aiBubbleColorDark = Color(0xFF1A1A1A);
  static const Color aiBubbleBorderDark = Color(0xFF333333);
  static const Color userBubbleColorDark = Color(0xFFF95685);
  static const Color userBubbleBorderDark = Color(0xFFD6406E);
  
  static const Color chatRoomTopLight = Color(0xFFFCECEF);
  static const Color chatRoomTopDark = Color(0xFF0A0A0A);
  
  static const Color messageInputBackgroundLight = Color(0xFFFBDCE1);
  static const Color messageInputBackgroundDark = Color(0xFF121212);
  
  static const Color messageFieldBackgroundLight = Color(0xFFFFFFFF);
  static const Color messageFieldBackgroundDark = Color(0xFF252525);
  
  static const Color messageFieldBorderLight = Color(0xFFB1A9AB);
  static const Color messageFieldBorderDark = Color(0xFF444444);
  
  // 文字颜色
  static const Color primaryTextLight = Color(0xFF1D1D1F);
  static const Color primaryTextDark = Color(0xFFFFFFFF);
  static const Color secondaryTextLight = Color(0xFF8E8E93);
  static const Color secondaryTextDark = Color(0xFF9E9E9E);
  static const Color narrationTextLight = Color(0xFF6D6D6F);
  static const Color narrationTextDark = Color(0xFFAAAAAA);
  static const Color userTextColorLight = Color(0xFFBB2D71);
  static const Color userTextColorDark = Color(0xFFFFFFFF);
  
  // 气泡圆角
  static const double bubbleBorderRadius = 18.0;

  static get darkBackground => null;
  
  // 旁白样式
  static TextStyle narrationStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    color: Theme.of(context).brightness == Brightness.dark 
        ? narrationTextDark 
        : narrationTextLight,
    fontStyle: FontStyle.italic,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );
  
  // 对话样式
  static TextStyle dialogueStyle(BuildContext context) => TextStyle(
    fontSize: 16,
    color: Theme.of(context).brightness == Brightness.dark 
        ? primaryTextDark 
        : primaryTextLight,
    height: 1.4,
    fontWeight: FontWeight.normal,
  );
  
  // 系统时间样式
  static TextStyle systemTimeStyle(BuildContext context) => TextStyle(
    fontSize: 12,
    color: Theme.of(context).brightness == Brightness.dark 
        ? secondaryTextDark 
        : secondaryTextLight,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  
  // 根据主题获取颜色
  static Color getAppBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? appBackgroundDark 
        : appBackgroundLight;
  }
  
  static Color getAiBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? aiBubbleColorDark 
        : aiBubbleColorLight;
  }
  
  static Color getAiBubbleBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? aiBubbleBorderDark 
        : aiBubbleBorderLight;
  }
  
  static Color getUserBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? userBubbleColorDark 
        : userBubbleColorLight;
  }
  
  static Color getUserBubbleBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? userBubbleBorderDark 
        : userBubbleBorderLight;
  }
  
  static Color getChatRoomTop(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? chatRoomTopDark 
        : chatRoomTopLight;
  }
  
  static Color getMessageInputBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? messageInputBackgroundDark 
        : messageInputBackgroundLight;
  }
  
  static Color getMessageFieldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? messageFieldBackgroundDark 
        : messageFieldBackgroundLight;
  }
  
  static Color getMessageFieldBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? messageFieldBorderDark 
        : messageFieldBorderLight;
  }
  
  static Color getUserTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? userTextColorDark 
        : userTextColorLight;
  }
}