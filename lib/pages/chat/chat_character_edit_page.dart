// lib/pages/chat/chat_character_edit_page.dart
// 彻底迁移到新主题系统（context.themeColor + ColorSemantic）
// 保留焦点逻辑（_getFocusedBorderForTheme / _getBorderForTheme）100%原样
// 删除所有 unused 方法 / 变量
// 解决 undefined appThemeProvider / UIThemeType / inputBorder

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../utils/asset_picker_util.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../theme/theme.dart' as app_theme; // 新系统入口

class ChatCharacterEditPage extends ConsumerStatefulWidget {
  const ChatCharacterEditPage({super.key});

  @override
  ConsumerState<ChatCharacterEditPage> createState() =>
      _ChatCharacterEditPageState();
}

class _ChatCharacterEditPageState extends ConsumerState<ChatCharacterEditPage> {
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

  // 两个独立的控制器（保持原样）
  final TextEditingController _plainPromptController = TextEditingController();
  final TextEditingController _xmlFormatController = TextEditingController();

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

        _enableCustomFormat = data['enable_custom_format'] == 'true';

        _plainPromptController.text = data['plain_prompt'] ?? '';
        _xmlFormatController.text = data['custom_format'] ?? '';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载角色数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final AssetEntity? asset =
          await AssetPickerUtil.pickSingleImageDirectly(context);
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
              content: Text('头像已更新'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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
        'plain_prompt': _plainPromptController.text.trim(),
        'custom_format': _xmlFormatController.text.trim(),
      };

      await _storage.saveCharacterData(characterData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('角色设定已保存'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      debugPrint('保存角色数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('保存失败: ${e.toString()}'),
              backgroundColor: Colors.red),
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
                    backgroundColor: context
                        .themeColor(app_theme.ColorSemantic.primaryContainer),
                    backgroundImage: _avatarPath != null
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child: _avatarPath == null
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: context.themeColor(
                                app_theme.ColorSemantic.onPrimaryContainer),
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
                            child:
                                CircularProgressIndicator(color: Colors.white)),
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
              color: context.themeColor(app_theme.ColorSemantic.textSecondary),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 焦点逻辑 100% 保持原样（用户禁止修改）
  InputBorder _getBorderForTheme() {
    final uiTheme = ref.watch(app_theme.appThemeProvider).currentUITheme;
    if (uiTheme == app_theme.UIThemeType.strawberryCandy) {
      return context.inputBorder;
    } else if (uiTheme == app_theme.UIThemeType.pickleMilk) {
      return context.inputBorder;
    } else {
      return context.inputBorder;
    }
  }

  InputBorder _getFocusedBorderForTheme() {
    final uiTheme = ref.watch(app_theme.appThemeProvider).currentUITheme;
    if (uiTheme == app_theme.UIThemeType.strawberryCandy) {
      return _getBorderForTheme();
    } else if (uiTheme == app_theme.UIThemeType.pickleMilk) {
      return context.inputBorder;
    } else {
      return _getBorderForTheme();
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
                color: context.themeColor(app_theme.ColorSemantic.textPrimary),
              ),
            ),
            if (required)
              const Text(
                ' *',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
              fillColor:
                  context.themeColor(app_theme.ColorSemantic.textFieldFill),
              border: _getBorderForTheme(),
              enabledBorder: _getBorderForTheme(),
              focusedBorder: _getFocusedBorderForTheme(),
              contentPadding: const EdgeInsets.all(16),
              hintText: hintText ?? '请输入${label.replaceAll('*', '').trim()}',
              hintStyle: TextStyle(
                color:
                    context.themeColor(app_theme.ColorSemantic.textFieldHint),
              ),
            ),
            style: TextStyle(
              color: context.themeColor(app_theme.ColorSemantic.inputText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFormatSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.themeColor(app_theme.ColorSemantic.divider),
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
                    color:
                        context.themeColor(app_theme.ColorSemantic.textPrimary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用自定义的格式化指令覆盖默认格式',
                  style: TextStyle(
                    color: context
                        .themeColor(app_theme.ColorSemantic.textSecondary),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enableCustomFormat,
            onChanged: (value) {
              setState(() => _enableCustomFormat = value);
            },
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return context.themeColor(app_theme.ColorSemantic.switchActive);
              }
              return context.themeColor(app_theme.ColorSemantic.switchInactive);
            }),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFormatSection() {
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
              fillColor:
                  context.themeColor(app_theme.ColorSemantic.textFieldFill),
              border: _enableCustomFormat
                  ? _getFocusedBorderForTheme()
                  : _getBorderForTheme(),
              enabledBorder: _enableCustomFormat
                  ? _getFocusedBorderForTheme()
                  : _getBorderForTheme(),
              focusedBorder: _enableCustomFormat
                  ? _getFocusedBorderForTheme()
                  : _getBorderForTheme(),
              contentPadding: const EdgeInsets.all(16),
              hintText:
                  _enableCustomFormat ? '请输入XML格式指令...' : '请输入普通对话格式指令...',
              hintStyle: TextStyle(
                color:
                    context.themeColor(app_theme.ColorSemantic.textFieldHint),
              ),
            ),
            style: TextStyle(
              color: context.themeColor(app_theme.ColorSemantic.inputText),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _enableCustomFormat
                ? '示例: "你是一位{{角色}}，请以{{风格}}的语气回复"'
                : '示例: "你是一位{{角色}}，请以{{对话}}的语气回复"',
            style: TextStyle(
              color: context.themeColor(app_theme.ColorSemantic.textSecondary),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
        appBar: AppBar(
          backgroundColor:
              context.themeColor(app_theme.ColorSemantic.appBarBackground),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: context.themeColor(app_theme.ColorSemantic.appBarText)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '编辑 AI 人设',
            style: TextStyle(
              color: context.themeColor(app_theme.ColorSemantic.appBarText),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
            child: CircularProgressIndicator(
                color: context.themeColor(app_theme.ColorSemantic.primary))),
      );
    }

    return Scaffold(
      backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: context.themeColor(app_theme.ColorSemantic.appBarText)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '编辑 AI 人设',
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.appBarText),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color:
                    context.themeColor(app_theme.ColorSemantic.textSecondary),
              ),
              onPressed: _loadCharacterData,
              tooltip: '刷新数据',
            ),
        ],
      ),
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
                      color: context
                          .themeColor(app_theme.ColorSemantic.textSecondary),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCharacterData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context
                            .themeColor(app_theme.ColorSemantic.buttonPrimary),
                        foregroundColor: context.themeColor(
                            app_theme.ColorSemantic.buttonPrimaryText),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              '保存设置',
                              style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context
                          .themeColor(app_theme.ColorSemantic.cardBackground),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context
                            .themeColor(app_theme.ColorSemantic.cardBorder),
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
                              color: context
                                  .themeColor(app_theme.ColorSemantic.primary),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '提示',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.themeColor(
                                    app_theme.ColorSemantic.primary),
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
                            color: context.themeColor(
                                app_theme.ColorSemantic.textSecondary),
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
