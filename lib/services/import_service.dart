// lib/services/import_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'storage_service.dart';

class ImportData {
  final String version;
  final String exportedAt;
  final String roomId;
  final String nickname;
  final Map<String, String> character;
  final List<dynamic> messagesJson;

  ImportData({
    required this.version,
    required this.exportedAt,
    required this.roomId,
    required this.nickname,
    required this.character,
    required this.messagesJson,
  });

  factory ImportData.fromJson(Map<String, dynamic> json) {
    return ImportData(
      version: json['version'] as String? ?? '1.0',
      exportedAt: json['exported_at'] as String? ?? '',
      roomId: json['room_id'] as String? ?? StorageService.kDefaultRoomId,
      nickname: json['nickname'] as String? ?? '未命名角色',
      character: Map<String, String>.from(
        (json['character'] as Map<dynamic, dynamic>?) ?? {},
      ),
      messagesJson: (json['messages'] as List<dynamic>?) ?? [],
    );
  }

  /// 验证导入数据的合法性
  ImportValidationResult validate() {
    // 检查版本
    if (version.isEmpty) {
      return ImportValidationResult(
        isValid: false,
        errorMessage: '文件版本信息缺失',
      );
    }

    // 检查必要字段
    if (nickname.isEmpty) {
      return ImportValidationResult(
        isValid: false,
        errorMessage: '人设名称缺失',
      );
    }

    // 检查消息数据
    if (messagesJson.isEmpty) {
      return ImportValidationResult(
        isValid: false,
        errorMessage: '没有聊天记录可导入',
      );
    }

    // 验证消息格式
    for (var i = 0; i < messagesJson.length; i++) {
      final msg = messagesJson[i];
      if (msg is! Map<String, dynamic>) {
        return ImportValidationResult(
          isValid: false,
          errorMessage: '第 ${i + 1} 条消息格式错误',
        );
      }

      // 检查消息必要字段
      if (!msg.containsKey('id') ||
          !msg.containsKey('role') ||
          !msg.containsKey('timestamp')) {
        return ImportValidationResult(
          isValid: false,
          errorMessage: '第 ${i + 1} 条消息缺少必要字段',
        );
      }
    }

    return ImportValidationResult(isValid: true);
  }
}

class ImportValidationResult {
  final bool isValid;
  final String? errorMessage;

  ImportValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

class ImportPreview {
  final String characterName;
  final int messageCount;
  final String exportedAt;
  final Map<String, String> characterData;

  ImportPreview({
    required this.characterName,
    required this.messageCount,
    required this.exportedAt,
    required this.characterData,
  });
}

class ImportResult {
  final bool success;
  final String message;
  final ImportPreview? preview;

  ImportResult({
    required this.success,
    required this.message,
    this.preview,
  });
}

class ImportService {
  static const String kDefaultRoomId = StorageService.kDefaultRoomId;

  /// 从文件读取 JSON 数据
  static Future<ImportData?> readJsonFile(File file) async {
    try {
      if (!file.path.endsWith('.json')) {
        return null;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return ImportData.fromJson(json);
    } catch (e) {
      debugPrint('读取文件失败: $e');
      return null;
    }
  }

  /// 获取导入预览（不实际导入，只预览数据）
  static Future<ImportResult> getImportPreview(File file) async {
    try {
      final importData = await readJsonFile(file);

      if (importData == null) {
        return ImportResult(
          success: false,
          message: '无法读取文件，请确保是有效的 JSON 格式',
        );
      }

      // 验证数据合法性
      final validation = importData.validate();
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          message: '文件格式错误: ${validation.errorMessage}',
        );
      }

      final preview = ImportPreview(
        characterName: importData.nickname,
        messageCount: importData.messagesJson.length,
        exportedAt: importData.exportedAt,
        characterData: importData.character,
      );

      return ImportResult(
        success: true,
        message: '文件验证成功',
        preview: preview,
      );
    } catch (e) {
      debugPrint('预览导入失败: $e');
      return ImportResult(
        success: false,
        message: '预览失败: $e',
      );
    }
  }

  /// 执行实际导入（覆盖现有数据）
  static Future<ImportResult> executeImport(
    File file, {
    String roomId = kDefaultRoomId,
  }) async {
    try {
      final importData = await readJsonFile(file);

      if (importData == null) {
        return ImportResult(
          success: false,
          message: '无法读取文件',
        );
      }

      // 再次验证
      final validation = importData.validate();
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          message: '文件格式错误: ${validation.errorMessage}',
        );
      }

      final storage = StorageService();

      // 1. 导入人设信息
      if (importData.character.isNotEmpty) {
        await storage.saveCharacterData(importData.character);
        debugPrint('✅ 人设信息已导入');
      }

      // 2. 导入聊天记录
      final messages = <Message>[];
      for (var msgJson in importData.messagesJson) {
        try {
          final msg = Message.fromMap(msgJson as Map<String, dynamic>);
          messages.add(msg);
        } catch (e) {
          debugPrint('转换消息失败: $e');
          continue; // 跳过单条消息，继续导入其他
        }
      }

      if (messages.isNotEmpty) {
        await storage.saveChatHistory(
          messages,
          roomId: roomId,
        );
        debugPrint('✅ 聊天记录已导入，共 ${messages.length} 条');
      }

      return ImportResult(
        success: true,
        message: '导入成功！人设和 ${messages.length} 条聊天记录已恢复',
        preview: ImportPreview(
          characterName: importData.nickname,
          messageCount: messages.length,
          exportedAt: importData.exportedAt,
          characterData: importData.character,
        ),
      );
    } catch (e) {
      debugPrint('导入失败: $e');
      return ImportResult(
        success: false,
        message: '导入过程中出错: $e',
      );
    }
  }
}
