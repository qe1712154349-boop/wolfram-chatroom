// lib/pages/chat/chat_components.dart - 完整替换
import 'package:flutter/material.dart';
import 'dart:io';
import '../../app/theme.dart'; // 导入主题

class ReceivedMessage extends StatelessWidget {
  final String text;
  final String? avatarPath;

  const ReceivedMessage({
    super.key,
    required this.text,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF333333) : AppTheme.aiBubbleBorderLight,
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              backgroundImage: avatarPath != null
                  ? FileImage(File(avatarPath!))
                  : null,
              child: avatarPath == null
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: isDark ? const Color(0xFFF95685) : AppTheme.pinkAccent,
                    )
                  : null,
            ),
          ),
          // AI气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 40,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : AppTheme.aiBubbleColorLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomRight: Radius.circular(AppTheme.bubbleBorderRadius),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : AppTheme.aiBubbleBorderLight,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : AppTheme.primaryTextLight,
                  height: 1.4,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SentMessage extends StatelessWidget {
  final String text;
  final String? userAvatarPath;
  final bool showUserAvatar;

  const SentMessage({
    super.key,
    required this.text,
    this.userAvatarPath,
    this.showUserAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 用户气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: 40,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFF95685) : AppTheme.userBubbleColorLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomRight: Radius.circular(AppTheme.bubbleBorderRadius),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFFD6406E) : AppTheme.userBubbleBorderLight,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : AppTheme.userTextColorLight,
                  height: 1.4,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 用户头像（根据设置显示或隐藏）
          if (showUserAvatar)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : AppTheme.userBubbleBorderLight,
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: userAvatarPath != null
                    ? FileImage(File(userAvatarPath!))
                    : null,
                child: userAvatarPath == null
                    ? Icon(
                        Icons.person_outline,
                        size: 18,
                        color: isDark ? const Color(0xFFF95685) : AppTheme.pinkAccent,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class SystemTimeMessage extends StatelessWidget {
  final String text;

  const SystemTimeMessage({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : AppTheme.secondaryTextLight,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class NarrationMessage extends StatelessWidget {
  final String text;
  final bool isAI;
  final bool isCentered;

  const NarrationMessage({
    super.key,
    required this.text,
    this.isAI = false,
    this.isCentered = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      child: Align(
        alignment: isCentered 
            ? Alignment.center 
            : (isAI ? Alignment.centerLeft : Alignment.centerRight),
        child: Container(
          margin: isCentered 
              ? null 
              : (isAI 
                  ? const EdgeInsets.only(left: 12)    // AI 左对齐时留左边距
                  : const EdgeInsets.only(right: 22)), // 用户右对齐时留右边距
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAI
                ? (isDark ? const Color(0xFF2A1A1F) : Colors.pink[50])  // 暗色模式下的粉色背景
                : (isDark ? const Color(0xFF252525) : Colors.grey[200]), // 暗色模式下的灰色背景
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAI 
                  ? (isDark ? const Color(0xFFD6406E) : Colors.pink[200]!) 
                  : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
              width: 1,
            ),
          ),
          child: Text(
            text.trim(),
            style: TextStyle(
              fontSize: 13,
              color: isAI 
                  ? (isDark ? Colors.pink[200] : Colors.pink[800])
                  : (isDark ? Colors.grey[300] : AppTheme.narrationTextLight),
              fontStyle: FontStyle.italic,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}