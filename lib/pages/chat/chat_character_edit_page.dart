// lib/pages/chat/chat_character_edit_page.dart
import 'dart:io';
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

  // 基础字段
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _introController = TextEditingController();
  final TextEditingController _privateSettingController = TextEditingController();
  final TextEditingController _openingController = TextEditingController();

  // 新增：自定义格式开关 + 控制器
  bool _enableCustomFormat = false;
  final TextEditingController _customFormatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> _loadCharacterData() async {
    setState(() => _isLoading = true);

    try {
      final avatarPath = await _storage.getCharacterAvatarPath();
      final data = await _storage.loadCharacterData();

      setState(() {
        _avatarPath = avatarPath;
        _nicknameController.text = data['nickname'] ?? '';
        _introController.text = data['intro'] ?? '';
        _privateSettingController.text = data['private_setting'] ?? '';
        _openingController.text = data['opening'] ?? '';
        // 新增字段加载
        _enableCustomFormat = data['enable_custom_format'] == 'true';
        _customFormatController.text = data['custom_format'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载角色数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,  // 限制图片尺寸，避免内存过大
        maxHeight: 800,
        imageQuality: 85, // 压缩质量
      );

      if (image != null) {
        setState(() => _isSaving = true);
        
        // 直接复制选中的图片到应用目录（不裁剪）
        final newPath = await _storage.copyFileToAppDir(image.path);
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
      debugPrint('选择图片失败: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 移除裁剪功能，只保留图片选择

  Future<void> _saveCharacterData() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final characterData = <String, String>{
        'nickname': _nicknameController.text.trim(),
        'intro': _introController.text.trim(),
        'private_setting': _privateSettingController.text.trim(),
        'opening': _openingController.text.trim(),
        'enable_custom_format': _enableCustomFormat.toString(),
        'custom_format': _customFormatController.text.trim(),
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
      debugPrint('保存角色数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
                if (!_isSaving && _avatarPath == null)
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
                        Icons.add_a_photo, 
                        color: Colors.white, 
                        size: 22,
                      ),
                    ),
                  ),
                if (!_isSaving && _avatarPath != null)
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
            _avatarPath == null ? '点击添加头像' : '点击更换头像',
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
    bool enabled = true,
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
          minLines: maxLines == 1 ? 1 : 3,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: '请输入${label.replaceAll('*', '').trim()}',
            hintStyle: TextStyle(
              color: enabled ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          style: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF5A7E),
            activeTrackColor: const Color(0xFFFF5A7E).withOpacity(0.5),
          ),
        ],
      ),
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
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
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
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.grey[700],
              ),
              onPressed: _loadCharacterData,
              tooltip: '刷新数据',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
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
              label: '简介（性格、爱好、职业等）',
              controller: _introController,
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 24),

            // 附加设定
            _buildTextField(
              label: '附加设定（私密）',
              controller: _privateSettingController,
              maxLines: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '这些设定会影响AI的性格和行为，不会直接显示给用户',
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
            const SizedBox(height: 24),

            // 自定义格式开关
            _buildSwitchOption(
              title: '启用自定义格式',
              description: '使用自定义的格式化指令覆盖默认格式',
              value: _enableCustomFormat,
              onChanged: (value) {
                setState(() {
                  _enableCustomFormat = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 自定义格式输入框
            if (_enableCustomFormat) ...[
              _buildTextField(
                label: '自定义格式指令',
                controller: _customFormatController,
                maxLines: 4,
                enabled: _enableCustomFormat,
              ),
              const SizedBox(height: 8),
              Text(
                '示例: "你是一位{{角色}}，请以{{风格}}的语气回复"',
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCharacterData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A7E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
            const SizedBox(height: 32),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD1DC), 
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline, 
                        color: Colors.pink[300], 
                        size: 18,
                      ),
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
                    '• 昵称和简介会显示在聊天列表\n'
                    '• 附加设定是AI的核心人格设定\n'
                    '• 自定义格式指令优先级最高\n'
                    '• 修改后需要重新进入聊天室生效',
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

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    _privateSettingController.dispose();
    _openingController.dispose();
    _customFormatController.dispose();
    super.dispose();
  }
}