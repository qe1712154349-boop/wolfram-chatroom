// lib/pages/chat/chat_backup_migrate_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '聊天记录迁移与备份',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 导出卡片（点击弹出子选项）- 放在最上面
        GestureDetector(
          onTap: () => _showExportOptions(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : primaryPink.withOpacity(0.08),
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
                  color: primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_upload_rounded, color: primaryPink, size: 28),
              ),
              title: Text(
                '导出全部配置',
                style: TextStyle(
                  fontSize: 16,
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
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
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
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_download_rounded, color: Colors.grey, size: 28),
              ),
              title: Text(
                '导入配置（开发中）',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              subtitle: Text(
                '从备份文件恢复人设与聊天记录',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ),
          ),
        ),

        // 底部安全说明（微信风格）- 移到最下面
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '提示',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : primaryPink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '可备份人设与聊天记录到本地。\n'
                '导出、导入格式为json。\n'
                '文件保存在 lovme/backup 文件夹，可通过文件管理器查看。',
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



  // 弹出导出选项（微信 ActionSheet 风格）
  void _showExportOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('导出选项'),
        message: const Text('请选择要导出的内容'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await _showConfirmDialog(context, '导出全部配置');
              if (confirm) {
                await ExportService.exportChat(
                  includeCharacter: true,
                  characterName: widget.characterName,
                  roomId: StorageService.kDefaultRoomId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已导出全部配置'),
                      backgroundColor: const Color(0xFFFF5A7E),
                    ),
                  );
                }
              }
            },
            child: const Text('导出全部配置（人设+消息）'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await _showConfirmDialog(context, '仅导出聊天记录');
              if (confirm) {
                await ExportService.exportChat(
                  includeCharacter: false,
                  characterName: widget.characterName,
                  roomId: StorageService.kDefaultRoomId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已导出仅聊天记录')),
                  );
                }
              }
            },
            child: const Text('仅导出聊天记录'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 确认弹窗
  Future<bool> _showConfirmDialog(BuildContext context, String action) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action'),
        content: const Text('将生成 .json 文件，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: const TextStyle(color: Color(0xFFFF5A7E))),
          ),
        ],
      ),
    ) ?? false;
  }
}