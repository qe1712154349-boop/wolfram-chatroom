// lib/app/theme.dart - 完整修复版本（Material 3 规范 + 零 null + 防崩溃）
import 'package:flutter/material.dart';

class AppTheme {
  // ========== 主色 ==========
  static const Color primaryLight = Color(0xFFFF5A7E);
  static const Color primaryDark = Color(0xFFF95685);

  // ========== 背景/表面色（Material 3 规范） ==========
  static const Color surfaceLight = Color(0xFFFDF7F7); // 替换 backgroundLight
  static const Color surfaceDark = Color(0xFF060405); // 替换 backgroundDark
  static const Color surfaceContainerLowestLight =
      Color(0xFFFDF7F7); // 替换 surfaceVariantLight
  static const Color surfaceContainerLowestDark =
      Color(0xFF060405); // 替换 surfaceVariantDark

  // ========== 文字色 ==========
  static const Color onSurfaceLight = Color(0xFF1D1D1F);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariantLight = Color(0xFF6D6D6F);
  static const Color onSurfaceVariantDark = Color(0xFFAAAAAA);

  // ========== 边框/轮廓色（Material 3 规范） ==========
  static const Color outlineLight = Color(0xFFE0E0E0);
  static const Color outlineDark = Color(0xFF424242);
  static const Color outlineVariantLight = Color(0xFFC7C7CC);
  static const Color outlineVariantDark = Color(0xFF303030);

  // ========== 卡片/容器色 ==========
  static const Color cardColorLight = Colors.white;
  static const Color cardColorDark = Color(0xFF1A1A1A);

  // ========== 其他功能色 ==========
  static const Color secondaryContainerLight = Color(0xFFFFE4E9);
  static const Color secondaryContainerDark = Color(0xFF3A1F25);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);

  // ========== Switch 专用颜色（完整处理所有状态） ==========
  static const Color switchActiveThumb = Color(0xFFFF5A7E); // 开启小球
  static const Color switchInactiveThumb = Color(0xFF757575); // 关闭小球
  static const Color switchActiveTrack =
      Color(0x80FF5A7E); // 开启轨道（50% 透明，用 withAlpha 替代 deprecated）
  static const Color switchInactiveTrack = Color(0xFFE0E0E0); // 关闭轨道
  static const Color switchTrackOutline = Color(0xFFBDBDBD); // 轨道边框

  // ========== 文字颜色（兼容旧代码） ==========
  static const Color textPrimaryLight = Color(0xFF1D1D1F);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF6D6D6F);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);

  // ========== 气泡颜色 ==========
  static const Color aiBubbleColorLight = Color(0xFFFFFFFF);
  static const Color aiBubbleBorderLight = Color(0xFFF1DCDE);
  static const Color userBubbleColorLight = Color(0xFFFFEAEF);
  static const Color userBubbleBorderLight = Color(0xFFEDD8DD);

  static const Color aiBubbleColorDark = Color(0xFF1A1A1A);
  static const Color aiBubbleBorderDark = Color(0xFF333333);
  static const Color userBubbleColorDark = Color(0xFFF95685);
  static const Color userBubbleBorderDark = Color(0xFFD6406E);

  // ========== 页面特定颜色 ==========
  static const Color chatRoomTopLight = Color(0xFFFCECEF);
  static const Color chatRoomTopDark = Color(0xFF0A0A0A);

  static const Color messageInputBackgroundLight = Color(0xFFFBDCE1);
  static const Color messageInputBackgroundDark = Color(0xFF121212);

  static const Color messageFieldBackgroundLight = Color(0xFFFFFFFF);
  static const Color messageFieldBackgroundDark = Color(0xFF252525);

  static const Color messageFieldBorderLight = Color(0xFFB1A9AB);
  static const Color messageFieldBorderDark = Color(0xFF444444);

  // ========== 尺寸/圆角 ==========
  static const double bubbleBorderRadius = 18.0;

  // ========== 主题定义 ==========
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // 1. colorScheme - 基础颜色系统（Material 3 规范）
        colorScheme: ColorScheme.light(
          primary: primaryLight,
          onPrimary: Colors.white,
          primaryContainer: secondaryContainerLight,
          onPrimaryContainer: primaryLight,
          secondary: primaryLight.withAlpha(204), // 80% 透明，用 withAlpha
          onSecondary: Colors.white,
          secondaryContainer: secondaryContainerLight,
          onSecondaryContainer: primaryLight,
          surface: surfaceLight,
          onSurface: onSurfaceLight,
          surfaceVariant: surfaceContainerLowestLight, // 替换 surfaceVariant
          onSurfaceVariant: onSurfaceVariantLight,
          outline: outlineLight,
          outlineVariant: outlineVariantLight,
          error: errorLight,
          onError: Colors.white,
        ),

        // 2. 文字主题
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: textPrimaryLight),
          bodyMedium: TextStyle(
            fontFamily: 'System',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.4,
            color: textPrimaryLight,
          ),
          bodySmall: TextStyle(color: textSecondaryLight),
          titleMedium: TextStyle(color: textPrimaryLight),
          labelLarge: TextStyle(color: textPrimaryLight),
        ),

        // 3. Switch主题 - 完整处理所有 WidgetState（防 null）
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return switchActiveThumb;
              }
              if (states.contains(WidgetState.disabled)) {
                return switchInactiveThumb.withAlpha(128);
              }
              return switchInactiveThumb;
            },
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return switchActiveTrack;
              }
              if (states.contains(WidgetState.disabled)) {
                return switchInactiveTrack.withAlpha(128);
              }
              return switchInactiveTrack;
            },
          ),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent; // 开启无边框
              }
              if (states.contains(WidgetState.disabled)) {
                return switchTrackOutline.withAlpha(128);
              }
              return switchTrackOutline;
            },
          ),
          trackOutlineWidth: WidgetStateProperty.resolveWith<double?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return 0.0;
              }
              return 1.0;
            },
          ),
        ),

        // 4. 其他主题配置（使用新字段）
        scaffoldBackgroundColor: surfaceLight,
        primaryColor: primaryLight,
        cardColor: cardColorLight,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceLight,
          elevation: 0,
          foregroundColor: onSurfaceLight,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceLight,
          selectedItemColor: primaryLight,
          unselectedItemColor: onSurfaceVariantLight,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: onSurfaceLight),
        dividerColor: outlineVariantLight,
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: outlineLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: outlineLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryLight),
          ),
        ),
      );

  // 暗色主题（类似修复）
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primaryDark,
          onPrimary: Colors.white,
          primaryContainer: secondaryContainerDark,
          onPrimaryContainer: primaryDark,
          secondary: primaryDark.withAlpha(204),
          onSecondary: Colors.white,
          secondaryContainer: secondaryContainerDark,
          onSecondaryContainer: primaryDark,
          surface: surfaceDark,
          onSurface: onSurfaceDark,
          surfaceVariant: surfaceContainerLowestDark,
          onSurfaceVariant: onSurfaceVariantDark,
          outline: outlineDark,
          outlineVariant: outlineVariantDark,
          error: errorDark,
          onError: Colors.white,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: textPrimaryDark),
          bodyMedium: TextStyle(
            fontFamily: 'System',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.4,
            color: textPrimaryDark,
          ),
          bodySmall: TextStyle(color: textSecondaryDark),
          titleMedium: TextStyle(color: textPrimaryDark),
          labelLarge: TextStyle(color: textPrimaryDark),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return switchActiveThumb;
              }
              if (states.contains(WidgetState.disabled)) {
                return switchInactiveThumb.withAlpha(128);
              }
              return switchInactiveThumb;
            },
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return switchActiveTrack;
              }
              if (states.contains(WidgetState.disabled)) {
                return switchInactiveTrack.withAlpha(128);
              }
              return switchInactiveTrack;
            },
          ),
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              if (states.contains(WidgetState.disabled)) {
                return switchTrackOutline.withAlpha(128);
              }
              return switchTrackOutline;
            },
          ),
          trackOutlineWidth: WidgetStateProperty.resolveWith<double?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return 0.0;
              }
              return 1.0;
            },
          ),
        ),
        scaffoldBackgroundColor: surfaceDark,
        primaryColor: primaryDark,
        cardColor: cardColorDark,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceDark,
          elevation: 0,
          foregroundColor: onSurfaceDark,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceDark,
          selectedItemColor: primaryDark,
          unselectedItemColor: onSurfaceVariantDark,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: onSurfaceDark),
        dividerColor: outlineVariantDark,
        inputDecorationTheme: InputDecorationTheme(
          fillColor: messageFieldBackgroundDark,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: outlineDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: outlineDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryDark),
          ),
        ),
      );

  // ========== 兼容性方法（保持现有代码不变） ==========
  static Color getAppBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getAiBubbleColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getAiBubbleBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline.withAlpha(77); // 0.3 透明
  }

  static Color getUserBubbleColor(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }

  static Color getUserBubbleBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline.withAlpha(77);
  }

  static Color getChatRoomTop(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getMessageInputBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getMessageFieldBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getMessageFieldBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color getUserTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  static Color getOutlineColor(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color getOutlineVariantColor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }
}
