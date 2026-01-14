// lib/pages/chat/chat_character_edit_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class ChatCharacterEditPage extends StatefulWidget {
  const ChatCharacterEditPage({super.key});

  @override
  State<ChatCharacterEditPage> createState() => _ChatCharacterEditPageState();
}

class _ChatCharacterEditPageState extends State<ChatCharacterEditPage> {
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  
  String? _avatarPath;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _introController = TextEditingController();
  final TextEditingController _privateSettingController = TextEditingController();
  final TextEditingController _openingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 加载头像路径
      final avatarPath = await _storage.getCharacterAvatarPath();
      
      // 加载角色数据
      final characterData = await _storage.loadCharacterData();
      
      setState(() {
        _avatarPath = avatarPath;
        _nicknameController.text = characterData['nickname'] ?? '';
        _introController.text = characterData['intro'] ?? '';
        _privateSettingController.text = characterData['private_setting'] ?? '';
        _openingController.text = characterData['opening'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('加载角色数据失败: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
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
        final newPath = await _storage.copyFileToAppDir(image.path);
        
        // 保存新路径
        await _storage.saveCharacterAvatarPath(newPath);
        
        setState(() {
          _avatarPath = newPath;
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
      if (kDebugMode) {
        debugPrint('选择图片失败: $e');
      }
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCharacterData() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final characterData = <String, String>{
        'nickname': _nicknameController.text.trim(),
        'intro': _introController.text.trim(),
        'private_setting': _privateSettingController.text.trim(),
        'opening': _openingController.text.trim(),
      };
      
      await _storage.saveCharacterData(characterData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('角色设定已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('保存角色数据失败: $e');
      }
      
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

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _pickImageFromGallery,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFFFD1DC),
                  backgroundImage: _avatarPath != null
                      ? FileImage(File(_avatarPath!))
                      : null,
                  child: _avatarPath == null
                      ? const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (_isSaving)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                if (!_isSaving)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5A7E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击更换头像',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: '请输入${label.replaceAll('*', '').trim()}',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF8FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '编辑 AI 人设',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5A7E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '编辑 AI 人设',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像部分
            _buildAvatarSection(),
            const SizedBox(height: 32),

            // 昵称
            _buildTextField(
              label: '昵称',
              controller: _nicknameController,
              required: true,
            ),
            const SizedBox(height: 24),

            // 简介
            _buildTextField(
              label: '简介（对其他人展示）',
              controller: _introController,
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 24),

            // 附加设定（私密）
            _buildTextField(
              label: '附加设定（私密，不对外展示）',
              controller: _privateSettingController,
              maxLines: 8,
            ),
            const SizedBox(height: 16),
            Text(
              '这些设定会作为AI的系统提示，影响AI的性格和行为',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // 开场白
            _buildTextField(
              label: '开场白（对话开始时使用）',
              controller: _openingController,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCharacterData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A7E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        '保存设置',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 提示信息（移除格式相关提示）
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.pink[300], size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '提示',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD81B60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 昵称和简介会显示在聊天列表中\n• 附加设定会影响AI的行为和性格\n• 修改后需要重启聊天才能生效',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}