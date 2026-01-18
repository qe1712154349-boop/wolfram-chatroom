// lib/app/ui_theme_manager.dart - 完整修复版本
import 'package:flutter/material.dart';

// 主题枚举
enum UITheme {
  strawberryCandy,  // 草莓糖心🍓（基于版本B）
  pickleMilk,       // 酸菜牛奶🥛（基于版本A）
  system            // 跟随系统（默认）
}

// 草莓糖心主题颜色配置（基于版本B）
class StrawberryCandyTheme {
  // 亮色模式
  static const Color lightBackground = Color(0xFFFFF8FA);
  static const Color lightPrimary = Color(0xFFFF5A7E);
  static const Color lightPrimaryLight = Color(0xFFFFB6C1);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightHintText = Color(0xFF6D6D6F);
  static const Color lightBorder = Color(0xFFF1DCDE);
  
  // 暗色模式
  static const Color darkBackground = Color(0xFF060405);
  static const Color darkPrimary = Color(0xFFF95685);
  static const Color darkPrimaryLight = Color(0xFFF95685);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkHintText = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF333333);
}

// 酸菜牛奶主题颜色配置（基于版本A）
class PickleMilkTheme {
  // 亮色模式
  static const Color lightBackground = Color(0xFFFDF7F7);
  static const Color lightPrimary = Color(0xFFFF5A7E);
  static const Color lightPrimaryLight = Color(0xFFFFB6C1);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1D1D1F);
  static const Color lightHintText = Color(0xFF8E8E93);
  static const Color lightBorder = Color(0xFFD8D8D8);
  
  // 暗色模式
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkPrimary = Color(0xFFF95685);
  static const Color darkPrimaryLight = Color(0xFFF95685);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkHintText = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF444444);
}

// 主题管理器
class UIThemeManager {
  // 获取当前主题的显示名称
  static String getThemeName(UITheme theme) {
    switch (theme) {
      case UITheme.strawberryCandy:
        return '草莓糖心🍓';
      case UITheme.pickleMilk:
        return '酸菜牛奶🥛';
      case UITheme.system:
        return '跟随系统';
    }
  }

  // 获取主题图标
  static IconData getThemeIcon(UITheme theme) {
    switch (theme) {
      case UITheme.strawberryCandy:
        return Icons.cake;
      case UITheme.pickleMilk:
        return Icons.local_cafe;
      case UITheme.system:
        return Icons.settings;
    }
  }

  // 获取主题描述
  static String getThemeDescription(UITheme theme) {
    switch (theme) {
      case UITheme.strawberryCandy:
        return '清爽简洁的无边框设计，少女心配色';
      case UITheme.pickleMilk:
        return '优雅的边框设计，舒适的视觉层次';
      case UITheme.system:
        return '跟随系统外观设置';
    }
  }

  // 根据当前主题获取颜色（用于动态切换）
  static Color getBackgroundColor(BuildContext context, UITheme uiTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (uiTheme == UITheme.strawberryCandy) {
      return isDark ? StrawberryCandyTheme.darkBackground : StrawberryCandyTheme.lightBackground;
    } else {
      return isDark ? PickleMilkTheme.darkBackground : PickleMilkTheme.lightBackground;
    }
  }

  static Color getPrimaryColor(BuildContext context, UITheme uiTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (uiTheme == UITheme.strawberryCandy) {
      return isDark ? StrawberryCandyTheme.darkPrimary : StrawberryCandyTheme.lightPrimary;
    } else {
      return isDark ? PickleMilkTheme.darkPrimary : PickleMilkTheme.lightPrimary;
    }
  }

  static Color getTextColor(BuildContext context, UITheme uiTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (uiTheme == UITheme.strawberryCandy) {
      return isDark ? StrawberryCandyTheme.darkText : StrawberryCandyTheme.lightText;
    } else {
      return isDark ? PickleMilkTheme.darkText : PickleMilkTheme.lightText;
    }
  }

  // 构建输入框边框（草莓糖心主题 - 无边框）
  static InputBorder buildTextFieldBorderStrawberryCandy(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
  }

  // 构建输入框边框（酸菜牛奶主题 - 有边框）
  static InputBorder buildTextFieldBorderPickleMilk(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? PickleMilkTheme.darkBorder : PickleMilkTheme.lightBorder,
        width: 1,
      ),
    );
  }

  // 构建焦点边框（草莓糖心主题）
  static InputBorder buildTextFieldFocusedBorderStrawberryCandy(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? StrawberryCandyTheme.darkPrimary : StrawberryCandyTheme.lightPrimary;
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: primaryColor,
        width: 2,
      ),
    );
  }

  // 构建焦点边框（酸菜牛奶主题）
  static InputBorder buildTextFieldFocusedBorderPickleMilk(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? PickleMilkTheme.darkPrimary : PickleMilkTheme.lightPrimary;
    
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: primaryColor,
        width: 2,
      ),
    );
  }

  // 根据主题获取按钮样式
  static ButtonStyle getButtonStyle(BuildContext context, UITheme uiTheme) {
    final primaryColor = getPrimaryColor(context, uiTheme);
    
    if (uiTheme == UITheme.strawberryCandy) {
      // 草莓糖心主题按钮：无阴影，圆角
      return ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
      );
    } else {
      // 酸菜牛奶主题按钮：轻微阴影，圆角
      return ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16),
      );
    }
  }

  // 获取卡片颜色
  static Color getCardColor(BuildContext context, UITheme uiTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (uiTheme == UITheme.strawberryCandy) {
      return isDark ? StrawberryCandyTheme.darkCard : StrawberryCandyTheme.lightCard;
    } else {
      return isDark ? PickleMilkTheme.darkCard : PickleMilkTheme.lightCard;
    }
  }

  // 获取提示文本颜色
  static Color getHintTextColor(BuildContext context, UITheme uiTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (uiTheme == UITheme.strawberryCandy) {
      return isDark ? StrawberryCandyTheme.darkHintText : StrawberryCandyTheme.lightHintText;
    } else {
      return isDark ? PickleMilkTheme.darkHintText : PickleMilkTheme.lightHintText;
    }
  }

  // 从字符串转换为UITheme枚举
  static UITheme fromString(String value) {
    switch (value) {
      case 'strawberryCandy':
        return UITheme.strawberryCandy;
      case 'pickleMilk':
        return UITheme.pickleMilk;
      default:
        return UITheme.system;
    }
  }

  // 将UITheme枚举转换为字符串
  static String themeToString(UITheme theme) {  // 改名避免冲突
    switch (theme) {
      case UITheme.strawberryCandy:
        return 'strawberryCandy';
      case UITheme.pickleMilk:
        return 'pickleMilk';
      case UITheme.system:
        return 'system';
    }
  }
}