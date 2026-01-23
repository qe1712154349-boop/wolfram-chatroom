import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加 Clipboard 支持
import '../../services/export_service.dart';
import '../../services/storage_service.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPink = const Color(0xFFFF5A7E);
    final lightPinkBg = const Color(0xFFFFF0F5);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : lightPinkBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '聊天记录迁移与备份',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16, // 调整为16px
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
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : primaryPink.withValues(alpha: 0.08),
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
                    color: primaryPink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_upload_rounded,
                      color: primaryPink, size: 28),
                ),
                title: Text(
                  '导出全部配置',
                  style: TextStyle(
                    fontSize: 16, // 调整为16px
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '人设 + 聊天记录 + 头像引用（.json）',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ),
            ),
          ),

          // 导入卡片（置灰）
          Opacity(
            opacity: 0.55,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_download_rounded,
                      color: Colors.grey, size: 28),
                ),
                title: Text(
                  '导入配置（开发中）',
                  style: TextStyle(
                    fontSize: 16, // 调整为16px
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                subtitle: Text(
                  '从备份文件恢复人设与聊天记录',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.grey),
              ),
            ),
          ),

          // 底部说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.12),
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
                    fontSize: 16, // 调整为16px
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : primaryPink,
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
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 弹出导出选项
  void _showExportOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          '导出选项',
          style: TextStyle(fontSize: 16), // 调整为16px
        ),
        message: Text(
          '请选择要导出的内容',
          style: TextStyle(fontSize: 14), // 调整为14px
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => _startExport(context, includeCharacter: true),
            child: Text(
              '导出全部配置（人设+消息）',
              style: TextStyle(fontSize: 16), // 调整为16px
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => _startExport(context, includeCharacter: false),
            child: Text(
              '仅导出聊天记录',
              style: TextStyle(fontSize: 16), // 调整为16px
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(fontSize: 16), // 调整为16px
            ),
          ),
        ],
      ),
    );
  }

  // 开始导出流程
  Future<void> _startExport(BuildContext context,
      {required bool includeCharacter}) async {
    // 先关闭ActionSheet
    Navigator.pop(context);

    // 1. 检查文件是否已存在
    final fileExists = await ExportService.checkFileExists(
      widget.characterName, // 角色名
      includeCharacter, // 是否是全部配置
    );

    if (fileExists) {
      // 2. 如果存在，询问是否覆盖
      final type = includeCharacter ? '全部配置' : '聊天记录';
      final fileName = '${widget.characterName}-$type.json';
      final shouldOverwrite = await _showOverwriteDialog(context, fileName);

      if (!shouldOverwrite) return; // 用户取消覆盖

      // 3. 覆盖导出
      await _performExport(
        context,
        includeCharacter: includeCharacter,
        overwrite: true,
      );
    } else {
      // 4. 直接导出（新文件）
      await _performExport(
        context,
        includeCharacter: includeCharacter,
        overwrite: false,
      );
    }
  }

  // 执行导出操作 - 更新版本
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
        // 使用新的 _showSuccessSnackBar 版本
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

  // 覆盖确认对话框
  Future<bool> _showOverwriteDialog(
      BuildContext context, String fileName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.warning_rounded, color: Colors.orange),
            title: Text(
              '文件已存在',
              style: TextStyle(fontSize: 16), // 调整为16px
            ),
            content: Text('已存在同名备份：$fileName\n是否覆盖？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '取消',
                  style: TextStyle(fontSize: 14), // 调整为14px
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '覆盖',
                  style:
                      TextStyle(fontSize: 14, color: Colors.orange), // 调整为14px
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 成功提示 - 新版（显示详细路径）
  void _showSuccessSnackBar(BuildContext context, ExportResult result) {
    if (!result.success || result.filePath == null) return;

    final fileName = result.filePath!.split('/').last;

    // 转换路径格式（用户友好显示）
    String displayPath = result.filePath!;
    if (displayPath.contains('/storage/emulated/0/')) {
      displayPath = displayPath.replaceAll('/storage/emulated/0/', '/内部存储/');
    }

    // 如果是应用私有目录，给出额外提示
    if (displayPath.contains('/Android/data/')) {
      displayPath =
          '应用私有下载目录/lovme\n(文件管理器 → 内部存储 → Android → data → com.example.my_new_app → files → downloads → lovme)';
    }

    // 显示微信风格的底部卡片
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
              // 标题
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFFFF5A7E),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '✅ 已保存文件',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 文件名
              Text(
                '文件: $fileName',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),

              // 路径（模仿微信的灰色小字）
              Text(
                '保存到: $displayPath',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),

              // 复制路径按钮（小按钮）
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
                    backgroundColor: const Color(0xFFF5F5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    '复制路径',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
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

  // 错误提示
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14), // 调整为14px
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
