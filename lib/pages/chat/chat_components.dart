// lib/pages/chat/chat_components.dart - 完整修复版（Material 3 规范 + 动态主题响应）
import 'package:flutter/material.dart';
import 'dart:io';
// 添加这行导入
import '../../theme/extensions/context_extensions.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
              color: cs.surfaceContainerHighest,
              border: Border.all(
                color: cs.outline.withAlpha(77), // 0.3 透明
                width: 1,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              backgroundImage:
                  avatarPath != null ? FileImage(File(avatarPath!)) : null,
              child: avatarPath == null
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: cs.primary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: cs.outline.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: cs.outline.withAlpha(77),
                  width: 1,
                ),
              ),
              child: Text(
                text,
// 修改后：
                style: TextStyle(
                  fontSize: 16,
                  color: context.userBubbleText, // ← 使用新系统
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
                color: cs.surfaceContainerHighest,
                border: Border.all(
                  color: cs.outline.withAlpha(77),
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
                        color: cs.primary,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: context.aiBubbleBackground, // ← 使用新系统
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  ? const EdgeInsets.only(left: 12)
                  : const EdgeInsets.only(right: 22)),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAI ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outline.withAlpha(77),
              width: 1,
            ),
          ),
          child: Text(
            text.trim(),
            style: TextStyle(
              fontSize: 13,
              color: isAI ? cs.onPrimaryContainer : cs.onSurfaceVariant,
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
