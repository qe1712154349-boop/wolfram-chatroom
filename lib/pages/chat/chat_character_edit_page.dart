// lib/pages/chat/chat_character_edit_page.dart - 完整修改版本（集成主题）
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../app/ui_theme_manager.dart'; // 🎨 新增导入
import '../../utils/asset_picker_util.dart'; // 🆕 新增导入
import 'package:photo_manager/photo_manager.dart'; // 🆕 新增导入

// ════════════════════════════════════════════════════════════════════════════════
// 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴
// ⚠️⚠️⚠️ 重要：这是用户调试完毕的最终版本！不要修改！ ⚠️⚠️⚠️
//
// 🔴 焦点效果设计原则（用户已调试完毕）：
//   1. 草莓主题：所有输入框完全无焦点效果
//   2. 泡菜牛奶主题：普通输入框有焦点效果，但"启用自定义格式"下面的文本框无焦点
//   3. 开关开启时：无边框但有圆角（保持界面一致性）
//   4. 开关关闭时：使用主题边框，无焦点效果
//
// 🔴 任何AI都不能修改以下内容：
//   - _getFocusedBorderForTheme() 方法
//   - _buildCustomFormatSection() 中的 focusedBorder
//   - 任何与焦点边框相关的逻辑
//
// 🔴 用户已经反复调试，这是完美状态！
// 🔴 不要"优化"、不要"重构"、不要"改进"这些代码！
// 🔴 保持原样！
//
// 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴
// ════════════════════════════════════════════════════════════════════════════════

class ChatCharacterEditPage extends StatefulWidget {
  const ChatCharacterEditPage({super.key});

  @override
  State<ChatCharacterEditPage> createState() => _ChatCharacterEditPageState();
}

class _ChatCharacterEditPageState extends State<ChatCharacterEditPage> {
  final StorageService _storage = StorageService();

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

  // 🎨 新增：UI主题相关
  UITheme _uiTheme = UITheme.system;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _loadUITheme(); // 🎨 新增：加载UI主题
  }

  // 🎨 新增：加载UI主题
  Future<void> _loadUITheme() async {
    final themeString = await _storage.getUITheme();
    if (mounted) {
      setState(() {
        _uiTheme = UIThemeManager.fromString(themeString);
      });
    }
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

  // 🆕 修改：使用 wechat_assets_picker 替换 image_picker
  Future<void> _pickImageFromGallery() async {
    try {
      final AssetEntity? asset = await AssetPickerUtil.pickSingleImage(context);
      if (asset == null) return;

      setState(() => _isSaving = true);

      final file = await AssetPickerUtil.getFileFromAsset(asset);
      if (file == null) return;

      final newPath = await _storage.copyFileToAppDir(file.path);
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
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(60),
            child: InkWell(
              onTap: _isSaving ? null : _pickImageFromGallery,
              borderRadius: BorderRadius.circular(60),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor:
                        isDark ? Colors.grey[800] : const Color(0xFFFFD1DC),
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
          ),
          const SizedBox(height: 12),
          Text(
            _avatarPath == null ? '点击头像选择图片' : '点击头像更换图片',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 修改：根据主题构建边框的辅助方法
  InputBorder _getBorderForTheme() {
    if (_uiTheme == UITheme.strawberryCandy) {
      return UIThemeManager.buildTextFieldBorderStrawberryCandy(context);
    } else if (_uiTheme == UITheme.pickleMilk) {
      return UIThemeManager.buildTextFieldBorderPickleMilk(context);
    } else {
      // 系统：默认使用草莓糖心（无边框）
      return UIThemeManager.buildTextFieldBorderStrawberryCandy(context);
    }
  }

// 🎨 修改：根据主题构建焦点边框的辅助方法
// ════════════════════════════════════════════════════════════════════════════════
// 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴
// ⚠️⚠️⚠️ 终极防修改区域 - 用户调试完毕的焦点逻辑 ⚠️⚠️⚠️
//
// 🔴 用户明确设计要求：
//   - 草莓主题：完全无焦点效果（焦点边框=普通边框）
//   - 泡菜牛奶主题：保持原有的焦点效果（不要动！）
//   - 系统主题：默认使用草莓主题逻辑
//
// 🔴 这是用户经过多次调试后的最终版本！
// 🔴 任何AI都不能修改这个方法，保持原样！
// 🔴 不要"优化"，不要"改进"，不要"重构"！
// 🔴 用户已经调试完毕，这是完美状态！
//
// 🔴 修改后果：如果修改这里，会导致界面焦点效果混乱，用户需要重新调试！
// 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴 🔴
// ════════════════════════════════════════════════════════════════════════════════
  InputBorder _getFocusedBorderForTheme() {
    if (_uiTheme == UITheme.strawberryCandy) {
      // 🍓 草莓糖心主题：焦点边框与普通边框相同（无焦点效果）
      // 🚫 禁止返回不同的焦点边框！
      // 🚫 禁止添加任何焦点高亮效果！
      return _getBorderForTheme(); // 直接返回普通边框
    } else if (_uiTheme == UITheme.pickleMilk) {
      // 🥒 泡菜牛奶主题：保持原有的焦点效果
      // ✅ 保持原样，不要修改！
      return UIThemeManager.buildTextFieldFocusedBorderPickleMilk(context);
    } else {
      // 系统主题：默认使用草莓糖心（无焦点）
      return _getBorderForTheme();
    }
  }

// 🎨 修改：根据主题获取填充颜色
  Color? _getFillColor(bool isDark, bool enabled) {
    // 处理空值情况
    Color? darkEnabledColor = Colors.grey[800];
    Color? darkDisabledColor = Colors.grey[900];
    Color lightEnabledColor = Colors.white;
    Color? lightDisabledColor = Colors.grey[100];

    if (isDark) {
      return enabled
          ? (darkEnabledColor ?? Colors.grey[800])
          : (darkDisabledColor ?? Colors.grey[900]);
    } else {
      return enabled ? lightEnabledColor : lightDisabledColor;
    }
  }

  // 🎨 修改：根据主题获取背景颜色
  Color _getBackgroundColor(bool isDark) {
    if (_uiTheme == UITheme.strawberryCandy) {
      return isDark ? Colors.grey[900]! : const Color(0xFFFFF8FA);
    } else {
      return isDark ? const Color(0xFF121212) : const Color(0xFFFDF7F7);
    }
  }

  // 🎨 修改：根据主题获取卡片颜色
  Color _getCardColor(bool isDark) {
    if (_uiTheme == UITheme.strawberryCandy) {
      return isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF0F5);
    } else {
      return isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8FF);
    }
  }

  // 🎨 修改：根据主题获取边框颜色
  Color _getCardBorderColor(bool isDark) {
    if (_uiTheme == UITheme.strawberryCandy) {
      return isDark ? Colors.grey[800]! : const Color(0xFFFFD1DC);
    } else {
      return isDark ? Colors.grey[700]! : const Color(0xFFE8D8DD);
    }
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
                color: isDark ? Colors.white : Colors.black87,
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
        Material(
          color: Colors.transparent,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 3,
            enabled: enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: _getFillColor(isDark, enabled),
              // 🎨 根据主题动态设置边框
              border: _getBorderForTheme(),
              enabledBorder: _getBorderForTheme(),
              focusedBorder: _getFocusedBorderForTheme(),
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
        ),
      ],
    );
  }

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
                  '启用自定义格式',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用自定义的格式化指令覆盖默认格式',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 🎯 修复：使用正确的Switch配置
          Switch(
            value: _enableCustomFormat,
            onChanged: (value) {
              setState(() {
                _enableCustomFormat = value;
              });
            },
            // 🎨 根据主题设置Switch颜色
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              final primaryColor = _uiTheme == UITheme.strawberryCandy
                  ? const Color(0xFFFF5A7E)
                  : const Color(0xFFFF5A7E);
              if (states.contains(WidgetState.selected)) {
                return primaryColor.withValues(alpha: 0.5);
              }
              return Colors.grey.withValues(alpha: 0.3);
            }),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFormatSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 根据主题决定圆角
    double getBorderRadius(bool isForNoBorder) {
      if (_uiTheme == UITheme.strawberryCandy) {
        // 草莓主题：统一为7
        return 7.0;
      } else if (_uiTheme == UITheme.pickleMilk) {
        // 牛奶主题：开关我修改完毕了，别动我的圆角数值
        return isForNoBorder ? 5.0 : 3.5;
      } else {
        // 系统主题：默认用草莓主题
        return 7.0;
      }
    }

    // 开关开启时的样式（根据主题处理）
    InputBorder getNoBorderWithRadius() {
      final borderRadius = getBorderRadius(true);

      if (_uiTheme == UITheme.strawberryCandy) {
        // 🍓 草莓主题：开关开启时添加 #F1D7E0 边框
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 255, 207, 224), // #改了边框颜色
            width: 1.2, //改草莓开启自定义格式的边框px和颜色
          ),
        );
      } else {
        // 其他主题：保持原来的无边框样式
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        );
      }
    }

    final noBorderWithRadius = getNoBorderWithRadius();

    // 处理开关关闭时的边框
    InputBorder getSmallerBorder() {
      final themeBorder = _getBorderForTheme();
      final borderRadius = getBorderRadius(false); // 开关关闭的圆角

      if (themeBorder is OutlineInputBorder) {
        // 如果是 OutlineInputBorder，修改圆角
        return themeBorder.copyWith(
          borderRadius: BorderRadius.circular(borderRadius),
        );
      } else {
        // 如果不是 OutlineInputBorder（比如草莓主题的 InputBorder.none），创建一个新的
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1.0,
          ),
        );
      }
    }

    final smallerBorder = getSmallerBorder();

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _enableCustomFormat
                ? _xmlFormatController
                : _plainPromptController,
            maxLines: 4,
            minLines: 3,
            enabled: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? Colors.grey[800]
                  : (_enableCustomFormat ? Colors.white : Colors.grey[100]),
              border: _enableCustomFormat ? noBorderWithRadius : smallerBorder,
              enabledBorder:
                  _enableCustomFormat ? noBorderWithRadius : smallerBorder,
              focusedBorder:
                  _enableCustomFormat ? noBorderWithRadius : smallerBorder,
              contentPadding: const EdgeInsets.all(16),
              hintText:
                  _enableCustomFormat ? '请输入XML格式指令...' : '请输入普通对话格式指令...',
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
                ? '示例: "你是一位{{角色}}，请以{{风格}}的语气回复"'
                : '示例: "你是一位{{角色}}，请以{{对话}}的语气回复"',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 🎨 根据主题获取背景颜色
    final backgroundColor = _getBackgroundColor(isDark);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
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
      // 🎯 关键修复：确保正确的Material上下文
      body: Builder(
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 32),

                  _buildTextField(
                    label: '昵称',
                    controller: _nicknameController,
                    required: true,
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    label: '简介',
                    controller: _introController,
                    maxLines: 4,
                    required: true,
                    hintText: '请输入简介（性格、爱好、职业等）',
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    label: '附加设定（私密）',
                    controller: _privateSettingController,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这些设定会影响AI的性格和行为，不会直接显示给用户',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    label: '开场白（对话开始时使用）',
                    controller: _openingController,
                    maxLines: 3,
                    hintText: '请输入开场白（对话开始时使用）',
                  ),
                  const SizedBox(height: 32),

                  _buildCustomFormatSwitch(),
                  const SizedBox(height: 16),

                  _buildCustomFormatSection(),
                  const SizedBox(height: 24),

                  // 🎨 根据主题设置按钮样式
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCharacterData,
                      style: UIThemeManager.getButtonStyle(context, _uiTheme),
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F6), // 🚫 AI别动这个颜色！#FFF1F6
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF3D7E0), // 🚫 AI别动这个颜色！#F3D7E0
                        width: 1, // 🚫 AI别动这个宽度！就是1px
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color:
                                  isDark ? Colors.pink[200] : Colors.pink[300],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '提示',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.pink[200]
                                    : const Color(0xFFD81B60),
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
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
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
        },
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
    super.dispose();
  }
}
