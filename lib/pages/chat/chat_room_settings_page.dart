import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../app/theme.dart';  // 导入 AppTheme 以使用暗色常量

class ChatRoomSettingsPage extends StatefulWidget {
  final String characterName;
  final String? avatarPath;

  const ChatRoomSettingsPage({
    super.key,
    required this.characterName,
    this.avatarPath,
  });

  @override
  State<ChatRoomSettingsPage> createState() => _ChatRoomSettingsPageState();
}

class _ChatRoomSettingsPageState extends State<ChatRoomSettingsPage> {
  final StorageService _storage = StorageService();

  Future<void> _clearChatHistory() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.white,
        title: Text("清空聊天记录", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
        content: Text("确定要清空所有聊天记录吗？此操作不可恢复。", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("取消", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("清空", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFF8FA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.characterName} 设置",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
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
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.grey.withAlpha(26),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark ? const Color(0xFF2A1A1A) : Colors.pinkAccent,
                  backgroundImage: widget.avatarPath != null
                      ? FileImage(File(widget.avatarPath!))
                      : null,
                  child: widget.avatarPath == null
                      ? Icon(Icons.person, size: 36, color: isDark ? Colors.white : Colors.white)
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
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "AI角色设置",
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: isDark ? const Color(0xFFF95685) : Colors.pinkAccent),
                  onPressed: () {
                    // 这里可以跳转到角色编辑页面
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
            color: Colors.red,
            onTap: _clearChatHistory,
          ),
          _buildSettingItem(
            icon: Icons.block,
            title: "屏蔽此角色",
            subtitle: "不再接收来自此角色的消息",
            color: Colors.grey,
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.report_problem,
            title: "举报",
            subtitle: "举报此角色存在不当内容",
            color: Colors.orange,
            onTap: () {},
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.grey.withAlpha(26),
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
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey[400] : Colors.grey),
        onTap: onTap,
      ),
    );
  }
}