/// color_semantics.dart
/// 添加必要的导入
library;

import 'package:flutter/material.dart';

/// 颜色语义枚举 - 定义颜色的用途而不是具体值
/// 这样我们可以灵活地为主题分配不同的颜色值
enum ColorSemantic {
  // ========== 气泡相关 ==========
  userBubbleBackground, // 用户气泡背景色
  userBubbleBorder, // 用户气泡边框色
  userBubbleText, // 用户气泡文字色

  aiBubbleBackground, // AI气泡背景色
  aiBubbleBorder, // AI气泡边框色
  aiBubbleText, // AI气泡文字色

  // ========== 应用通用 ==========
  primary, // 主色（按钮、选中状态等）
  secondary, // 辅色
  accent, // 强调色（图标、高亮等）

  background, // 页面背景色
  surface, // 表面色（卡片、对话框背景）
  surfaceVariant, // 表面变体色（列表项等）

  textPrimary, // 主要文字色
  textSecondary, // 次要文字色
  textHint, // 提示文字色

  border, // 通用边框色
  divider, // 分割线颜色

  // ========== 组件特定 ==========
  buttonPrimary, // 主要按钮背景
  buttonPrimaryText, // 主要按钮文字
  buttonSecondary, // 次要按钮背景
  buttonSecondaryText, // 次要按钮文字

  appBarBackground, // 应用栏背景
  appBarText, // 应用栏文字

  inputBackground, // 输入框背景
  inputBorder, // 输入框边框
  inputText, // 输入框文字

  switchActive, // Switch开启状态
  switchInactive, // Switch关闭状态

  success, // 成功色
  warning, // 警告色
  error, // 错误色
  info, // 信息色
// 新增（解决 undefined_enum_constant，覆盖 Material 3 常见语义）
  surfaceContainerHighest,
  primaryContainer,
  onPrimaryContainer,
  onSurface,
  onSurfaceVariant,
  cardBackground, // 编辑页卡片背景
  cardBorder, // 编辑页卡片边框
  textFieldFill, // 输入框填充色
  textFieldHint, // 输入框提示文字
  buttonBackground, // 保存按钮背景
  buttonText, // 保存按钮文字

  // 新增（聊天室专用，确保覆盖所有使用场景）
  chatRoomBackground, // 聊天室整体背景（原 scaffoldBackgroundColor）
  messageInputBackground, // 输入框背景
  messageInputBorder, // 输入框边框
  messageInputText, // 输入框文字
  messageInputHint, // 输入框提示文字
  scrollToBottomButton, // 滚动到底部按钮背景
  scrollToBottomIcon, // 滚动到底部图标
  loadingIndicator, // 正在输入... 指示器
}

/// 图片提取的颜色语义 - 从图片中提取的5个主要颜色
enum ExtractedColorType {
  dominant, // 主导色（图片中最多的颜色）→ 用于background
  vibrant, // 鲜艳色（图片中最鲜艳的颜色）→ 用于primary/accent
  lightVibrant, // 亮鲜艳色 → 用于surface
  darkVibrant, // 暗鲜艳色 → 用于surfaceVariant
  muted, // 柔和色 → 用于secondary
}

/// 颜色语义映射 - 将图片提取的颜色映射到应用语义
class ExtractedColorMapper {
  /// 将提取的5个颜色映射到完整的颜色语义表
  static Map<ColorSemantic, Color> mapToSemantics(
    Map<ExtractedColorType, Color> extractedColors,
  ) {
    return {
      // 气泡颜色使用鲜艳色和主导色
      ColorSemantic.userBubbleBackground:
          extractedColors[ExtractedColorType.vibrant]!,
      ColorSemantic.userBubbleText:
          _getContrastColor(extractedColors[ExtractedColorType.vibrant]!),
      ColorSemantic.aiBubbleBackground:
          extractedColors[ExtractedColorType.lightVibrant]!,
      ColorSemantic.aiBubbleText:
          _getContrastColor(extractedColors[ExtractedColorType.lightVibrant]!),

      // 应用通用颜色
      ColorSemantic.primary: extractedColors[ExtractedColorType.vibrant]!,
      ColorSemantic.secondary: extractedColors[ExtractedColorType.muted]!,
      ColorSemantic.accent: extractedColors[ExtractedColorType.vibrant]!,
      ColorSemantic.background: extractedColors[ExtractedColorType.dominant]!,
      ColorSemantic.surface: extractedColors[ExtractedColorType.lightVibrant]!,
      ColorSemantic.surfaceVariant:
          extractedColors[ExtractedColorType.darkVibrant]!,

      // 文字颜色根据背景色计算对比度
      ColorSemantic.textPrimary:
          _getContrastColor(extractedColors[ExtractedColorType.dominant]!),
      ColorSemantic.textSecondary: _getContrastColor(
          extractedColors[ExtractedColorType.dominant]!,
          lighter: true),

      // 边框和分割线使用柔和色
      ColorSemantic.border:
          extractedColors[ExtractedColorType.muted]!.withOpacity(0.3),
      ColorSemantic.divider:
          extractedColors[ExtractedColorType.muted]!.withOpacity(0.2),

      // 按钮颜色
      ColorSemantic.buttonPrimary: extractedColors[ExtractedColorType.vibrant]!,
      ColorSemantic.buttonPrimaryText: Colors.white,
      ColorSemantic.buttonSecondary: extractedColors[ExtractedColorType.muted]!,
      ColorSemantic.buttonSecondaryText:
          _getContrastColor(extractedColors[ExtractedColorType.muted]!),

      // 组件颜色
      ColorSemantic.appBarBackground:
          extractedColors[ExtractedColorType.dominant]!,
      ColorSemantic.appBarText:
          _getContrastColor(extractedColors[ExtractedColorType.dominant]!),
      ColorSemantic.inputBackground:
          extractedColors[ExtractedColorType.lightVibrant]!,
      ColorSemantic.inputText:
          _getContrastColor(extractedColors[ExtractedColorType.lightVibrant]!),

      // 状态颜色（保持固定，不受图片影响）
      ColorSemantic.success: const Color(0xFF4CAF50),
      ColorSemantic.warning: const Color(0xFFFF9800),
      ColorSemantic.error: const Color(0xFFF44336),
      ColorSemantic.info: const Color(0xFF2196F3),
    };
  }

  /// 获取对比色（黑或白）
  static Color _getContrastColor(Color background, {bool lighter = false}) {
    // 计算亮度
    final luminance = background.computeLuminance();

    if (lighter) {
      // 返回更浅的颜色
      return luminance > 0.5
          ? Colors.black.withOpacity(0.6)
          : Colors.white.withOpacity(0.8);
    }

    // 返回高对比度颜色
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// 扩展方法：方便地获取颜色名称
extension ColorSemanticName on ColorSemantic {
  String get name {
    switch (this) {
      case ColorSemantic.userBubbleBackground:
        return '用户气泡背景';
      case ColorSemantic.userBubbleBorder:
        return '用户气泡边框';
      case ColorSemantic.userBubbleText:
        return '用户气泡文字';
      case ColorSemantic.aiBubbleBackground:
        return 'AI气泡背景';
      case ColorSemantic.aiBubbleBorder:
        return 'AI气泡边框';
      case ColorSemantic.aiBubbleText:
        return 'AI气泡文字';
      case ColorSemantic.primary:
        return '主色';
      case ColorSemantic.secondary:
        return '辅色';
      case ColorSemantic.accent:
        return '强调色';
      case ColorSemantic.background:
        return '背景色';
      case ColorSemantic.surface:
        return '表面色';
      case ColorSemantic.surfaceVariant:
        return '表面变体';
      case ColorSemantic.textPrimary:
        return '主要文字';
      case ColorSemantic.textSecondary:
        return '次要文字';
      case ColorSemantic.textHint:
        return '提示文字';
      case ColorSemantic.border:
        return '边框色';
      case ColorSemantic.divider:
        return '分割线';
      case ColorSemantic.buttonPrimary:
        return '主要按钮';
      case ColorSemantic.buttonPrimaryText:
        return '主要按钮文字';
      case ColorSemantic.buttonSecondary:
        return '次要按钮';
      case ColorSemantic.buttonSecondaryText:
        return '次要按钮文字';
      case ColorSemantic.appBarBackground:
        return '应用栏背景';
      case ColorSemantic.appBarText:
        return '应用栏文字';
      case ColorSemantic.inputBackground:
        return '输入框背景';
      case ColorSemantic.inputBorder:
        return '输入框边框';
      case ColorSemantic.inputText:
        return '输入框文字';
      case ColorSemantic.switchActive:
        return 'Switch开启';
      case ColorSemantic.switchInactive:
        return 'Switch关闭';
      case ColorSemantic.success:
        return '成功色';
      case ColorSemantic.warning:
        return '警告色';
      case ColorSemantic.error:
        return '错误色';
      case ColorSemantic.info:
        return '信息色';

      // 新增（补全你加的所有语义常量）
      case ColorSemantic.surfaceContainerHighest:
        return '高亮表面容器';
      case ColorSemantic.primaryContainer:
        return '主色容器';
      case ColorSemantic.onPrimaryContainer:
        return '主色容器上的文字';
      case ColorSemantic.onSurface:
        return '表面上的文字';
      case ColorSemantic.onSurfaceVariant:
        return '表面变体上的文字';
      case ColorSemantic.chatRoomBackground:
        return '聊天室整体背景';
      case ColorSemantic.messageInputBackground:
        return '消息输入框背景';
      case ColorSemantic.messageInputBorder:
        return '消息输入框边框';
      case ColorSemantic.messageInputText:
        return '消息输入框文字';
      case ColorSemantic.messageInputHint:
        return '消息输入框提示文字';
      case ColorSemantic.scrollToBottomButton:
        return '滚动到底部按钮背景';
      case ColorSemantic.scrollToBottomIcon:
        return '滚动到底部图标';
      case ColorSemantic.loadingIndicator:
        return '加载/正在输入指示器';

      // 兜底（防止未来加新枚举值时忘记补 case）
      default:
        return name.toString().split('.').last; // 自动转成驼峰名
    }
  }

  /// 获取颜色描述（也补全，避免未来扩展时漏）
  String get description {
    switch (this) {
      case ColorSemantic.userBubbleBackground:
        return '用户发送消息的气泡背景颜色';
      case ColorSemantic.userBubbleText:
        return '用户发送消息的文字颜色';
      case ColorSemantic.aiBubbleBackground:
        return 'AI回复消息的气泡背景颜色';
      case ColorSemantic.aiBubbleText:
        return 'AI回复消息的文字颜色';
      case ColorSemantic.primary:
        return '应用的主要品牌色，用于重要操作和焦点状态';
      case ColorSemantic.background:
        return '页面的背景颜色';

      // 新增描述
      case ColorSemantic.surfaceContainerHighest:
        return '高亮表面容器，用于卡片/对话框等';
      case ColorSemantic.primaryContainer:
        return '主色容器，用于强调区域背景';
      case ColorSemantic.onPrimaryContainer:
        return '主色容器上的文字/图标';
      case ColorSemantic.onSurface:
        return '表面上的主要文字';
      case ColorSemantic.onSurfaceVariant:
        return '表面上的次要文字/变体';
      case ColorSemantic.chatRoomBackground:
        return '聊天室整体背景色';
      case ColorSemantic.messageInputBackground:
        return '消息输入框背景色';
      case ColorSemantic.messageInputBorder:
        return '消息输入框边框色';
      case ColorSemantic.messageInputText:
        return '消息输入框文字色';
      case ColorSemantic.messageInputHint:
        return '消息输入框提示文字色';
      case ColorSemantic.scrollToBottomButton:
        return '滚动到底部按钮背景色';
      case ColorSemantic.scrollToBottomIcon:
        return '滚动到底部图标色';
      case ColorSemantic.loadingIndicator:
        return '加载/正在输入指示器颜色';

      default:
        return '颜色语义：$name';
    }
  }
}
