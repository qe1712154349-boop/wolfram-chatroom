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
  // 链接 storage 的默认 roomId（保持一致）
  static const String kDefaultRoomId = StorageService.kDefaultRoomId;

  static Future<void> exportChat({
    required bool includeCharacter,
    required String characterName,
    String roomId = kDefaultRoomId,  // 动态，默认 'default'
  }) async {
    final storage = StorageService();
    final messages = await storage.loadChatHistory(roomId: roomId);  // 确保这个方法支持roomId参数
    if (messages.isEmpty) {
      debugPrint('无消息可导出 (room: $roomId)');
      return;
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HHmm');  // 精确匹配你想要的格式
    final timestamp = formatter.format(now);

    final nickname = await storage.getCharacterNickname();
    final characterData = includeCharacter ? await storage.loadCharacterData() : <String, String>{};

    final export = ExportData(
      exportedAt: now.toIso8601String(),
      roomId: roomId,  // 动态 'default'，无 master
      nickname: nickname.isEmpty ? characterName : nickname,
      character: characterData,
      messages: messages,
    );

    final jsonString = jsonEncode(export.toJson());
    final type = includeCharacter ? 'full' : 'messages';
    final fileName = 'lovme_chat_${nickname}_${roomId}_${type}_$timestamp.json';  // 修复：使用正确的变量名

    // 当前分享逻辑（后续可改成本地保存）
    await Share.shareXFiles(
      [XFile.fromData(utf8.encode(jsonString), name: fileName, mimeType: 'application/json')],
      text: includeCharacter ? '完整聊天备份（人设+消息）' : '仅聊天记录备份',
      subject: fileName,
    );

    if (kDebugMode) print('导出完成: $fileName (room: $roomId, msgs: ${messages.length})');
  }
}