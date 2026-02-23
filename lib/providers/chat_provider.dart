// lib/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../models/message.dart';
import '../utils/logger.dart';

class ChatCharacter {
  final String name;
  final String? avatarPath;

  ChatCharacter({required this.name, this.avatarPath});

  @override
  String toString() => 'ChatCharacter(name: $name, avatarPath: $avatarPath)';
}

// ── 聊天角色 Notifier ──
class ChatCharacterNotifier extends AsyncNotifier<ChatCharacter> {
  @override
  Future<ChatCharacter> build() async {
    final storage = StorageService();
    final name = await storage.getCharacterNickname();
    final avatarPath = await storage.getCharacterAvatarPath();
    return ChatCharacter(name: name, avatarPath: avatarPath);
  }

  /// 强制重新加载
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

final chatCharacterProvider =
    AsyncNotifierProvider<ChatCharacterNotifier, ChatCharacter>(
  ChatCharacterNotifier.new,
);

// ── 聊天消息 Notifier ──
class ChatMessagesNotifier extends AsyncNotifier<List<Message>> {
  @override
  Future<List<Message>> build() async {
    return await StorageService().loadChatHistory();
  }

  /// 强制重新加载
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider<ChatMessagesNotifier, List<Message>>(
  ChatMessagesNotifier.new,
);

// ── 最后一条消息 ──
final lastMessageProvider = FutureProvider<Message?>((ref) async {
  final messages = ref.watch(chatMessagesProvider).value ?? [];
  return messages.isNotEmpty ? messages.last : null;
});

// ── 未读消息数 ──
final unreadCountProvider = Provider<int>((ref) {
  final messages = ref.watch(chatMessagesProvider).value ?? [];
  final unreadCount = messages.length;
  log.t('计算未读消息计数（临时）: $unreadCount');
  return unreadCount;
});
