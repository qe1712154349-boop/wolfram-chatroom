// 修改后的 lib/pages/chat/chat_components.dart
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
              color: Colors.white,
              border: Border.all(
                color: AppTheme.aiBubbleBorder,
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
                      color: AppTheme.withOpacity(AppTheme.pinkAccent, 0.7),
                    )
                  : null,
            ),
          ),
          // AI气泡 - 纯色无阴影，带细边框
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
                color: AppTheme.aiBubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomRight: Radius.circular(AppTheme.bubbleBorderRadius),
                ),
                border: Border.all(
                  color: AppTheme.aiBubbleBorder,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: AppTheme.dialogueStyle,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 用户气泡 - 纯色无阴影，带细边框
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
                color: AppTheme.userBubbleColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(AppTheme.bubbleBorderRadius),
                  bottomRight: Radius.circular(AppTheme.bubbleBorderRadius),
                ),
                border: Border.all(
                  color: AppTheme.userBubbleBorder,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: AppTheme.dialogueStyle.copyWith(
                  color: AppTheme.userTextColor, // 添加用户文字颜色
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
                color: Colors.white,
                border: Border.all(
                  color: AppTheme.userBubbleBorder,
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
                        color: AppTheme.withOpacity(AppTheme.pinkAccent, 0.7),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: AppTheme.systemTimeStyle,
          ),
        ),
      ),
    );
  }
}

// 旁白消息组件
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Center(  // 关键：用 Center 包裹 Align
        child: Align(
          alignment: isCentered ? Alignment.center : Alignment.centerLeft,
          child: Container(
            margin: isCentered
                ? const EdgeInsets.symmetric(horizontal: 0)
                : const EdgeInsets.only(left: 32.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFD1DC),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: isCentered ? TextAlign.center : TextAlign.left,
              style: AppTheme.narrationStyle.copyWith(
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}