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
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  String? _userAvatarPath;
  String _userName = 'name';
  bool _showUserAvatar = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _storage.getUserProfile();
      
      setState(() {
        _userAvatarPath = profile['avatarPath'];
        _userName = profile['name'] ?? 'name';
        _showUserAvatar = profile['showAvatar'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickUserAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _isSaving = true;
        });
        
        // 复制文件到应用目录
        final newPath = await _storage.copyUserAvatarToAppDir(image.path);
        
        // 保存新路径
        await _storage.saveUserAvatarPath(newPath);
        
        setState(() {
          _userAvatarPath = newPath;
          _isSaving = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像已更新'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择头像失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveUserName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _storage.saveUserName(newName.trim());
      
      setState(() {
        _userName = newName.trim();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('名字已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _toggleShowUserAvatar(bool value) async {
    try {
      await _storage.saveShowUserAvatar(value);
      setState(() {
        _showUserAvatar = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改名字'),
        content: TextField(
          controller: nameController,
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
              if (nameController.text.trim().isNotEmpty) {
                _saveUserName(nameController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
            leading: const Text('头像', style: TextStyle(fontSize: 16)),
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
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _pickUserAvatar,
          ),
          const Divider(indent: 16),
          
          // 名字设置
          ListTile(
            leading: const Text('名字', style: TextStyle(fontSize: 16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_userName, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: _showEditNameDialog,
          ),
          const Divider(indent: 16),
          
          // 头像显示开关 - 往右靠，视觉更自然
          ListTile(
            leading: const Text('头像显示', style: TextStyle(fontSize: 16)),
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
          const Divider(indent: 16),
          
          // 说明文字
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '关闭"头像显示"后，在聊天界面中将不会显示您的头像',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}