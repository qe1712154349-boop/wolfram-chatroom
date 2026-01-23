// lib/pages/me/profile_settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../utils/asset_picker_util.dart';
import '../../providers/theme_provider.dart';
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

  // 静态 fallback 颜色（当动态主题未就绪时使用）
  static const Color _fallbackTitleColor = Color(0xFF333333);
  static const Color _fallbackDividerColor = Color(0xFF999999);
  static const Color _fallbackDescriptionColor = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _storage.getUserProfile();
      if (!mounted) return;
      setState(() {
        _userAvatarPath = profile['avatarPath'] as String?;
        _userName = profile['name'] as String? ?? 'name';
        _showUserAvatar = profile['showAvatar'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickUserAvatar() async {
    try {
      final AssetEntity? asset =
          await AssetPickerUtil.pickSingleImageDirectly(context);
      if (asset == null) return;

      if (!mounted) return;
      setState(() => _isSaving = true);

      final file = await asset.originFile;
      if (file == null) return;

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
    if (newName.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      await _storage.saveUserName(newName.trim());
      if (!mounted) return;
      setState(() => _userName = newName.trim());
      _showSuccessSnackBar('名字已保存');
    } catch (e) {
      _showErrorSnackBar('保存失败: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
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
    // 使用 family provider，传入 context
    final pageTheme = ref.watch(pageThemeProvider(context));

    // 从动态主题中提取颜色，fallback 到静态常量
    final dynamicTitleColor = pageTheme.colorScheme.primary;
    final dynamicDividerColor =
        pageTheme.dividerTheme.color ?? _fallbackDividerColor;
    final dynamicDescriptionColor = pageTheme.colorScheme.secondary;

    if (_isLoading) {
      return Theme(
        data: pageTheme,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('个人资料'),
            backgroundColor: pageTheme.appBarTheme.backgroundColor,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Theme(
      data: pageTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor: pageTheme.appBarTheme.backgroundColor,
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
                      color: dynamicTitleColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          children: [
            // 头像设置
            ListTile(
              leading: Text('头像',
                  style: TextStyle(fontSize: 16, color: dynamicTitleColor)),
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
                          ? Icon(Icons.person, color: dynamicTitleColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(_userName,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dynamicTitleColor)),
                ],
              ),
            ),
            Divider(
                indent: 16,
                color: dynamicDividerColor,
                thickness: 1,
                height: 1),

            // 名字设置
            ListTile(
              leading: Text('名字',
                  style: TextStyle(fontSize: 16, color: dynamicTitleColor)),
              title: Text(_userName,
                  style:
                      TextStyle(fontSize: 14, color: dynamicDescriptionColor)),
              trailing: Icon(Icons.edit, color: dynamicTitleColor),
              onTap: _showEditNameDialog,
            ),
            Divider(
                indent: 16,
                color: dynamicDividerColor,
                thickness: 1,
                height: 1),

            // 显示头像开关
            SwitchListTile(
              title: Text('在聊天中显示我的头像',
                  style: TextStyle(fontSize: 16, color: dynamicTitleColor)),
              value: _showUserAvatar,
              onChanged: _toggleShowUserAvatar,
              activeThumbColor: dynamicTitleColor,
              activeTrackColor:
                  dynamicTitleColor.withAlpha((0.5 * 255).round()),
            ),
            Divider(
                indent: 16,
                color: dynamicDividerColor,
                thickness: 1,
                height: 1),

            // 从图片提取主题色
            ListTile(
              leading: Icon(Icons.palette, color: dynamicTitleColor),
              title: Text('从图片提取主题色',
                  style: TextStyle(fontSize: 16, color: dynamicTitleColor)),
              subtitle: Text('选择一张图片，让 App 整体变色',
                  style:
                      TextStyle(fontSize: 14, color: dynamicDescriptionColor)),
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

                // family provider 自动触发页面重建，无需 setState
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('主题已适配完成'),
                    backgroundColor: dynamicTitleColor,
                  ),
                );
              },
            ),
            Divider(
                indent: 16,
                color: dynamicDividerColor,
                thickness: 1,
                height: 1),
          ],
        ),
      ),
    );
  }
}
