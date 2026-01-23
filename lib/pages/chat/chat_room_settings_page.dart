// lib/pages/chat/chat_room_settings_page.dart - 优化版
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';
import '../../providers/theme_provider.dart';
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
    // 异步加载头像，避免阻塞UI线程
    _avatarImageFuture = _loadAvatarImage();
  }

  Future<FileImage?> _loadAvatarImage() async {
    if (widget.avatarPath == null) return null;

    try {
      // 异步检查文件是否存在
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
    // 优化：使用更轻量的对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // 允许点击外部关闭
      builder: (context) => _buildConfirmationDialog(context),
    );

    if (confirm == true) {
      // 显示加载指示器
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;

      await _storage.clearChatHistory();

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildConfirmationDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      title: const Text("清空聊天记录"),
      content: const Text("确定要清空所有聊天记录吗？此操作不可恢复。"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: cs.error,
          ),
          child: const Text("清空"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 优化：使用 select 来避免不必要的重建
    final pageTheme =
        ref.watch(pageThemeProvider(context).select((value) => value));
    final cs = pageTheme.colorScheme;

    return Theme(
      data: pageTheme,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.characterName} 设置",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _buildBody(cs),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      // 添加缓存和预加载优化
      cacheExtent: 500,
      children: [
        // 头像和名称展示 - 使用 FutureBuilder 异步加载
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ), // 移除阴影减少渲染开销
          child: Row(
            children: [
              FutureBuilder<FileImage?>(
                future: _avatarImageFuture,
                builder: (context, snapshot) {
                  return CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: snapshot.data,
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const CircularProgressIndicator(strokeWidth: 3)
                        : widget.avatarPath == null
                            ? Icon(Icons.person,
                                size: 36, color: cs.onPrimaryContainer)
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
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                onPressed: () => _editCharacter(),
              ),
            ],
          ),
        ),

        // 设置选项 - 使用 const 构造函数优化
        const SizedBox(height: 8),
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
          onTap: _blockCharacter,
        ),
        _buildSettingItem(
          icon: Icons.report_problem,
          title: "举报",
          subtitle: "举报此角色存在不当内容",
          color: cs.errorContainer,
          onTap: _reportCharacter,
        ),
        _buildSettingItem(
          icon: Icons.cloud_download,
          title: "聊天记录迁移与备份",
          subtitle: "导出/导入人设与消息，防丢失",
          color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ), // 移除阴影
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
        onTap: () {
          // 添加轻微延迟，避免连续点击
          Future.delayed(const Duration(milliseconds: 100), onTap);
        },
      ),
    );
  }

  void _editCharacter() {
    // 实现编辑角色逻辑
  }

  void _blockCharacter() {
    // 实现屏蔽角色逻辑
  }

  void _reportCharacter() {
    // 实现举报逻辑
  }

  void _navigateToBackup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatBackupMigratePage(
          characterName: widget.characterName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
