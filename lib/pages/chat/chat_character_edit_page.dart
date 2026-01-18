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

class _ChatCharacterEditPageState extends State<ChatCharacterEditPage>
    with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();

  String? _avatarPath;
  bool _isLoading = true;
  bool _isSaving = false;

  // 基础字段
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _introController = TextEditingController();
  final TextEditingController _privateSettingController =
      TextEditingController();
  final TextEditingController _openingController = TextEditingController();

  // 自定义格式开关
  bool _enableCustomFormat = false;

  // 🎯 关键修改：两个独立的控制器
  final TextEditingController _plainPromptController =
      TextEditingController(); // 关闭时的普通提示词
  final TextEditingController _xmlFormatController =
      TextEditingController(); // 开启时的XML格式指令

// 🎯 新增：弹力球动画控制器（改为late final确保不为空）
late final AnimationController _switchAnimationController;

@override
void initState() {
  super.initState();
  
  // 🎯 必须先初始化动画控制器
  _switchAnimationController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  
  // 然后加载数据
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

        // 加载开关状态
        _enableCustomFormat = data['enable_custom_format'] == 'true';

        // 🎯 关键修改：分别加载两个字段
        _plainPromptController.text = data['plain_prompt'] ?? ''; // 普通提示词
        _xmlFormatController.text = data['custom_format'] ?? ''; // XML格式指令

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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isSaving = true);

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

  Future<void> _saveCharacterData() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 🎯 关键修改：保存两个独立的字段
      final characterData = <String, String>{
        'nickname': _nicknameController.text.trim(),
        'intro': _introController.text.trim(),
        'private_setting': _privateSettingController.text.trim(),
        'opening': _openingController.text.trim(),
        'enable_custom_format': _enableCustomFormat.toString(),

        // 保存两个不同的内容
        'plain_prompt': _plainPromptController.text.trim(), // 普通提示词
        'custom_format': _xmlFormatController.text.trim(), // XML格式指令
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _pickImageFromGallery,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: isDark
                      ? Colors.grey[800]
                      : const Color(0xFFFFD1DC), // 动态背景
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _avatarPath == null ? '点击头像选择图片' : '点击头像更换图片',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600], // 动态文本颜色
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
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87, // 动态标签颜色
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
            fillColor: isDark
                ? (enabled ? Colors.grey[800] : Colors.grey[900])
                : (enabled ? Colors.white : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: hintText ?? '请输入${label.replaceAll('*', '').trim()}',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          style: TextStyle(
            color: isDark
                ? (enabled ? Colors.white : Colors.grey[400])
                : (enabled ? Colors.black87 : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // 🎯 修改：弹力球开关组件
  Widget _buildCustomFormatSwitch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
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
                  '启用自定义格式', // 使用版本A的标题
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用自定义的格式化指令覆盖默认格式', // 版本A的描述文字
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 🎯 替换：弹力球开关（保持原有Switch所有功能，只改动画）
          _buildBouncySwitch(isDark: isDark),
        ],
      ),
    );
  }

// 🎯 新增：弹力球开关（修复版）
Widget _buildBouncySwitch({required bool isDark}) {
  return GestureDetector(
    onTapDown: (_) {
      // 按下时开始挤压动画（带弹簧效果）
      _switchAnimationController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
      );
    },
    onTapUp: (_) {
      // 松开时切换状态并回弹
      setState(() {
        _enableCustomFormat = !_enableCustomFormat;
      });
      _switchAnimationController.reverse();
    },
    onTapCancel: () {
      // 取消点击时也回弹
      _switchAnimationController.reverse();
    },
    child: SizedBox(
      width: 52, // Switch的标准宽度
      height: 32, // Switch的标准高度
      child: Stack(
        children: [
          // 轨道背景
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _enableCustomFormat
                  ? const Color(0xFFFF5A7E).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),

          // 弹力球滑块
          AnimatedBuilder(
            animation: _switchAnimationController,
            builder: (context, child) {
              // 弹力球挤压效果
              final squeeze = _switchAnimationController.value;
              final scaleX = 1.0 + squeeze * 0.3; // 水平拉伸30%
              final scaleY = 1.0 - squeeze * 0.4; // 垂直压缩40%

              // 🎯 修复1：调整位置，右边球不贴边
              // OFF时在左边(8px)，ON时在右边(22px)
              final basePosition = _enableCustomFormat ? 22.0 : 8.0;
              
              // 添加滑动动画的位移效果
              final extraOffset = squeeze * (_enableCustomFormat ? -1.5 : 1.5);
              final currentPosition = basePosition + extraOffset;

              return Positioned(
                left: currentPosition,
                top: _enableCustomFormat ? 3.0 : 5.0, // 🎯 ON时上移一点，OFF时下移一点
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  child: Container(
                    // 🎯 修复2：OFF小球，ON大球
                    width: _enableCustomFormat ? 26.0 : 22.0, // ON:26px, OFF:22px
                    height: _enableCustomFormat ? 26.0 : 22.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  // 🎯 关键修改：使用版本A的UI设计，保持版本B的双控制器逻辑
  Widget _buildCustomFormatSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 使用版本A的输入框设计，但保持版本B的双控制器逻辑
        TextField(
          controller: _enableCustomFormat
              ? _xmlFormatController // 开启时使用XML控制器
              : _plainPromptController, // 关闭时使用普通提示词控制器
          maxLines: 4,
          minLines: 3,
          enabled: true, // 始终保持启用，内容根据开关切换
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.grey[800]
                : (_enableCustomFormat ? Colors.white : Colors.grey[100]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: _enableCustomFormat
                ? '输入自定义格式指令...' // 版本A的提示文字
                : '输入普通对话格式指令...',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          style: TextStyle(
            color: isDark
                ? Colors.white
                : (_enableCustomFormat ? Colors.black87 : Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _enableCustomFormat
              ? '示例: "你是一位{{角色}}，请以{{风格}}的语气回复"' // 版本A的示例文字
              : '示例: "你是一位{{角色}}，请以{{对话}}的语气回复"',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? Colors.grey[900] : const Color(0xFFFFF8FA), // 动态背景
        appBar: AppBar(
          backgroundColor:
              isDark ? Colors.grey[900] : const Color(0xFFFFF8FA),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '编辑 AI 人设',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
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
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFFFF8FA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '编辑 AI 人设',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
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
              label: '简介',
              controller: _introController,
              maxLines: 4,
              required: true,
              hintText: '请输入简介（性格、爱好、职业等）',
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
                color: isDark ? Colors.grey[400] : Colors.grey[600], // 动态颜色
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
              hintText: '请输入开场白（对话开始时使用）',
            ),
            const SizedBox(
                height: 32), // 保持开场白底部到自定义格式中间的空白间距

            // 自定义格式开关 - 使用版本A的UI设计（已替换为弹力球）
            _buildCustomFormatSwitch(),
            const SizedBox(height: 16), // 使用版本A的间距

            // 🎯 关键修改：显示不同的输入框 - 使用版本A的UI设计
            _buildCustomFormatSection(),
            const SizedBox(height: 24),

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
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFFFF0F5), // 动态背景
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade800
                      : const Color(0xFFFFD1DC), // 使用 .shade800
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
                        color: isDark
                            ? Colors.pink[200]
                            : Colors.pink[300], // 动态图标颜色
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '提示',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.pink[200]
                              : const Color(0xFFD81B60), // 动态文本颜色
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
                      color: isDark ? Colors.grey[300] : Colors.grey[700], // 动态文本颜色
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
  _plainPromptController.dispose();
  _xmlFormatController.dispose();
_switchAnimationController.dispose(); // 🎯 去掉?号，因为现在不为空
  super.dispose();
}
}