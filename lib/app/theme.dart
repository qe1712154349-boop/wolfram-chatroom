// lib/app/theme.dart - 完整修复版本
import 'package:flutter/material.dart';

class AppTheme {
  // ========== 主色 ==========
  static const Color primaryLight = Color(0xFFFF5A7E);
  static const Color primaryDark = Color(0xFFF95685);

  // ========== 背景色 ==========
  static const Color backgroundLight = Color(0xFFFDF7F7);
  static const Color backgroundDark = Color(0xFF060405);
  static const Color surfaceLight = Color(0xFFFDF7F7);
  static const Color surfaceDark = Color(0xFF060405);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  static const Color surfaceVariantDark = Color(0xFF1E1E1E);

  // ========== 文字色 ==========
  static const Color onSurfaceLight = Color(0xFF1D1D1F);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color onSurfaceVariantLight = Color(0xFF6D6D6F);
  static const Color onSurfaceVariantDark = Color(0xFFAAAAAA);

  // ========== 边框/轮廓色（关键！解决 Switch 边缘黑色问题） ==========
  static const Color outlineLight = Color(0xFFE0E0E0); // 浅灰色
  static const Color outlineDark = Color(0xFF424242); // 深灰色
  static const Color outlineVariantLight = Color(0xFFC7C7CC); // 中灰色
  static const Color outlineVariantDark = Color(0xFF303030); // 更深灰

  // ========== 卡片/容器色 ==========
  static const Color cardColorLight = Colors.white;
  static const Color cardColorDark = Color(0xFF1A1A1A);

  // ========== 其他功能色 ==========
  static const Color secondaryContainerLight = Color(0xFFFFE4E9);
  static const Color secondaryContainerDark = Color(0xFF3A1F25);
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);

  // ========== Switch 专用颜色（方便修改） ==========
  static const Color switchActiveThumb = Color(0xFFFF5A7E); // 开启小球颜色
  static final Color switchActiveTrack =
      Color(0xFFFF5A7E).withValues(alpha: 0x80); // 50%透明度
  static const Color switchInactiveThumb =
      Color(0xFF757575); // 关闭小球颜色 ← 这里可以修改按钮off小球的颜色
  static const Color switchInactiveTrack = Color(0xFFE0E0E0); // 关闭轨道颜色
  static const Color switchTrackOutline = Color(0xFFBDBDBD); // 轨道边框颜色

  // ========== 文字颜色（与按钮分开） ==========
  static const Color textPrimaryLight = Color(0xFF1D1D1F); // 主要文字
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFF6D6D6F); // 次要文字
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

  // ========== 文字颜色（兼容旧代码） ==========
  static const Color primaryTextLight = Color(0xFF1D1D1F);
  static const Color primaryTextDark = Color(0xFFFFFFFF);
  static const Color secondaryTextLight = Color(0xFF8E8E93);
  static const Color secondaryTextDark = Color(0xFF9E9E9E);
  static const Color narrationTextLight = Color(0xFF6D6D6F);
  static const Color narrationTextDark = Color(0xFFAAAAAA);
  static const Color userTextColorLight = Color(0xFFBB2D71);
  static const Color userTextColorDark = Color(0xFFFFFFFF);

  // ========== 尺寸/圆角 ==========
  static const double bubbleBorderRadius = 18.0;

  // ========== 主题定义 ==========
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // 1. colorScheme - 基础颜色系统（不影响Switch）
        colorScheme: ColorScheme.light(
          primary: primaryLight, // 主色
          surface: surfaceLight, // 表面色
          onSurface: textPrimaryLight, // 表面文字色
          // outline 保持Flutter默认，不影响Switch
        ),

        // 2. 文字主题 - 使用专门的文字颜色
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: textPrimaryLight),
          bodyMedium: TextStyle(
            fontFamily: 'System',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.4,
            color: textPrimaryLight, // 使用文字专用颜色
          ),
          bodySmall: TextStyle(color: textSecondaryLight),
          titleMedium: TextStyle(color: textPrimaryLight),
          labelLarge: TextStyle(color: textPrimaryLight),
        ),

        // 3. Switch主题 - 独立配置，不影响文字
        // 注意：Flutter 3.38.7 使用 WidgetStateProperty 和 WidgetState
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryLight; // 硬编码颜色保持不变
              }
              return switchInactiveThumb; // 关闭状态 - 深灰色小球
            },
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return switchActiveTrack; // 开启轨道
              }
              return switchInactiveTrack; // 关闭轨道
            },
          ),
          // 边框颜色
          trackOutlineColor: WidgetStateProperty.all(switchTrackOutline),
          // 边框宽度：开启时0，关闭时1px
          trackOutlineWidth: WidgetStateProperty.resolveWith<double?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return 0.0; // 开启时不要边框
              }
              return 1.0; // 关闭时1px边框
            },
          ),
        ),

        // 4. 其他主题配置保持不变...
        scaffoldBackgroundColor: backgroundLight,
        primaryColor: primaryLight,
        cardColor: cardColorLight,
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceLight,
          elevation: 0,
          foregroundColor: textPrimaryLight,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryLight,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
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
            borderSide: BorderSide(color: primaryLight),
          ),
        ),
      );

  // 暗色主题类似配置...
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // colorScheme - 暗色版本
        colorScheme: ColorScheme.dark(
          primary: primaryDark,
          surface: surfaceDark,
          onSurface: textPrimaryDark,
        ),

        // 文字主题
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: textPrimaryDark),
          bodyMedium:
              TextStyle(color: Colors.grey[200], fontSize: 16, height: 1.4),
          bodySmall: TextStyle(color: Colors.grey[400], fontSize: 14),
          titleMedium: TextStyle(color: textPrimaryDark),
          labelLarge: TextStyle(color: textPrimaryDark),
        ),

        // Switch主题 - 暗色版本
        // 注意：Flutter 3.38.7 使用 WidgetStateProperty 和 WidgetState
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryDark; // 暗色主色
              }
              return const Color(0xFF9E9E9E); // 暗色关闭小球
            },
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryDark.withValues(alpha: 0x80); // 50%透明度
              }
              return const Color(0xFF424242); // 暗色关闭轨道
            },
          ),
          // 边框颜色
          trackOutlineColor: WidgetStateProperty.all(const Color(0xFF616161)),
          // 边框宽度：开启时0，关闭时1px
          trackOutlineWidth: WidgetStateProperty.resolveWith<double?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return 0.0; // 开启时不要边框
              }
              return 1.0; // 关闭时1px边框
            },
          ),
        ),

        // ... 其他暗色主题配置
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: primaryDark,
        cardColor: cardColorDark,
        appBarTheme: AppBarTheme(
          backgroundColor: chatRoomTopDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: chatRoomTopDark,
          selectedItemColor: primaryDark,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        iconTheme: IconThemeData(color: Colors.grey[300]),
        dividerColor: Colors.grey[800],
        inputDecorationTheme: InputDecorationTheme(
          fillColor: messageFieldBackgroundDark,
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryDark),
          ),
        ),
      );

  // ========== 兼容性方法（保持现有代码不变） ==========

  // 旧常量别名（兼容现有代码）
  static const Color appBackgroundLight = backgroundLight;
  static const Color appBackgroundDark = backgroundDark;
  static const Color pinkAccent = primaryLight;
  static const Color pinkAccentDark = primaryDark;

  static Color get darkBackground => appBackgroundDark;

  // ========== 样式方法 ==========

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

  // ========== 颜色获取方法 ==========

  static Color getAppBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.surface;
  }

  static Color getAiBubbleColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.surface
        : cs.surface;
  }

  static Color getAiBubbleBorder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.outline.withValues(alpha: 0.3)
        : cs.outlineVariant.withValues(alpha: 0.3);
  }

  static Color getUserBubbleColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.primaryContainer
        : cs.primaryContainer;
  }

  static Color getUserBubbleBorder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.outline.withValues(alpha: 0.3)
        : cs.outlineVariant.withValues(alpha: 0.3);
  }

  static Color getChatRoomTop(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.surface
        : cs.surface;
  }

  static Color getMessageInputBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.surface
        : cs.surface;
  }

  static Color getMessageFieldBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.surface;
  }

  static Color getMessageFieldBorder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.outline;
  }

  static Color getUserTextColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.onPrimary
        : cs.onPrimary;
  }

  // ========== 新增：获取边框颜色方法 ==========

  static Color getOutlineColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.outline;
  }

  static Color getOutlineVariantColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.outlineVariant;
  }
}
