// lib/pages/me/profile_settings_page.dart - 最终版（逻辑优化）
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../utils/asset_picker_util.dart';
import '../../providers/theme_provider.dart'; // 只导入 customColorsProvider
import 'package:photo_manager/photo_manager.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final StorageService _storage = StorageService();
  String? _userAvatarPath;
  String _userName = 'name';
  bool _showUserAvatar = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final profile = await _storage.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userAvatarPath = profile['avatarPath'] as String?;
        _userName = profile['name'] as String? ?? 'name';
        _showUserAvatar = profile['showAvatar'] as bool? ?? true;
      });
    } catch (e) {
      debugPrint('加载用户资料失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickUserAvatar() async {
    if (_isSaving) return;

    try {
      setState(() => _isSaving = true);
      final AssetEntity? asset =
          await AssetPickerUtil.pickSingleImageDirectly(context);
      if (asset == null) {
        setState(() => _isSaving = false);
        return;
      }

      final file = await asset.originFile;
      if (file == null) {
        setState(() => _isSaving = false);
        return;
      }

      final newPath = await _storage.copyUserAvatarToAppDir(file.path);
      await _storage.saveUserAvatarPath(newPath);

      if (!mounted) return;
      setState(() {
        _userAvatarPath = newPath;
        _isSaving = false;
      });

      _showSuccessSnackBar('头像已更新');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnackBar('选择头像失败: ${e.toString()}');
    }
  }

  Future<void> _saveUserName(String newName) async {
    if (newName.trim().isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _storage.saveUserName(newName.trim());
      if (!mounted) return;
      setState(() => _userName = newName.trim());
      _showSuccessSnackBar('名字已保存');
    } catch (e) {
      _showErrorSnackBar('保存失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleShowUserAvatar(bool value) async {
    try {
      await _storage.saveShowUserAvatar(value);
      if (!mounted) return;
      setState(() => _showUserAvatar = value);
    } catch (e) {
      _showErrorSnackBar('设置失败: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('修改名字'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '请输入名字',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _saveUserName(name);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 关键修改：直接使用 Theme.of(context)，不依赖 pageThemeProvider
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor: cs.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: cs.surface,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // 头像区域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickUserAvatar,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: _userAvatarPath != null
                        ? FileImage(File(_userAvatarPath!))
                        : null,
                    backgroundColor: cs.primaryContainer,
                    child: _userAvatarPath == null
                        ? Icon(Icons.person,
                            size: 36, color: cs.onPrimaryContainer)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击头像更换',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 设置项
          _buildSettingItem(
            icon: Icons.edit,
            title: '修改名字',
            subtitle: _userName,
            onTap: _showEditNameDialog,
            cs: cs,
          ),
          _buildSettingItem(
            icon: Icons.visibility,
            title: '在聊天中显示头像',
            subtitle: _showUserAvatar ? '已开启' : '已关闭',
            trailing: Switch(
              value: _showUserAvatar,
              onChanged: _toggleShowUserAvatar,
              activeColor: cs.primary,
            ),
            cs: cs,
          ),
          _buildSettingItem(
            icon: Icons.palette,
            title: '从图片提取主题色',
            subtitle: '选择图片让App变色',
            onTap: () async {
              try {
                final asset =
                    await AssetPickerUtil.pickSingleImageDirectly(context);
                if (asset == null) return;

                final colors = await AssetPickerUtil.extractPalette(asset);
                if (colors == null || colors.isEmpty) {
                  _showErrorSnackBar('提取失败，请重试');
                  return;
                }

                // ✅ 只更新 customColorsProvider，main.dart会自动处理
                ref.read(customColorsProvider.notifier).updateColors(colors);
                _showSuccessSnackBar('主题色已提取完成');
              } catch (e) {
                _showErrorSnackBar('操作失败: ${e.toString()}');
              }
            },
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
