// lib/services/export_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/message.dart';
import 'storage_service.dart';

class ExportData {
  final String version = '1.0';
  final String exportedAt;
  final String roomId;
  final String nickname;
  final Map<String, String> character;
  final List<Message> messages;

  ExportData({
    required this.exportedAt,
    required this.roomId,
    required this.nickname,
    required this.character,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exported_at': exportedAt,
        'room_id': roomId,
        'nickname': nickname,
        'character': character,
        'messages': messages.map((m) => m.toMap()).toList(),
      };
}

class ExportService {
  static Future<void> exportChat({
    required bool includeCharacter,
    required String characterName,
  }) async {
    final storage = StorageService();
    final messages = await storage.loadChatHistory();
    if (messages.isEmpty) {
      // 可加 toast
      debugPrint('无消息可导出');
      return;
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmm');
    final timestamp = formatter.format(now);

    final nickname = await storage.getCharacterNickname();
    final characterData = includeCharacter ? await storage.loadCharacterData() : <String, String>{};

    final export = ExportData(
      exportedAt: now.toIso8601String(),
      roomId: 'master', // 未来替换为 UUID
      nickname: nickname.isEmpty ? characterName : nickname,
      character: characterData,
      messages: messages,
    );

    final jsonString = jsonEncode(export.toJson());
    final fileName = includeCharacter
        ? 'wolf_chat_${nickname}_full_$timestamp.json'
        : 'wolf_chat_${nickname}_messages_$timestamp.json';

    // 分享（系统面板）
    await Share.shareXFiles(
      [XFile.fromData(utf8.encode(jsonString), name: fileName, mimeType: 'application/json')],
      text: includeCharacter ? '完整聊天备份（人设+消息）' : '仅聊天记录备份',
      subject: fileName,
    );
  }
}