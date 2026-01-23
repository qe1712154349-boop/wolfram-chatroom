// lib/pages/chat/chat_room_settings_page.dart - 修复版（Material 3 规范 + 动态主题响应）
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 添加 Riverpod 导入
import '../../services/storage_service.dart';
import '../../providers/theme_provider.dart'; // 导入 family provider
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

  Future<void> _clearChatHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text(
            "清空聊天记录",
            style: TextStyle(color: cs.onSurface),
          ),
          content: Text(
            "确定要清空所有聊天记录吗？此操作不可恢复。",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "取消",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "清空",
                style: TextStyle(color: cs.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _storage.clearChatHistory();
      if (mounted) {
        Navigator.pop(context, true); // 返回true表示已清空
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 family provider，传入 context，实现局部动态主题
    final pageTheme = ref.watch(pageThemeProvider(context));
    final cs = pageTheme.colorScheme;

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.characterName} 设置",
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 头像和名称展示
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withAlpha(64),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: widget.avatarPath != null
                        ? FileImage(File(widget.avatarPath!))
                        : null,
                    child: widget.avatarPath == null
                        ? Icon(Icons.person,
                            size: 36, color: cs.onPrimaryContainer)
                        : null,
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
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "AI角色设置",
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: cs.primary),
                    onPressed: () {
                      // 跳转到角色编辑页面
                      // Navigator.push(...)
                    },
                  ),
                ],
              ),
            ),

            // 设置选项
            _buildSettingItem(
              icon: Icons.delete_outline,
              title: "清空聊天记录",
              subtitle: "删除所有聊天消息",
              color: cs.error,
              onTap: _clearChatHistory,
            ),
            _buildSettingItem(
              icon: Icons.block,
              title: "屏蔽此角色",
              subtitle: "不再接收来自此角色的消息",
              color: cs.onSurfaceVariant,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.report_problem,
              title: "举报",
              subtitle: "举报此角色存在不当内容",
              color: cs.errorContainer,
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.cloud_download,
              title: "聊天记录迁移与备份",
              subtitle: "导出/导入人设与消息，防丢失",
              color: cs.primary,
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatBackupMigratePage(
                      characterName: widget.characterName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(64),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
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
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
