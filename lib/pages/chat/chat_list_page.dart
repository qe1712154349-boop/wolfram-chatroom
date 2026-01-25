// lib/pages/chat/chat_list_page.dart - 完整 Riverpod 版本
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'chat_room_page.dart';
import 'chat_character_edit_page.dart';
import '../../services/storage_service.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(chatCharacterProvider);
    final lastMsgAsync = ref.watch(lastMessageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        elevation: 0,
        title: Text(
          "聊天",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF4A4A4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Icon(Icons.search, color: Theme.of(context).primaryColor),
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
                // 返回时刷新数据
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
                  // 返回时刷新角色数据
                  ref.invalidate(chatCharacterProvider);
                }),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: character.avatarPath != null
                      ? FileImage(File(character.avatarPath!))
                      : null,
                  child: character.avatarPath == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
              ),
              title: Text(
                character.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: lastMsgAsync.when(
                data: (msg) => msg != null && msg.displayContent.isNotEmpty
                    ? Text(
                        msg.displayContent.length > 30
                            ? '${msg.displayContent.substring(0, 30)}...'
                            : msg.displayContent,
                        style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey),
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
                              color: isDark ? Colors.grey[400] : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: Theme.of(context).primaryColor,
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
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ],
        ),
        loading: () => const SizedBox.shrink(), // 因预热，几乎不会显示
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '加载失败',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(chatCharacterProvider);
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
