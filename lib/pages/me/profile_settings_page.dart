// lib/pages/me/profile_settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../utils/asset_picker_util.dart';
import '../../theme/theme.dart' as app_theme;
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
      if (mounted) setState(() => _isLoading = false);
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

      _showSnackBar('头像已更新', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('选择头像失败: $e', isSuccess: false);
    }
  }

  Future<void> _saveUserName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _storage.saveUserName(trimmed);
      if (!mounted) return;
      setState(() => _userName = trimmed);
      _showSnackBar('名字已保存', isSuccess: true);
    } catch (e) {
      _showSnackBar('保存失败: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleShowUserAvatar(bool value) async {
    try {
      await _storage.saveShowUserAvatar(value);
      if (!mounted) return;
      setState(() => _showUserAvatar = value);
    } catch (e) {
      _showSnackBar('设置失败: $e', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? null
            : context.themeColor(app_theme.ColorSemantic.error), // ✅ 改用语义颜色
        duration: Duration(seconds: isSuccess ? 2 : 3),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor:
              context.themeColor(app_theme.ColorSemantic.appBarBackground),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        foregroundColor: context.themeColor(app_theme.ColorSemantic.appBarText),
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
                    color: context.themeColor(app_theme.ColorSemantic.primary),
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
              color: context
                  .themeColor(app_theme.ColorSemantic.surfaceContainerHighest),
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
                    backgroundColor: context
                        .themeColor(app_theme.ColorSemantic.primaryContainer),
                    child: _userAvatarPath == null
                        ? Icon(
                            Icons.person,
                            size: 36,
                            color: context.themeColor(
                                app_theme.ColorSemantic.onPrimaryContainer),
                          )
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
                          color: context
                              .themeColor(app_theme.ColorSemantic.onSurface),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '点击头像更换',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.themeColor(
                              app_theme.ColorSemantic.onSurfaceVariant),
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
          ),
          _buildSettingItem(
            icon: Icons.visibility,
            title: '在聊天中显示头像',
            subtitle: _showUserAvatar ? '已开启' : '已关闭',
            trailing: Switch(
              value: _showUserAvatar,
              onChanged: _toggleShowUserAvatar,
              activeThumbColor:
                  context.themeColor(app_theme.ColorSemantic.switchActive),
            ),
          ),

          // 测试按钮
          _buildSettingItem(
            icon: Icons.color_lens,
            title: '测试主题色更新',
            subtitle: '点击测试颜色变化',
            onTap: () async {
              final testColor = Colors.deepPurple;
              final testColors = {
                app_theme.ExtractedColorType.dominant: testColor,
                app_theme.ExtractedColorType.vibrant: Color.fromRGBO(
                  (testColor.red * 255 + 30).clamp(0, 255).toInt(),
                  (testColor.green * 255 + 30).clamp(0, 255).toInt(),
                  (testColor.blue * 255 + 30).clamp(0, 255).toInt(),
                  1.0,
                ),
                app_theme.ExtractedColorType.lightVibrant: Color.fromRGBO(
                  (testColor.red * 255 + 60).clamp(0, 255).toInt(),
                  (testColor.green * 255 + 60).clamp(0, 255).toInt(),
                  (testColor.blue * 255 + 60).clamp(0, 255).toInt(),
                  1.0,
                ),
                app_theme.ExtractedColorType.darkVibrant: Color.fromRGBO(
                  (testColor.red * 255 - 30).clamp(0, 255).toInt(),
                  (testColor.green * 255 - 30).clamp(0, 255).toInt(),
                  (testColor.blue * 255 - 30).clamp(0, 255).toInt(),
                  1.0,
                ),
                app_theme.ExtractedColorType.muted:
                    testColor.withValues(alpha: 0.5),
              };
              await ref
                  .read(app_theme.extractedColorsUtilsProvider)
                  .updateColors(testColors);
              _showSnackBar('已应用紫色主题', isSuccess: true);
            },
          ),

          // 图片提取主题色
          _buildSettingItem(
            icon: Icons.palette,
            title: '从图片提取主题色',
            subtitle: '选择图片让App变色',
            onTap: () async {
              final asset =
                  await AssetPickerUtil.pickSingleImageDirectly(context);
              if (asset == null) return;

              final rawColors = await AssetPickerUtil.extractPalette(asset);
              if (rawColors == null || rawColors.isEmpty) {
                _showSnackBar('提取失败', isSuccess: false);
                return;
              }

              // 关键：用工具类转换字符串 key → 枚举 key
              final convertedColors = ref
                  .read(app_theme.extractedColorsUtilsProvider)
                  .convertFromStringMap(rawColors);

              // 如果转换后为空或不完整，可加提示
              if (convertedColors.isEmpty) {
                _showSnackBar('提取颜色无效', isSuccess: false);
                return;
              }

              await ref
                  .read(app_theme.extractedColorsUtilsProvider)
                  .updateColors(convertedColors);

              _showSnackBar('主题色已提取', isSuccess: true);
            },
          ),

          // 重置主题色
          _buildSettingItem(
            icon: Icons.restart_alt,
            title: '重置主题色',
            subtitle: '恢复到默认颜色',
            onTap: () async {
              await ref.read(app_theme.extractedColorsUtilsProvider).reset();
              _showSnackBar('主题色已重置', isSuccess: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            context.themeColor(app_theme.ColorSemantic.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: context.themeColor(app_theme.ColorSemantic.primary)),
        title: Text(
          title,
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.onSurface),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.onSurfaceVariant),
            fontSize: 12,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  context.themeColor(app_theme.ColorSemantic.onSurfaceVariant),
            ),
        onTap: onTap,
      ),
    );
  }
}
