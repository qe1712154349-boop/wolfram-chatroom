// lib/pages/chat/chat_room_settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../theme/theme.dart' as app_theme;
import 'chat_backup_migrate_page.dart';

class ChatRoomSettingsPage extends ConsumerStatefulWidget {
  final String characterName;
  final String? avatarPath;

  const ChatRoomSettingsPage({
    super.key,
    required this.characterName,
    this.avatarPath,
  });

  @override
  ConsumerState<ChatRoomSettingsPage> createState() =>
      _ChatRoomSettingsPageState();
}

class _ChatRoomSettingsPageState extends ConsumerState<ChatRoomSettingsPage> {
  final StorageService _storage = StorageService();
  late Future<FileImage?> _avatarImageFuture;

  @override
  void initState() {
    super.initState();
    _avatarImageFuture = _loadAvatarImage();
  }

  Future<FileImage?> _loadAvatarImage() async {
    if (widget.avatarPath == null) return null;

    try {
      final file = File(widget.avatarPath!);
      final exists = await file.exists();
      if (exists && file.statSync().size > 0) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('加载头像失败: $e');
    }
    return null;
  }

  Future<void> _clearChatHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _buildConfirmationDialog(context),
    );

    if (confirm == true) {
      await _storage.clearChatHistory();

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    final sem = context.sem;

    return AlertDialog(
      backgroundColor: sem.surface,
      title: Text(
        "清空聊天记录",
        style: TextStyle(color: sem.textPrimary),
      ),
      content: Text(
        "确定要清空所有聊天记录吗？此操作不可恢复。",
        style: TextStyle(color: sem.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "取消",
            style: TextStyle(color: sem.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: sem.error,
          ),
          child: const Text("清空"),
        ),
      ],
    );
  }

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
          icon: Icon(Icons.arrow_back, color: sem.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.characterName} 设置",
          style: TextStyle(
            color: sem.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final sem = context.sem;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      cacheExtent: 500,
      children: [
        // 头像和名称展示
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: sem.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              FutureBuilder<FileImage?>(
                future: _avatarImageFuture,
                builder: (context, snapshot) {
                  return CircleAvatar(
                    radius: 32,
                    backgroundColor: context
                        .themeColor(app_theme.ColorSemantic.primaryContainer),
                    backgroundImage: snapshot.data,
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(sem.primary),
                          )
                        : widget.avatarPath == null
                            ? Icon(Icons.person,
                                size: 36,
                                color: context.themeColor(
                                    app_theme.ColorSemantic.onPrimaryContainer))
                            : null,
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.characterName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sem.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "AI角色设置",
                      style: TextStyle(color: sem.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: sem.primary),
                onPressed: () => _editCharacter(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        _buildSettingItem(
          icon: Icons.delete_outline,
          title: "清空聊天记录",
          subtitle: "删除所有聊天消息",
          color: sem.error,
          onTap: _clearChatHistory,
        ),
        _buildSettingItem(
          icon: Icons.block,
          title: "屏蔽此角色",
          subtitle: "不再接收来自此角色的消息",
          color: sem.textSecondary,
          onTap: _blockCharacter,
        ),
        _buildSettingItem(
          icon: Icons.report_problem,
          title: "举报",
          subtitle: "举报此角色存在不当内容",
          color: sem.warning,
          onTap: _reportCharacter,
        ),
        _buildSettingItem(
          icon: Icons.cloud_download,
          title: "聊天记录迁移与备份",
          subtitle: "导出/导入人设与消息，防丢失",
          color: sem.primary,
          onTap: _navigateToBackup,
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final sem = context.sem;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: sem.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: sem.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: sem.textSecondary),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: sem.textSecondary),
        onTap: () {
          Future.delayed(const Duration(milliseconds: 100), onTap);
        },
      ),
    );
  }

  void _editCharacter() {}

  void _blockCharacter() {}

  void _reportCharacter() {}

  void _navigateToBackup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatBackupMigratePage(
          characterName: widget.characterName,
        ),
      ),
    );
  }
}
