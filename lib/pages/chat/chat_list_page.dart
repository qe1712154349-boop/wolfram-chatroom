// lib/pages/chat/chat_list_page.dart - 完整迁移到新主题系统
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'chat_room_page.dart';
import 'chat_character_edit_page.dart';
import '../../providers/chat_provider.dart';
import '../../theme/theme.dart' as app_theme;

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(chatCharacterProvider);
    final lastMsgAsync = ref.watch(lastMessageProvider);

    return Scaffold(
      backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        elevation: 0,
        title: Text(
          "聊天",
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.appBarText),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Icon(
            Icons.search,
            color: context.themeColor(app_theme.ColorSemantic.primary),
          ),
        ],
      ),
      body: characterAsync.when(
        data: (character) => ListView(
          children: [
            ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatRoomPage()),
              ).then((_) {
                ref.invalidate(chatCharacterProvider);
                ref.invalidate(lastMessageProvider);
                ref.invalidate(chatMessagesProvider);
              }),
              leading: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChatCharacterEditPage()),
                ).then((_) {
                  ref.invalidate(chatCharacterProvider);
                }),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: context
                      .themeColor(app_theme.ColorSemantic.primaryContainer),
                  backgroundImage: character.avatarPath != null
                      ? FileImage(File(character.avatarPath!))
                      : null,
                  child: character.avatarPath == null
                      ? Icon(
                          Icons.person,
                          color: context.themeColor(
                              app_theme.ColorSemantic.onPrimaryContainer),
                          size: 32,
                        )
                      : null,
                ),
              ),
              title: Text(
                character.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color:
                      context.themeColor(app_theme.ColorSemantic.textPrimary),
                ),
              ),
              subtitle: lastMsgAsync.when(
                data: (msg) => msg != null && msg.displayContent.isNotEmpty
                    ? Text(
                        msg.displayContent.length > 30
                            ? '${msg.displayContent.substring(0, 30)}...'
                            : msg.displayContent,
                        style: TextStyle(
                          color: context.themeColor(
                              app_theme.ColorSemantic.textSecondary),
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              trailing: lastMsgAsync.when(
                data: (msg) => msg != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg.timestamp,
                            style: TextStyle(
                              color: context.themeColor(
                                  app_theme.ColorSemantic.textSecondary),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: context
                                .themeColor(app_theme.ColorSemantic.primary),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            Divider(
              height: 1,
              indent: 80,
              color: context.themeColor(app_theme.ColorSemantic.divider),
            ),
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '加载失败',
                style: TextStyle(
                  color: context.themeColor(app_theme.ColorSemantic.error),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(chatCharacterProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      context.themeColor(app_theme.ColorSemantic.buttonPrimary),
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
