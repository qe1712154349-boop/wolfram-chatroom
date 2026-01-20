// lib/pages/me/profile_settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // ========== 服务 ==========
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  // ========== 状态 ==========
  String? _userAvatarPath;
  String _userName = 'name';
  bool _showUserAvatar = true;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // ========== 样式常量 ==========
  static const Color _titleColor = Color(0xFF333333);      // 深灰色文字
  static const Color _dividerColor = Color(0xFF999999);    // 中灰色分割线
  static const Color _descriptionColor = Color(0xFF666666); // 说明文字灰色
  
  static const TextStyle _titleTextStyle = TextStyle(
    fontSize: 16,
    color: _titleColor,
  );
  
  static const TextStyle _descriptionTextStyle = TextStyle(
    fontSize: 14,
    color: _descriptionColor,
  );
  
  static const Divider _customDivider = Divider(
    indent: 16,
    color: _dividerColor,
    thickness: 1,
    height: 1,
  );

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ========== 数据加载 ==========
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _storage.getUserProfile();
      setState(() {
        _userAvatarPath = profile['avatarPath'];
        _userName = profile['name'] ?? 'name';
        _showUserAvatar = profile['showAvatar'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ========== 头像处理 ==========
  Future<void> _pickUserAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() => _isSaving = true);
        final newPath = await _storage.copyUserAvatarToAppDir(image.path);
        await _storage.saveUserAvatarPath(newPath);
        setState(() {
          _userAvatarPath = newPath;
          _isSaving = false;
        });
        _showSuccessSnackBar('头像已更新');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('选择头像失败: ${e.toString()}');
    }
  }

  // ========== 名字处理 ==========
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

  // ========== 开关处理 ==========
  Future<void> _toggleShowUserAvatar(bool value) async {
    try {
      await _storage.saveShowUserAvatar(value);
      setState(() => _showUserAvatar = value);
    } catch (e) {
      _showErrorSnackBar('设置失败: ${e.toString()}');
    }
  }

  // ========== SnackBar 辅助方法 ==========
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ========== 对话框 ==========
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
              if (controller.text.trim().isNotEmpty) {
                _saveUserName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A7E),
            ),
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== 构建方法 ==========
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _pickUserAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.pink,
                        backgroundImage: _userAvatarPath != null
                            ? FileImage(File(_userAvatarPath!))
                            : null,
                        child: _userAvatarPath == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),  // 保持原来的间距
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _pickUserAvatar,
          ),
          _customDivider,
          
          // 名字设置
          ListTile(
            leading: const Text('名字', style: _titleTextStyle),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _showEditNameDialog,
          ),
          _customDivider,
          
          // 头像显示开关
          ListTile(
            leading: const Text('头像显示', style: _titleTextStyle),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: _showUserAvatar,
                  onChanged: _toggleShowUserAvatar,
                  activeThumbColor: const Color(0xFFFF5A7E),
                  activeTrackColor: const Color(0xFFFF5A7E).withOpacity(0.5),
                ),
              ],
            ),
          ),
          _customDivider,
          
          // 说明文字
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '关闭"头像显示"后，在聊天界面中将不会显示您的头像',
              style: _descriptionTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}