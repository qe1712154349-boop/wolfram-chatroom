// lib/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../models/message.dart';
import '../utils/logger.dart'; // ← 加这一行导入（你已有 logger.dart）

/// 聊天角色数据模型
class ChatCharacter {
  final String name;
  final String? avatarPath;

  ChatCharacter({
    required this.name,
    this.avatarPath,
  });

  @override
  String toString() => 'ChatCharacter(name: $name, avatarPath: $avatarPath)';
}

/// 聊天角色数据 Provider
final chatCharacterProvider = FutureProvider<ChatCharacter>((ref) async {
  final storage = StorageService();
  final name = await storage.getCharacterNickname();
  final avatarPath = await storage.getCharacterAvatarPath();

  return ChatCharacter(
    name: name,
    avatarPath: avatarPath,
  );
});

/// 最后一条消息 Provider
final lastMessageProvider = FutureProvider<Message?>((ref) async {
  final messages = await StorageService().loadChatHistory();
  return messages.isNotEmpty ? messages.last : null;
});

/// 所有聊天消息 Provider
final chatMessagesProvider = FutureProvider<List<Message>>((ref) async {
  return await StorageService().loadChatHistory();
});

// 未读消息数量 Provider（临时使用 messages.length 让它被使用，未来换成 !isRead 逻辑）
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(chatMessagesProvider).value ?? [];
  // 这里可以根据消息的已读状态来统计（未来替换）
  final unreadCount = messages.length; // ← 临时用 length（合法使用变量）
  log.t('计算未读消息计数（临时）: $unreadCount'); // ← 改成 t()，trace 级别
  return unreadCount; // 未来改成 where(!m.isRead).length
});
