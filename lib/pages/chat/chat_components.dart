// lib/pages/chat/chat_components.dart - 完整迁移到新主题系统
import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/theme.dart' as app_theme;

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
              color: context
                  .themeColor(app_theme.ColorSemantic.surfaceContainerHighest),
              border: Border.all(
                color: context
                    .themeColor(app_theme.ColorSemantic.border)
                    .withValues(alpha: 0.3),
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
                      color:
                          context.themeColor(app_theme.ColorSemantic.primary),
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
                color: context.aiBubbleBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: context.aiBubbleBorder,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: context.aiBubbleText,
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
                color: context.userBubbleBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: context.userBubbleBorder,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: context.userBubbleText,
                  height: 1.4,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 用户头像
          if (showUserAvatar)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.themeColor(
                    app_theme.ColorSemantic.surfaceContainerHighest),
                border: Border.all(
                  color: context
                      .themeColor(app_theme.ColorSemantic.border)
                      .withValues(alpha: 0.3),
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
                        color:
                            context.themeColor(app_theme.ColorSemantic.primary),
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
            color: context
                .themeColor(app_theme.ColorSemantic.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: context.themeColor(app_theme.ColorSemantic.textSecondary),
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
            color: isAI
                ? context.themeColor(app_theme.ColorSemantic.primaryContainer)
                : context.themeColor(
                    app_theme.ColorSemantic.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context
                  .themeColor(app_theme.ColorSemantic.border)
                  .withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            text.trim(),
            style: TextStyle(
              fontSize: 13,
              color: isAI
                  ? context
                      .themeColor(app_theme.ColorSemantic.onPrimaryContainer)
                  : context.themeColor(app_theme.ColorSemantic.textSecondary),
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
