// lib/pages/chat/chat_backup_migrate_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/export_service.dart';
import '../../services/storage_service.dart';
import '../../theme/theme.dart' as app_theme;

class ChatBackupMigratePage extends StatefulWidget {
  final String characterName;

  const ChatBackupMigratePage({
    super.key,
    required this.characterName,
  });

  @override
  State<ChatBackupMigratePage> createState() => _ChatBackupMigratePageState();
}

class _ChatBackupMigratePageState extends State<ChatBackupMigratePage> {
  @override
  Widget build(BuildContext context) {
    final sem = context.sem;

    return Scaffold(
      backgroundColor: sem.background,
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: sem.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '聊天记录迁移与备份',
          style: TextStyle(
            color: sem.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 导出卡片
          GestureDetector(
            onTap: () => _showExportOptions(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: sem.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: sem.primary.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sem.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_upload_rounded,
                      color: sem.primary, size: 28),
                ),
                title: Text(
                  '导出全部配置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sem.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '人设 + 聊天记录 + 头像引用（.json）',
                  style: TextStyle(
                    fontSize: 13,
                    color: sem.textSecondary,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: sem.textSecondary),
              ),
            ),
          ),

          // 导入卡片（置灰）
          Opacity(
            opacity: 0.55,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: sem.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: sem.border.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sem.textSecondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_download_rounded,
                      color: sem.textSecondary, size: 28),
                ),
                title: Text(
                  '导入配置（开发中）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sem.textSecondary,
                  ),
                ),
                subtitle: Text(
                  '从备份文件恢复人设与聊天记录',
                  style: TextStyle(fontSize: 13, color: sem.textHint),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: sem.textSecondary),
              ),
            ),
          ),

          // 底部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sem.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: sem.border.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '关于备份',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sem.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 文件保存在 Download/lovme 文件夹\n'
                  '• 同名文件将提示覆盖确认\n'
                  '• 可在手机文件管理器中查看\n'
                  '• 支持换机恢复、防止数据丢失',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: sem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          '导出选项',
          style: TextStyle(fontSize: 16),
        ),
        message: const Text(
          '请选择要导出的内容',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _startExport(context, includeCharacter: true),
            child: const Text(
              '导出全部配置（人设+消息）',
              style: TextStyle(fontSize: 16),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _startExport(context, includeCharacter: false),
            child: const Text(
              '仅导出聊天记录',
              style: TextStyle(fontSize: 16),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startExport(BuildContext context,
      {required bool includeCharacter}) async {
    Navigator.pop(context);

    final fileExists = await ExportService.checkFileExists(
      widget.characterName,
      includeCharacter,
    );

    if (fileExists) {
      final type = includeCharacter ? '全部配置' : '聊天记录';
      final fileName = '${widget.characterName}-$type.json';

      if (!context.mounted) return;

      final shouldOverwrite = await _showOverwriteDialog(context, fileName);

      if (!context.mounted) return;

      if (!shouldOverwrite) return;

      if (!context.mounted) return;
      await _performExport(
        context,
        includeCharacter: includeCharacter,
        overwrite: true,
      );
    } else {
      if (!context.mounted) return;
      await _performExport(
        context,
        includeCharacter: includeCharacter,
        overwrite: false,
      );
    }
  }

  Future<void> _performExport(
    BuildContext context, {
    required bool includeCharacter,
    required bool overwrite,
  }) async {
    try {
      final result = await ExportService.exportChat(
        includeCharacter: includeCharacter,
        characterName: widget.characterName,
        roomId: StorageService.kDefaultRoomId,
        overwrite: overwrite,
      );

      if (result.success && context.mounted) {
        _showSuccessSnackBar(context, result);
      } else if (!result.success && context.mounted) {
        _showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '导出失败: $e');
      }
    }
  }

  Future<bool> _showOverwriteDialog(
      BuildContext context, String fileName) async {
    final sem = context.sem;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: sem.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: Icon(Icons.warning_rounded, color: sem.warning),
            title: Text(
              '文件已存在',
              style: TextStyle(fontSize: 16, color: sem.textPrimary),
            ),
            content: Text('已存在同名备份：$fileName\n是否覆盖？',
                style: TextStyle(color: sem.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(fontSize: 14, color: sem.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '覆盖',
                  style: TextStyle(fontSize: 14, color: sem.warning),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(BuildContext context, ExportResult result) {
    if (!result.success || result.filePath == null) return;

    final sem = context.sem;
    final fileName = result.filePath!.split('/').last;

    String displayPath = result.filePath!;
    if (displayPath.contains('/storage/emulated/0/')) {
      displayPath = displayPath.replaceAll('/storage/emulated/0/', '/内部存储/');
    }

    if (displayPath.contains('/Android/data/')) {
      displayPath =
          '应用私有下载目录/lovme\n(文件管理器 → 内部存储 → Android → data → com.wolfram.lovme → files → downloads → lovme)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            color: sem.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: sem.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '✅ 已保存文件',
                    style: TextStyle(
                      color: sem.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '文件: $fileName',
                style: TextStyle(
                  color: sem.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '保存到: $displayPath',
                style: TextStyle(
                  color: sem.textHint,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result.filePath!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('路径已复制到剪贴板'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: sem.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    '复制路径',
                    style: TextStyle(
                      fontSize: 12,
                      color: sem.info,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 6),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final sem = context.sem;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: sem.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
