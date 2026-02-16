// lib/pages/me/me_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_page.dart';
import 'profile_settings_page.dart';
import '../../services/storage_service.dart';
import '../diary/diary_bookshelf_page.dart';
import '../../theme/theme.dart' as app_theme;

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

        final newPath = await _storage.copyUserAvatarToAppDir(image.path);

        await _storage.saveUserAvatarPath(newPath);

        setState(() {
          _userAvatarPath = newPath;
          _isLoadingAvatar = false;
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
            backgroundColor: context.themeColor(app_theme.ColorSemantic.error),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;

    return ListView(
      children: [
        // 用户信息卡片
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ).then((_) {
              _loadUserData();
            });
          },
          child: Container(
            color: sem.surface,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickUserAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: sem.primary,
                        backgroundImage: _userAvatarPath != null
                            ? FileImage(File(_userAvatarPath!))
                            : null,
                        child: _userAvatarPath == null
                            ? const Icon(Icons.person,
                                size: 36, color: Colors.white)
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
                              child: CircularProgressIndicator(
                                  color: Colors.white),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: sem.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: likeme",
                        style:
                            TextStyle(color: sem.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: sem.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 功能列表
        _buildListTile(Icons.wechat_outlined, "记录", sem.success, context),
        Divider(height: 1, indent: 60, color: sem.divider),
        _buildListTile(Icons.collections_bookmark_outlined, "收藏·碎碎念",
            sem.warning, context),
        Divider(height: 1, indent: 60, color: sem.divider),
        _buildListTile(Icons.photo_outlined, "书架", sem.info, context),
        Divider(height: 1, indent: 60, color: sem.divider),
        _buildListTile(Icons.credit_card_outlined, "结婚纪念日", sem.info, context),
        Divider(height: 1, indent: 60, color: sem.divider),
        _buildListTile(Icons.sentiment_satisfied_alt_outlined, "心情不好·日记本",
            sem.warning, context),

        const SizedBox(height: 10),

        // 设置入口
        Container(
          color: sem.surface,
          child: ListTile(
            leading: Icon(Icons.settings_outlined, color: sem.textSecondary),
            title: Text("设置", style: TextStyle(color: sem.textPrimary)),
            trailing:
                Icon(Icons.chevron_right, color: sem.textSecondary, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
      IconData icon, String title, Color iconColor, BuildContext context) {
    final sem = context.sem;

    return Container(
      color: sem.surface,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(color: sem.textPrimary)),
        trailing: Icon(Icons.chevron_right, color: sem.textSecondary, size: 20),
        onTap: () {
          if (title == "心情不好·日记本") {
            try {
              if (kDebugMode) {
                print('🎯 正在跳转到日记书架页面...');
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DiaryBookshelfPage(),
                ),
              ).then((_) {
                if (kDebugMode) {
                  print('✅ 从日记书架页面返回');
                }
              }).catchError((error) {
                if (kDebugMode) {
                  print('❌ 跳转过程出错: $error');
                }
              });
            } catch (e, stackTrace) {
              if (kDebugMode) {
                print('💥 点击日记本时发生异常:');
                print('错误类型: ${e.runtimeType}');
                print('错误信息: $e');
                print('堆栈跟踪: $stackTrace');
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('打开日记本时出错: ${e.toString().split('\n').first}'),
                  backgroundColor: sem.error,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 功能开发中...'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}
