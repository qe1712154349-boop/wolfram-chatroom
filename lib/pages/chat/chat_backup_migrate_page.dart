import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../services/storage_service.dart';
import '../../theme/theme.dart' as app_theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';

class ChatBackupMigratePage extends ConsumerStatefulWidget {
  final String characterName;

  const ChatBackupMigratePage({
    super.key,
    required this.characterName,
  });

  @override
  ConsumerState<ChatBackupMigratePage> createState() =>
      _ChatBackupMigratePageState();
}

class _ChatBackupMigratePageState extends ConsumerState<ChatBackupMigratePage> {
  bool _isImporting = false;

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
                  '人设 + 聊天记录（.json）',
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

          // 导入卡片
          GestureDetector(
            onTap: _isImporting ? null : () => _showImportOptions(context),
            child: Opacity(
              opacity: _isImporting ? 0.6 : 1.0,
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
                      color: sem.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isImporting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(sem.primary),
                            ),
                          )
                        : Icon(Icons.cloud_download_rounded,
                            color: sem.primary, size: 28),
                  ),
                  title: Text(
                    '导入配置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: sem.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '从备份文件恢复人设与聊天记录',
                    style: TextStyle(fontSize: 13, color: sem.textSecondary),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: sem.textSecondary),
                ),
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

  // ============ 导出相关方法 ============

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
            onPressed: () =>
                _startExport(context, includeCharacter: true, share: false),
            child: const Text(
              '导出全部配置（人设+消息）',
              style: TextStyle(fontSize: 16),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                _startExport(context, includeCharacter: false, share: false),
            child: const Text(
              '仅导出聊天记录',
              style: TextStyle(fontSize: 16),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () =>
                _startExport(context, includeCharacter: true, share: true),
            child: const Text(
              '导出并分享全部配置',
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: false,
            onPressed: () =>
                _startExport(context, includeCharacter: false, share: true),
            child: const Text(
              '导出并分享聊天记录',
              style: TextStyle(fontSize: 16, color: Colors.blue),
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
      {required bool includeCharacter, required bool share}) async {
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
        share: share,
      );
    } else {
      if (!context.mounted) return;
      await _performExport(
        context,
        includeCharacter: includeCharacter,
        overwrite: false,
        share: share,
      );
    }
  }

  Future<void> _performExport(
    BuildContext context, {
    required bool includeCharacter,
    required bool overwrite,
    required bool share,
  }) async {
    try {
      final result = await ExportService.exportChat(
        includeCharacter: includeCharacter,
        characterName: widget.characterName,
        roomId: StorageService.kDefaultRoomId,
        overwrite: overwrite,
        shareAfterExport: share,
      );

      if (result.success && context.mounted) {
        _showSuccessSnackBar(context, result, share);
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

  void _showSuccessSnackBar(
      BuildContext context, ExportResult result, bool shared) {
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
                    shared ? '✅ 已分享文件' : '✅ 已保存文件',
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
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: TextButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: result.filePath!));
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
                  ),
                  if (!shared) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: TextButton(
                          onPressed: () {
                            final file = result.file;
                            if (file != null) {
                              final type = result.filePath!.contains('全部配置')
                                  ? '全部配置'
                                  : '聊天记录';
                              ExportService.shareExportedFile(
                                file,
                                widget.characterName,
                                type,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: sem.primary.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            '分享文件',
                            style: TextStyle(
                              fontSize: 12,
                              color: sem.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
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

  // ============ 导入相关方法 ============

  void _showImportOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          '导入选项',
          style: TextStyle(fontSize: 16),
        ),
        message: const Text(
          '请选择导入来源',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _pickFileAndImport(context),
            child: const Text(
              '从文件管理器选择',
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

  Future<void> _pickFileAndImport(BuildContext context) async {
    Navigator.pop(context);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '选择文件失败: $e');
      }
      return;
    }

    if (result == null || result.files.isEmpty) {
      if (context.mounted) {
        _showErrorSnackBar(context, '未选择文件');
      }
      return;
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      if (context.mounted) {
        _showErrorSnackBar(context, '无法获取文件路径');
      }
      return;
    }

    final file = File(filePath);

    await _showImportPreview(context, file);
  }

  Future<void> _showImportPreview(BuildContext context, File file) async {
    try {
      if (!mounted) return;
      setState(() => _isImporting = true);

      final previewResult = await ImportService.getImportPreview(file);

      if (!mounted) {
        setState(() => _isImporting = false);
        return;
      }

      setState(() => _isImporting = false);

      if (!previewResult.success) {
        _showErrorSnackBar(context, previewResult.message);
        return;
      }

      final preview = previewResult.preview;
      if (preview == null) {
        _showErrorSnackBar(context, '无法读取文件');
        return;
      }

      final sem = context.sem;
      final shouldImport = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: sem.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                '导入预览',
                style: TextStyle(fontSize: 18, color: sem.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPreviewItem(
                      context,
                      icon: Icons.person,
                      label: '人设名称',
                      value: preview.characterName,
                      sem: sem,
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewItem(
                      context,
                      icon: Icons.message,
                      label: '聊天记录',
                      value: '${preview.messageCount} 条消息',
                      sem: sem,
                    ),
                    const SizedBox(height: 12),
                    _buildPreviewItem(
                      context,
                      icon: Icons.schedule,
                      label: '导出时间',
                      value: preview.exportedAt,
                      sem: sem,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sem.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sem.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: sem.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '导入将覆盖现有人设和聊天记录',
                              style: TextStyle(
                                fontSize: 12,
                                color: sem.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                  style: TextButton.styleFrom(
                    foregroundColor: sem.error,
                  ),
                  child: const Text(
                    '确认导入',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (shouldImport) {
        if (!context.mounted) return;
        await _performImport(context, file);
      }
    } catch (e) {
      if (context.mounted) {
        setState(() => _isImporting = false);
        _showErrorSnackBar(context, '预览失败: $e');
      }
    }
  }

  Widget _buildPreviewItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required dynamic sem,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: sem.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: sem.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: sem.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performImport(BuildContext context, File file) async {
    try {
      setState(() => _isImporting = true);

      final result = await ImportService.executeImport(
        file,
        roomId: StorageService.kDefaultRoomId,
      );

      if (!mounted) {
        setState(() => _isImporting = false);
        return;
      }

      setState(() => _isImporting = false);

      if (result.success) {
        ref.invalidate(chatMessagesProvider);
        ref.invalidate(chatCharacterProvider);

        _showImportSuccessSnackBar(context, result);

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          Navigator.of(context).pop(true);
        });
      } else {
        _showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        _showErrorSnackBar(context, '导入失败: $e');
      }
    }
  }

  void _showImportSuccessSnackBar(BuildContext context, ImportResult result) {
    final sem = context.sem;
    final preview = result.preview;

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
                    '✅ 导入成功',
                    style: TextStyle(
                      color: sem.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (preview != null) ...[
                Text(
                  '人设: ${preview.characterName}',
                  style: TextStyle(
                    color: sem.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '聊天记录: ${preview.messageCount} 条',
                  style: TextStyle(
                    color: sem.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '已自动返回聊天室，请刷新页面查看',
                style: TextStyle(
                  color: sem.textHint,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
