// lib/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../models/message.dart';

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

/// 未读消息数量 Provider
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(chatMessagesProvider).value ?? [];
  // 这里可以根据消息的已读状态来统计
  return 0; // 暂时返回0，后续可扩展
});
