// lib/pages/me/me_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_page.dart';
import 'profile_settings_page.dart'; // 新增导入
import '../../services/storage_service.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  String? _userAvatarPath;
  String _userName = 'name';
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 并行加载头像和用户名
    final avatarPath = await _storage.getUserAvatarPath();
    final name = await _storage.getUserName();
    
    setState(() {
      _userAvatarPath = avatarPath;
      _userName = name;
    });
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
          _isLoadingAvatar = true;
        });
        
        // 复制文件到应用目录
        final newPath = await _storage.copyUserAvatarToAppDir(image.path);
        
        // 保存新路径
        await _storage.saveUserAvatarPath(newPath);
        
        setState(() {
          _userAvatarPath = newPath;
          _isLoadingAvatar = false;
        });
        
        // 显示成功提示
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
      if (kDebugMode) {
        debugPrint('选择用户头像失败: $e');
      }
      setState(() {
        _isLoadingAvatar = false;
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // 用户信息卡片
        GestureDetector(
          onTap: () {
            // 点击整个卡片跳转到资料设置页面
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ).then((_) {
              // 返回时刷新数据
              _loadUserData();
            });
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            child: Row(
              children: [
                // 头像部分（可点击更换）
                GestureDetector(
                  onTap: _pickUserAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.pink,
                        backgroundImage: _userAvatarPath != null
                            ? FileImage(File(_userAvatarPath!))
                            : null,
                        child: _userAvatarPath == null
                            ? const Icon(Icons.person, size: 36, color: Colors.white)
                            : null,
                      ),
                      if (_isLoadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                      if (!_isLoadingAvatar)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.pink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "ID: likeme",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // 右侧箭头
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 功能列表
        _buildListTile(Icons.wechat_outlined, "爱意", Colors.green),
        const Divider(height: 1, indent: 60),
        _buildListTile(Icons.collections_bookmark_outlined, "收藏", Colors.orange),
        const Divider(height: 1, indent: 60),
        _buildListTile(Icons.photo_outlined, "朋友圈", Colors.blue),
        const Divider(height: 1, indent: 60),
        _buildListTile(Icons.credit_card_outlined, "小说", Colors.blueAccent),
        const Divider(height: 1, indent: 60),
        _buildListTile(Icons.sentiment_satisfied_alt_outlined, "相册", Colors.amber),
        
        const SizedBox(height: 10),
        
        // 设置入口
        ListTile(
          leading: const Icon(Icons.settings_outlined, color: Colors.blueGrey),
          title: const Text("设置"),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, Color iconColor) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () {
          // 这里可以添加对应的功能
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 功能开发中...')),
          );
        },
      ),
    );
  }
}