// lib/services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../models/message.dart';
import 'storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  static const String kDefaultRoomId = StorageService.kDefaultRoomId;

  /// 导出聊天数据
  static Future<ExportResult> exportChat({
    required bool includeCharacter,
    required String characterName,
    String roomId = kDefaultRoomId,
    bool overwrite = false,
    bool shareAfterExport = false, // 【新增】导出后是否立即分享
  }) async {
    try {
      // 请求存储权限（Android 必要）
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return ExportResult(success: false, message: '需要存储权限才能保存文件');
          }
        }
      }

      final storage = StorageService();
      final messages = await storage.loadChatHistory(roomId: roomId);
      if (messages.isEmpty) {
        return ExportResult(success: false, message: '无消息可导出');
      }

      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd_HHmm');
      final timestamp = formatter.format(now);

      final nicknameRaw = await storage.getCharacterNickname();
      final nickname = nicknameRaw.isEmpty ? characterName : nicknameRaw;
      final characterData = includeCharacter
          ? await storage.loadCharacterData()
          : <String, String>{};

      final export = ExportData(
        exportedAt: now.toIso8601String(),
        roomId: roomId,
        nickname: nickname,
        character: characterData,
        messages: messages,
      );

      final jsonString = jsonEncode(export.toJson());
      final type = includeCharacter ? '全部配置' : '聊天记录';
      final baseFileName =
          'lovme_chat_${nickname}_${roomId}_${type}_$timestamp';

      // 公共 Download 目录（用户可见！）
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final lovmeDir = Directory(path.join(downloadDir.path, 'lovme'));
      if (!await lovmeDir.exists()) {
        await lovmeDir.create(recursive: true);
      }

      var filePath = path.join(lovmeDir.path, '$baseFileName.json');
      var file = File(filePath);

      // 防覆盖：序号递增
      int counter = 1;
      while (await file.exists() && !overwrite) {
        filePath = path.join(lovmeDir.path, '${baseFileName}_$counter.json');
        file = File(filePath);
        counter++;
      }

      // 原子写入
      final tempFile = await File(path.join(
              (await getTemporaryDirectory()).path, 'temp_export.json'))
          .writeAsString(jsonString);
      await tempFile.copy(filePath);
      await tempFile.delete();

      if (kDebugMode) {
        print('公共保存成功: $filePath');
        print('大小: ${await file.length()} bytes');
      }

      final result = ExportResult(
        success: true,
        message: '保存到 Download/lovme',
        filePath: filePath,
        file: file,
      );

      // 【新增】如果需要分享，立即调用分享功能
      if (shareAfterExport) {
        await shareExportedFile(file, nickname, type);
      }

      return result;
    } catch (e) {
      debugPrint('导出失败: $e');
      return ExportResult(success: false, message: '导出失败: $e');
    }
  }

  /// 【新增】分享导出的文件
  static Future<void> shareExportedFile(
      File file, String characterName, String type) async {
    try {
      final fileName = file.path.split('/').last;
      final subject = '[$characterName] $type 备份文件';
      final text = '我在 lovme 中备份了与 $characterName 的聊天记录和人设信息。';

      // 使用 share_plus 的 shareXFiles 方法
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: text,
      );
    } catch (e) {
      debugPrint('分享文件失败: $e');
    }
  }

  /// 检查文件是否存在
  static Future<bool> checkFileExists(
      String characterName, bool includeCharacter) async {
    try {
      final type = includeCharacter ? '全部配置' : '聊天记录';
      final fileName = '$characterName-$type.json';
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return false;

      final lovmeDir = Directory(path.join(downloadsDir.path, 'lovme'));
      final filePath = path.join(lovmeDir.path, fileName);
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// 获取保存目录的显示路径（用于显示给用户）
  static Future<String> getDisplayPath() async {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) return '下载目录';

    // 转换路径为可读格式
    String pathStr = downloadsDir.path;

    // 如果是Android，转换为用户友好的路径
    if (pathStr.contains('/storage/emulated/0/')) {
      pathStr = pathStr.replaceAll('/storage/emulated/0/', '/sdcard/');
    }

    return path.join(pathStr, 'lovme');
  }
}

/// 导出结果类
class ExportResult {
  final bool success;
  final String message;
  final String? filePath;
  final bool fileExists;
  final File? file;

  ExportResult({
    required this.success,
    required this.message,
    this.filePath,
    this.fileExists = false,
    this.file,
  });
}
