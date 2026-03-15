import 'package:flutter/material.dart';
import '../core/color_semantics.dart';
import 'base_tokens.dart';

/// 语义映射器 - 将基础颜色令牌映射到颜色语义
/// 每个主题都会定义自己的映射关系
class SemanticMapper {
  /// 默认主题的亮色映射
  static Map<ColorSemantic, Color> defaultLight() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: BaseColorTokens.pinkUserBubble,
      ColorSemantic.userBubbleBorder: BaseColorTokens.borderLightPink,
      ColorSemantic.userBubbleText: BaseColorTokens.pinkUserText,

      ColorSemantic.aiBubbleBackground: BaseColorTokens.white,
      ColorSemantic.aiBubbleBorder: BaseColorTokens.borderLightGray,
      ColorSemantic.aiBubbleText: BaseColorTokens.textPrimaryLight,

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: BaseColorTokens.pinkPrimary,
      ColorSemantic.secondary: BaseColorTokens.pinkLight,
      ColorSemantic.accent: BaseColorTokens.pinkPrimary,

      ColorSemantic.background: BaseColorTokens.backgroundLight,
      ColorSemantic.surface: BaseColorTokens.surfaceLight,
      ColorSemantic.surfaceVariant: BaseColorTokens.gray100,

      ColorSemantic.textPrimary: BaseColorTokens.textPrimaryLight,
      ColorSemantic.textSecondary: BaseColorTokens.textSecondaryLight,
      ColorSemantic.textHint: BaseColorTokens.textHintLight,

      ColorSemantic.border: BaseColorTokens.gray300,
      ColorSemantic.divider: BaseColorTokens.gray200,

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: BaseColorTokens.pinkPrimary,
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: BaseColorTokens.gray100,
      ColorSemantic.buttonSecondaryText: BaseColorTokens.textPrimaryLight,

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: BaseColorTokens.surfaceLight,
      ColorSemantic.appBarText: BaseColorTokens.textPrimaryLight,
      ColorSemantic.inputBackground: BaseColorTokens.white,
      ColorSemantic.inputBorder: BaseColorTokens.gray300,
      ColorSemantic.inputText: BaseColorTokens.textPrimaryLight,
      ColorSemantic.switchActive: BaseColorTokens.pinkPrimary,
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successLight,
      ColorSemantic.warning: BaseColorTokens.warningLight,
      ColorSemantic.error: BaseColorTokens.errorLight,
      ColorSemantic.info: BaseColorTokens.infoLight,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFFF5F5F5),
      ColorSemantic.primaryContainer: const Color(0xFFFFE4E9),
      ColorSemantic.onPrimaryContainer: const Color(0xFF6D1F34),
      ColorSemantic.onSurface: const Color(0xFF1C1B1F),
      ColorSemantic.onSurfaceVariant: const Color(0xFF666666),
      ColorSemantic.cardBackground: BaseColorTokens.white,
      ColorSemantic.cardBorder: BaseColorTokens.gray300,
      ColorSemantic.textFieldFill: BaseColorTokens.white,
      ColorSemantic.textFieldHint: BaseColorTokens.textHintLight,
      ColorSemantic.buttonBackground: BaseColorTokens.pinkPrimary,
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: BaseColorTokens.backgroundLight,
      ColorSemantic.messageInputBackground: BaseColorTokens.white,
      ColorSemantic.messageInputBorder: BaseColorTokens.gray300,
      ColorSemantic.messageInputText: BaseColorTokens.textPrimaryLight,
      ColorSemantic.messageInputHint: BaseColorTokens.textHintLight,
      ColorSemantic.scrollToBottomButton: BaseColorTokens.pinkPrimary,
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: BaseColorTokens.pinkPrimary,
    };
  }

  /// 默认主题的暗色映射
  static Map<ColorSemantic, Color> defaultDark() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: const Color(0xFF2A1A1F),
      ColorSemantic.userBubbleBorder: const Color(0xFF443339),
      ColorSemantic.userBubbleText: BaseColorTokens.pink100,

      ColorSemantic.aiBubbleBackground: BaseColorTokens.surfaceDark,
      ColorSemantic.aiBubbleBorder: BaseColorTokens.gray700,
      ColorSemantic.aiBubbleText: BaseColorTokens.textPrimaryDark,

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: BaseColorTokens.pinkPrimaryDark,
      ColorSemantic.secondary: const Color(0xFF3A1F25),
      ColorSemantic.accent: BaseColorTokens.pinkPrimaryDark,

      ColorSemantic.background: BaseColorTokens.backgroundDark,
      ColorSemantic.surface: BaseColorTokens.surfaceDark,
      ColorSemantic.surfaceVariant: BaseColorTokens.gray800,

      ColorSemantic.textPrimary: BaseColorTokens.textPrimaryDark,
      ColorSemantic.textSecondary: BaseColorTokens.textSecondaryDark,
      ColorSemantic.textHint: BaseColorTokens.textHintDark,

      ColorSemantic.border: BaseColorTokens.gray700,
      ColorSemantic.divider: BaseColorTokens.gray800,

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: BaseColorTokens.pinkPrimaryDark,
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: BaseColorTokens.gray800,
      ColorSemantic.buttonSecondaryText: BaseColorTokens.textPrimaryDark,

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: BaseColorTokens.surfaceDark,
      ColorSemantic.appBarText: BaseColorTokens.textPrimaryDark,
      ColorSemantic.inputBackground: const Color(0xFF252525),
      ColorSemantic.inputBorder: const Color(0xFF444444),
      ColorSemantic.inputText: BaseColorTokens.textPrimaryDark,
      ColorSemantic.switchActive: BaseColorTokens.pinkPrimaryDark,
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successDark,
      ColorSemantic.warning: BaseColorTokens.warningDark,
      ColorSemantic.error: BaseColorTokens.errorDark,
      ColorSemantic.info: BaseColorTokens.infoDark,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFF2A2A2A),
      ColorSemantic.primaryContainer: const Color(0xFF3A1F25),
      ColorSemantic.onPrimaryContainer: const Color(0xFFFFB6C1),
      ColorSemantic.onSurface: const Color(0xFFF5F5F5),
      ColorSemantic.onSurfaceVariant: const Color(0xFFBCB8B9),
      ColorSemantic.cardBackground: const Color(0xFF1F1F1F),
      ColorSemantic.cardBorder: BaseColorTokens.gray700,
      ColorSemantic.textFieldFill: const Color(0xFF252525),
      ColorSemantic.textFieldHint: BaseColorTokens.textHintDark,
      ColorSemantic.buttonBackground: BaseColorTokens.pinkPrimaryDark,
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: BaseColorTokens.backgroundDark,
      ColorSemantic.messageInputBackground: const Color(0xFF252525),
      ColorSemantic.messageInputBorder: const Color(0xFF444444),
      ColorSemantic.messageInputText: BaseColorTokens.textPrimaryDark,
      ColorSemantic.messageInputHint: BaseColorTokens.textHintDark,
      ColorSemantic.scrollToBottomButton: BaseColorTokens.pinkPrimaryDark,
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: BaseColorTokens.pinkPrimaryDark,
    };
  }

  /// 草莓糖心主题的亮色映射
  static Map<ColorSemantic, Color> strawberryCandyLight() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: BaseColorTokens.pinkUserBubble,
      ColorSemantic.userBubbleBorder: BaseColorTokens.borderLightPink,
      ColorSemantic.userBubbleText: BaseColorTokens.pinkUserText,

      ColorSemantic.aiBubbleBackground: BaseColorTokens.white,
      ColorSemantic.aiBubbleBorder: BaseColorTokens.borderLightGray,
      ColorSemantic.aiBubbleText: BaseColorTokens.textPrimaryLight,

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: const Color(0xFFFF7B9C), // 更亮的草莓粉
      ColorSemantic.secondary: const Color(0xFFFFD1DC), // 草莓奶油色
      ColorSemantic.accent: const Color(0xFFFF7B9C),

      ColorSemantic.background: const Color(0xFFFFF8FA), // 草莓牛奶背景
      ColorSemantic.surface: BaseColorTokens.white,
      ColorSemantic.surfaceVariant: const Color(0xFFFEF0F3),

      ColorSemantic.textPrimary: const Color(0xFF2C1A1F), // 深草莓籽色
      ColorSemantic.textSecondary: const Color(0xFF6D4F59),
      ColorSemantic.textHint: const Color(0xFFA88B95),

      ColorSemantic.border: const Color(0xFFF1DCDE), // 草莓茎色
      ColorSemantic.divider: const Color(0xFFFAEFF2),

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: const Color(0xFFFF7B9C),
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: const Color(0xFFFEF0F3),
      ColorSemantic.buttonSecondaryText: const Color(0xFF2C1A1F),

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: BaseColorTokens.white,
      ColorSemantic.appBarText: const Color(0xFF2C1A1F),
      ColorSemantic.inputBackground: BaseColorTokens.white,
      ColorSemantic.inputBorder: const Color(0xFFF1DCDE),
      ColorSemantic.inputText: const Color(0xFF2C1A1F),
      ColorSemantic.switchActive: const Color(0xFFFF7B9C),
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successLight,
      ColorSemantic.warning: BaseColorTokens.warningLight,
      ColorSemantic.error: BaseColorTokens.errorLight,
      ColorSemantic.info: BaseColorTokens.infoLight,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFFFEF0F3),
      ColorSemantic.primaryContainer: const Color(0xFFFFE4E9),
      ColorSemantic.onPrimaryContainer: const Color(0xFF6D1F34),
      ColorSemantic.onSurface: const Color(0xFF2C1A1F),
      ColorSemantic.onSurfaceVariant: const Color(0xFF6D4F59),
      ColorSemantic.cardBackground: BaseColorTokens.white,
      ColorSemantic.cardBorder: const Color(0xFFF1DCDE),
      ColorSemantic.textFieldFill: BaseColorTokens.white,
      ColorSemantic.textFieldHint: const Color(0xFFA88B95),
      ColorSemantic.buttonBackground: const Color(0xFFFF7B9C),
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: const Color(0xFFFFF8FA),
      ColorSemantic.messageInputBackground: BaseColorTokens.white,
      ColorSemantic.messageInputBorder: const Color(0xFFF1DCDE),
      ColorSemantic.messageInputText: const Color(0xFF2C1A1F),
      ColorSemantic.messageInputHint: const Color(0xFFA88B95),
      ColorSemantic.scrollToBottomButton: const Color(0xFFFF7B9C),
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: const Color(0xFFFF7B9C),
    };
  }

  /// 草莓糖心主题的暗色映射
  static Map<ColorSemantic, Color> strawberryCandyDark() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: const Color(0xFF3A1F25),
      ColorSemantic.userBubbleBorder: const Color(0xFF5A2F35),
      ColorSemantic.userBubbleText: const Color(0xFFFFB6C1),

      ColorSemantic.aiBubbleBackground: const Color(0xFF1E1E1E),
      ColorSemantic.aiBubbleBorder: const Color(0xFF3A3A3A),
      ColorSemantic.aiBubbleText: const Color(0xFFF5F5F5),

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: const Color(0xFFFF7B9C),
      ColorSemantic.secondary: const Color(0xFF4A2F35),
      ColorSemantic.accent: const Color(0xFFFF7B9C),

      ColorSemantic.background: const Color(0xFF0A0506),
      ColorSemantic.surface: const Color(0xFF1F1F1F),
      ColorSemantic.surfaceVariant: const Color(0xFF2A2A2A),

      ColorSemantic.textPrimary: const Color(0xFFF5F5F5),
      ColorSemantic.textSecondary: const Color(0xFFBBBBBB),
      ColorSemantic.textHint: const Color(0xFF888888),

      ColorSemantic.border: const Color(0xFF3A3A3A),
      ColorSemantic.divider: const Color(0xFF2A2A2A),

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: const Color(0xFFFF7B9C),
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: const Color(0xFF2A2A2A),
      ColorSemantic.buttonSecondaryText: const Color(0xFFF5F5F5),

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: const Color(0xFF1F1F1F),
      ColorSemantic.appBarText: const Color(0xFFF5F5F5),
      ColorSemantic.inputBackground: const Color(0xFF252525),
      ColorSemantic.inputBorder: const Color(0xFF3A3A3A),
      ColorSemantic.inputText: const Color(0xFFF5F5F5),
      ColorSemantic.switchActive: const Color(0xFFFF7B9C),
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successDark,
      ColorSemantic.warning: BaseColorTokens.warningDark,
      ColorSemantic.error: BaseColorTokens.errorDark,
      ColorSemantic.info: BaseColorTokens.infoDark,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFF2A2A2A),
      ColorSemantic.primaryContainer: const Color(0xFF3A1F25),
      ColorSemantic.onPrimaryContainer: const Color(0xFFFFB6C1),
      ColorSemantic.onSurface: const Color(0xFFF5F5F5),
      ColorSemantic.onSurfaceVariant: const Color(0xFFBBBBBB),
      ColorSemantic.cardBackground: const Color(0xFF1F1F1F),
      ColorSemantic.cardBorder: const Color(0xFF3A3A3A),
      ColorSemantic.textFieldFill: const Color(0xFF252525),
      ColorSemantic.textFieldHint: const Color(0xFF888888),
      ColorSemantic.buttonBackground: const Color(0xFFFF7B9C),
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: const Color(0xFF0A0506),
      ColorSemantic.messageInputBackground: const Color(0xFF252525),
      ColorSemantic.messageInputBorder: const Color(0xFF3A3A3A),
      ColorSemantic.messageInputText: const Color(0xFFF5F5F5),
      ColorSemantic.messageInputHint: const Color(0xFF888888),
      ColorSemantic.scrollToBottomButton: const Color(0xFFFF7B9C),
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: const Color(0xFFFF7B9C),
    };
  }

  /// 酸菜牛奶主题的亮色映射
  static Map<ColorSemantic, Color> pickleMilkLight() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: BaseColorTokens.pickleUserBubble,
      ColorSemantic.userBubbleBorder: BaseColorTokens.pickleBorder,
      ColorSemantic.userBubbleText: BaseColorTokens.pickleUserText,

      ColorSemantic.aiBubbleBackground: BaseColorTokens.pickleAiBubble,
      ColorSemantic.aiBubbleBorder: BaseColorTokens.pickleBorder,
      ColorSemantic.aiBubbleText: BaseColorTokens.pickleAiText,

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: const Color(0xFF8B5D3A), // 酸菜棕色
      ColorSemantic.secondary: const Color(0xFFD4B996), // 牛奶米色
      ColorSemantic.accent: const Color(0xFF8B5D3A),

      ColorSemantic.background: const Color(0xFFFAF7F2), // 牛奶背景
      ColorSemantic.surface: const Color(0xFFFFFEFB),
      ColorSemantic.surfaceVariant: const Color(0xFFF5F1E8),

      ColorSemantic.textPrimary: const Color(0xFF372B2D), // 酸菜深色
      ColorSemantic.textSecondary: const Color(0xFF6D6359),
      ColorSemantic.textHint: const Color(0xFFA0988F),

      ColorSemantic.border: const Color(0xFFE8DECD), // 酸菜茎色
      ColorSemantic.divider: const Color(0xFFF0ECE1),

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: const Color(0xFF8B5D3A),
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: const Color(0xFFF5F1E8),
      ColorSemantic.buttonSecondaryText: const Color(0xFF372B2D),

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: const Color(0xFFFFFEFB),
      ColorSemantic.appBarText: const Color(0xFF372B2D),
      ColorSemantic.inputBackground: const Color(0xFFFFFEFB),
      ColorSemantic.inputBorder: const Color(0xFFE8DECD),
      ColorSemantic.inputText: const Color(0xFF372B2D),
      ColorSemantic.switchActive: const Color(0xFF8B5D3A),
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successLight,
      ColorSemantic.warning: BaseColorTokens.warningLight,
      ColorSemantic.error: BaseColorTokens.errorLight,
      ColorSemantic.info: BaseColorTokens.infoLight,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFFF5F1E8),
      ColorSemantic.primaryContainer: const Color(0xFFE8DECD),
      ColorSemantic.onPrimaryContainer: const Color(0xFF372B2D),
      ColorSemantic.onSurface: const Color(0xFF372B2D),
      ColorSemantic.onSurfaceVariant: const Color(0xFF6D6359),
      ColorSemantic.cardBackground: const Color(0xFFFFFEFB),
      ColorSemantic.cardBorder: const Color(0xFFE8DECD),
      ColorSemantic.textFieldFill: const Color(0xFFFFFEFB),
      ColorSemantic.textFieldHint: const Color(0xFFA0988F),
      ColorSemantic.buttonBackground: const Color(0xFF8B5D3A),
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: const Color(0xFFFAF7F2),
      ColorSemantic.messageInputBackground: const Color(0xFFFFFEFB),
      ColorSemantic.messageInputBorder: const Color(0xFFE8DECD),
      ColorSemantic.messageInputText: const Color(0xFF372B2D),
      ColorSemantic.messageInputHint: const Color(0xFFA0988F),
      ColorSemantic.scrollToBottomButton: const Color(0xFF8B5D3A),
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: const Color(0xFF8B5D3A),
    };
  }

  /// 酸菜牛奶主题的暗色映射
  static Map<ColorSemantic, Color> pickleMilkDark() {
    return {
      // ========== 气泡颜色 ==========
      ColorSemantic.userBubbleBackground: const Color(0xFF1B3A2A),
      ColorSemantic.userBubbleBorder: const Color(0xFF2D5A40),
      ColorSemantic.userBubbleText: const Color(0xFFC8E6C9),

      ColorSemantic.aiBubbleBackground: const Color(0xFF2D2D2D),
      ColorSemantic.aiBubbleBorder: const Color(0xFF4A4A4A),
      ColorSemantic.aiBubbleText: const Color(0xFFE8F5E9),

      // ========== 应用通用颜色 ==========
      ColorSemantic.primary: const Color(0xFF4CAF50), // 亮酸菜绿
      ColorSemantic.secondary: const Color(0xFF81C784), // 牛奶绿
      ColorSemantic.accent: const Color(0xFF4CAF50),

      ColorSemantic.background: const Color(0xFF121212),
      ColorSemantic.surface: const Color(0xFF1E1E1E),
      ColorSemantic.surfaceVariant: const Color(0xFF2A2A2A),

      ColorSemantic.textPrimary: const Color(0xFFE8F5E9),
      ColorSemantic.textSecondary: const Color(0xFFBDBDBD),
      ColorSemantic.textHint: const Color(0xFF888888),

      ColorSemantic.border: const Color(0xFF4A4A4A),
      ColorSemantic.divider: const Color(0xFF333333),

      // ========== 按钮颜色 ==========
      ColorSemantic.buttonPrimary: const Color(0xFF4CAF50),
      ColorSemantic.buttonPrimaryText: BaseColorTokens.white,
      ColorSemantic.buttonSecondary: const Color(0xFF2A2A2A),
      ColorSemantic.buttonSecondaryText: const Color(0xFFE8F5E9),

      // ========== 组件颜色 ==========
      ColorSemantic.appBarBackground: const Color(0xFF1E1E1E),
      ColorSemantic.appBarText: const Color(0xFFE8F5E9),
      ColorSemantic.inputBackground: const Color(0xFF252525),
      ColorSemantic.inputBorder: const Color(0xFF4A4A4A),
      ColorSemantic.inputText: const Color(0xFFE8F5E9),
      ColorSemantic.switchActive: const Color(0xFF4CAF50),
      ColorSemantic.switchInactive: BaseColorTokens.gray500,

      // ========== 状态颜色 ==========
      ColorSemantic.success: BaseColorTokens.successDark,
      ColorSemantic.warning: BaseColorTokens.warningDark,
      ColorSemantic.error: BaseColorTokens.errorDark,
      ColorSemantic.info: BaseColorTokens.infoDark,

      // ========== Material 3 语义颜色 ==========
      ColorSemantic.surfaceContainerHighest: const Color(0xFF2A2A2A),
      ColorSemantic.primaryContainer: const Color(0xFF1B3A2A),
      ColorSemantic.onPrimaryContainer: const Color(0xFFC8E6C9),
      ColorSemantic.onSurface: const Color(0xFFE8F5E9),
      ColorSemantic.onSurfaceVariant: const Color(0xFFBDBDBD),
      ColorSemantic.cardBackground: const Color(0xFF1E1E1E),
      ColorSemantic.cardBorder: const Color(0xFF4A4A4A),
      ColorSemantic.textFieldFill: const Color(0xFF252525),
      ColorSemantic.textFieldHint: const Color(0xFF888888),
      ColorSemantic.buttonBackground: const Color(0xFF4CAF50),
      ColorSemantic.buttonText: BaseColorTokens.white,
      ColorSemantic.chatRoomBackground: const Color(0xFF121212),
      ColorSemantic.messageInputBackground: const Color(0xFF252525),
      ColorSemantic.messageInputBorder: const Color(0xFF4A4A4A),
      ColorSemantic.messageInputText: const Color(0xFFE8F5E9),
      ColorSemantic.messageInputHint: const Color(0xFF888888),
      ColorSemantic.scrollToBottomButton: const Color(0xFF4CAF50),
      ColorSemantic.scrollToBottomIcon: BaseColorTokens.white,
      ColorSemantic.loadingIndicator: const Color(0xFF4CAF50),
    };
  }

  /// 根据主题类型和亮度获取映射
  static Map<ColorSemantic, Color> getMapping({
    required String themeId,
    required bool isDark,
  }) {
    switch (themeId) {
      case 'strawberryCandy':
        return isDark ? strawberryCandyDark() : strawberryCandyLight();
      case 'pickleMilk':
        return isDark ? pickleMilkDark() : pickleMilkLight();
      default: // 'default'
        return isDark ? defaultDark() : defaultLight();
    }
  }

  /// 获取所有可用的主题映射
  static Map<String, Map<ColorSemantic, Color>> getAllMappings(bool isDark) {
    return {
      'default': isDark ? defaultDark() : defaultLight(),
      'strawberryCandy':
          isDark ? strawberryCandyDark() : strawberryCandyLight(),
      'pickleMilk': isDark ? pickleMilkDark() : pickleMilkLight(),
    };
  }

  /// 验证映射是否完整
  static List<ColorSemantic> validateMapping(
      Map<ColorSemantic, Color> mapping) {
    final missingSemantics = <ColorSemantic>[];

    for (final semantic in ColorSemantic.values) {
      if (!mapping.containsKey(semantic)) {
        missingSemantics.add(semantic);
      }
    }

    return missingSemantics;
  }

  /// 打印映射信息（用于调试）
  static void debugPrintMapping(
    Map<ColorSemantic, Color> mapping, {
    String? themeName,
    bool isDark = false,
  }) {
    debugPrint(
        '=== ${themeName ?? 'Unknown'} Theme (${isDark ? 'Dark' : 'Light'}) ===');

    // 按类别分组打印
    final categories = <String, List<ColorSemantic>>{
      '气泡': [
        ColorSemantic.userBubbleBackground,
        ColorSemantic.userBubbleBorder,
        ColorSemantic.userBubbleText,
        ColorSemantic.aiBubbleBackground,
        ColorSemantic.aiBubbleBorder,
        ColorSemantic.aiBubbleText,
      ],
      '通用': [
        ColorSemantic.primary,
        ColorSemantic.secondary,
        ColorSemantic.accent,
        ColorSemantic.background,
        ColorSemantic.surface,
        ColorSemantic.textPrimary,
        ColorSemantic.textSecondary,
      ],
      '按钮': [
        ColorSemantic.buttonPrimary,
        ColorSemantic.buttonPrimaryText,
        ColorSemantic.buttonSecondary,
        ColorSemantic.buttonSecondaryText,
      ],
      '组件': [
        ColorSemantic.appBarBackground,
        ColorSemantic.appBarText,
        ColorSemantic.inputBackground,
        ColorSemantic.inputText,
        ColorSemantic.switchActive,
      ],
      '状态': [
        ColorSemantic.success,
        ColorSemantic.warning,
        ColorSemantic.error,
        ColorSemantic.info,
      ],
    };

    for (final category in categories.entries) {
      debugPrint('\n--- ${category.key} ---');
      for (final semantic in category.value) {
        final color = mapping[semantic];
        if (color != null) {
          final hex =
              '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
          debugPrint('${semantic.name.padRight(25)}: $hex');
        }
      }
    }
  }

  /// 创建自定义映射（用于图片提取色）
  static Map<ColorSemantic, Color> createCustomMapping({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color textPrimary,
    bool isDark = false,
  }) {
    final baseMapping = isDark ? defaultDark() : defaultLight();

    // 用自定义颜色覆盖
    return {
      ...baseMapping,
      ColorSemantic.primary: primary,
      ColorSemantic.secondary: secondary,
      ColorSemantic.accent: primary,
      ColorSemantic.background: background,
      ColorSemantic.surface: surface,
      ColorSemantic.textPrimary: textPrimary,

      // 气泡颜色也相应调整
      ColorSemantic.userBubbleBackground: primary.withValues(alpha: 0.15),
      ColorSemantic.userBubbleText: textPrimary,
      ColorSemantic.aiBubbleBackground: surface,
      ColorSemantic.aiBubbleText: textPrimary,

      // 按钮颜色
      ColorSemantic.buttonPrimary: primary,
      ColorSemantic.buttonSecondary: secondary,
    };
  }
}
