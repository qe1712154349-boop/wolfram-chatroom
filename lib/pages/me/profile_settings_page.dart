// lib/pages/me/profile_settings_page.dart - 修复版
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
  final GlobalKey _scaffoldKey = GlobalKey(); // 添加全局Key

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

  @override
  void dispose() {
    // 清理可能的异步操作
    super.dispose();
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
    // 使用安全的 SnackBar 显示方式
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);

    // 延迟显示对话框，确保UI稳定
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                '保存',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用 family provider，传入 context
    final pageTheme = ref.watch(pageThemeProvider(context));
    final cs = pageTheme.colorScheme;

    if (_isLoading) {
      return Theme(
        data: pageTheme,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('个人资料'),
            backgroundColor: cs.surface,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Theme(
      data: pageTheme,
      child: Scaffold(
        key: _scaffoldKey,
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
        body: SingleChildScrollView(
          // 使用 SingleChildScrollView 替代 ListView
          child: Column(
            children: [
              // 头像设置
              _buildAvatarSection(cs),
              const SizedBox(height: 8),

              // 名字设置
              _buildNameSection(cs),
              const SizedBox(height: 8),

              // 显示头像开关
              _buildAvatarSwitch(cs),
              const SizedBox(height: 8),

              // 从图片提取主题色
              _buildThemeExtractSection(cs),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickUserAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: _userAvatarPath != null
                      ? FileImage(File(_userAvatarPath!))
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: _userAvatarPath == null
                      ? Icon(Icons.person,
                          size: 40, color: cs.onPrimaryContainer)
                      : null,
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
              ],
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
    );
  }

  Widget _buildNameSection(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.person, color: cs.primary),
        title: Text(
          '名字',
          style: TextStyle(
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          _userName,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.edit, color: cs.primary),
        onTap: _showEditNameDialog,
      ),
    );
  }

  Widget _buildAvatarSwitch(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          '在聊天中显示我的头像',
          style: TextStyle(
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          '开启后，你的头像会在聊天界面显示',
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        value: _showUserAvatar,
        onChanged: _toggleShowUserAvatar,
        activeColor: cs.primary,
        activeTrackColor: cs.primaryContainer,
      ),
    );
  }

  Widget _buildThemeExtractSection(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.palette, color: cs.primary),
        title: Text(
          '从图片提取主题色',
          style: TextStyle(
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          '选择一张图片，让 App 整体变色',
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: cs.primary),
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

            ref.read(customColorsProvider.notifier).updateColors(colors);

            _showSuccessSnackBar('主题已适配完成');
          } catch (e) {
            _showErrorSnackBar('操作失败: ${e.toString()}');
          }
        },
      ),
    );
  }
}
