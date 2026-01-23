// lib/pages/me/profile_settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../utils/asset_picker_util.dart';
import '../../providers/theme_provider.dart';
import 'package:photo_manager/photo_manager.dart'; // ← 必须导入！AssetEntity 来自这里

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

  static const Color _titleColor = Color(0xFF333333);
  static const Color _dividerColor = Color(0xFF999999);
  static const Color _descriptionColor = Color(0xFF666666);

  static const TextStyle _titleTextStyle =
      TextStyle(fontSize: 16, color: _titleColor);
  static const TextStyle _descriptionTextStyle =
      TextStyle(fontSize: 14, color: _descriptionColor);

  static const Divider _customDivider =
      Divider(indent: 16, color: _dividerColor, thickness: 1, height: 1);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _storage.getUserProfile();
      setState(() {
        _userAvatarPath = profile['avatarPath'] as String?;
        _userName = profile['name'] as String? ?? 'name';
        _showUserAvatar = profile['showAvatar'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickUserAvatar() async {
    try {
      final AssetEntity? asset =
          await AssetPickerUtil.pickSingleImageDirectly(context);
      if (asset == null) return;

      setState(() => _isSaving = true);

      final file = await asset.originFile;
      if (file == null) return;

      final newPath = await _storage.copyUserAvatarToAppDir(file.path);
      await _storage.saveUserAvatarPath(newPath);

      setState(() {
        _userAvatarPath = newPath;
        _isSaving = false;
      });

      _showSuccessSnackBar('头像已更新');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('选择头像失败: ${e.toString()}');
    }
  }

  Future<void> _saveUserName(String newName) async {
    if (newName.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await _storage.saveUserName(newName.trim());
      setState(() => _userName = newName.trim());
      _showSuccessSnackBar('名字已保存');
    } catch (e) {
      _showErrorSnackBar('保存失败: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleShowUserAvatar(bool value) async {
    try {
      await _storage.saveShowUserAvatar(value);
      setState(() => _showUserAvatar = value);
    } catch (e) {
      _showErrorSnackBar('设置失败: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A7E)),
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('个人资料'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          // 头像设置
          ListTile(
            leading: const Text('头像', style: _titleTextStyle),
            title: Row(
              children: [
                GestureDetector(
                  onTap: _pickUserAvatar,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: _userAvatarPath != null
                        ? FileImage(File(_userAvatarPath!))
                        : null,
                    child: _userAvatarPath == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Text(_userName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _customDivider,

          // 名字设置
          ListTile(
            leading: const Text('名字', style: _titleTextStyle),
            title: Text(_userName, style: _descriptionTextStyle),
            trailing: const Icon(Icons.edit),
            onTap: _showEditNameDialog,
          ),
          _customDivider,

          // 显示头像开关（替换 activeColor → activeThumbColor）
          SwitchListTile(
            title: const Text('在聊天中显示我的头像', style: _titleTextStyle),
            value: _showUserAvatar,
            onChanged: _toggleShowUserAvatar,
            activeThumbColor: const Color(0xFFFF5A7E), // ← 替换 activeColor
            activeTrackColor: const Color(0xFFFF5A7E).withOpacity(0.5),
          ),
          _customDivider,

          // 从图片提取主题色
          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xFFFF5A7E)),
            title: const Text('从图片提取主题色', style: _titleTextStyle),
            subtitle:
                const Text('选择一张图片，让 App 整体变色', style: _descriptionTextStyle),
            onTap: () async {
              final asset =
                  await AssetPickerUtil.pickSingleImageDirectly(context);
              if (asset == null) return;

              final colors = await AssetPickerUtil.extractPalette(asset);
              if (colors == null || colors.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('提取失败，请重试')),
                );
                return;
              }

              ref.read(customColorsProvider.notifier).updateColors(colors);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题已适配完成')),
              );
            },
          ),
          _customDivider,
        ],
      ),
    );
  }
}
