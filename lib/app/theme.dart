import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDF7F7), // 全部页面背景 #FDF7F7
        primaryColor: const Color(0xFFFF5A7E),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFFF5A7E),
          type: BottomNavigationBarType.fixed,
        ),
        // 添加字体配置
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'System',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      );

  // 新的纯色方案
  static const Color appBackground = Color(0xFFFDF7F7); // 全部页面背景
  static const Color pinkAccent = Color(0xFFFF5A7E);
  static const Color aiBubbleColor = Color(0xFFFFFFFF); // AI气泡背景
  static const Color aiBubbleBorder = Color(0xFFF1DCDE); // AI气泡边框
  static const Color userBubbleColor = Color(0xFFFFEAEF); // 用户气泡背景
  static const Color userBubbleBorder = Color(0xFFEDD8DD); // 用户气泡边框
  static const Color chatRoomTop = Color(0xFFFCECEF); // 聊天室顶部颜色
  static const Color messageInputBackground = Color(0xFFFBDCE1); // 底部发消息大矩形
  static const Color messageFieldBackground = Color(0xFFFFFFFF); // 发消息框内背景
  static const Color messageFieldBorder = Color(0xFFB1A9AB); // 发消息框边框
  
  // 文字颜色
  static const Color primaryText = Color(0xFF1D1D1F);
  static const Color secondaryText = Color(0xFF8E8E93);
  static const Color narrationText = Color(0xFF6D6D6F);
  
  // 气泡圆角
  static const double bubbleBorderRadius = 18.0;
  
  // 旁白样式
  static const TextStyle narrationStyle = TextStyle(
    fontSize: 14,
    color: narrationText,
    fontStyle: FontStyle.italic,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  
  // 对话样式
  static const TextStyle dialogueStyle = TextStyle(
    fontSize: 16,
    color: primaryText,
    height: 1.4,
    fontWeight: FontWeight.normal,
  );
  
  // 系统时间样式
  static const TextStyle systemTimeStyle = TextStyle(
    fontSize: 12,
    color: secondaryText,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  
  // 辅助方法：创建带透明度的颜色
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: (opacity * 255).toDouble());
  }
}