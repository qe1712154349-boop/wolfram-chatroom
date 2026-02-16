// lib/pages/me/settings_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_config.dart';
import '../../services/storage_service.dart';
import '../../theme/theme.dart' as app_theme;
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final StorageService _storage = StorageService();
  bool _developerMode = false;
  bool? _narrationCentered;

  // API 配置变量
  bool _isCustomMode = true;
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  List<String> _availableModels = [];
  String _selectedModel = '';
  String _testStatus = '';
  String _testMessage = '';

  Timer? _testStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadDeveloperMode();
    _loadNarrationCentered();
    _loadApiConfig();
  }

  @override
  void dispose() {
    _testStatusTimer?.cancel();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _clearTestStatusAfterDelay() {
    _testStatusTimer?.cancel();
    _testStatusTimer = Timer(const Duration(milliseconds: 1710), () {
      if (mounted) {
        setState(() {
          _testStatus = '';
          _testMessage = '';
        });
      }
    });
  }

  Future<void> _loadApiConfig() async {
    final currentId = await ApiConfig.getCurrentProviderId();
    final currentModel = await ApiConfig.getCurrentModel();

    setState(() {
      _selectedModel = currentModel;
      _isCustomMode = currentId == 'custom';
    });

    if (_isCustomMode) {
      final prefs = await SharedPreferences.getInstance();
      _baseUrlController.text =
          prefs.getString('custom_base_url') ?? 'https://api.deepseek.com';
      _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
      _modelController.text =
          prefs.getString('custom_model') ?? 'deepseek-chat';
      _selectedModel = _modelController.text;
    } else {
      final providers = await ApiConfig.loadProviders();
      final provider = providers.firstWhere(
        (p) => p.id == currentId,
        orElse: () => ApiConfig.defaultProviders.first,
      );

      _baseUrlController.text = provider.baseUrl;
      _apiKeyController.text = provider.apiKey;
      _availableModels = provider.models;
      if (_availableModels.isNotEmpty &&
          !_availableModels.contains(_selectedModel)) {
        _selectedModel = _availableModels.first;
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_isCustomMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', _baseUrlController.text.trim());
      await prefs.setString('custom_api_key', _apiKeyController.text.trim());
      await prefs.setString('custom_model', _selectedModel);
    }

    final currentId =
        _isCustomMode ? 'custom' : (await ApiConfig.getCurrentProviderId());
    await ApiConfig.setCurrent(currentId, _selectedModel);

    if (!_isCustomMode) {
      final providers = await ApiConfig.loadProviders();
      final index = providers.indexWhere((p) => p.id == currentId);
      if (index != -1) {
        await ApiConfig.updateProvider(
          id: currentId,
          apiKey: _apiKeyController.text.trim(),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置已保存'),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testStatus = '';
      _testMessage = '测试中...';
    });

    try {
      final baseUrl = _baseUrlController.text.trim();
      final apiKey = _apiKeyController.text.trim();

      if (apiKey.isEmpty) throw Exception('API Key 不能为空');
      if (baseUrl.isEmpty) throw Exception('Base URL 不能为空');

      final url = Uri.parse('$baseUrl/models');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String newTestMessage = '连接成功！';
        List<String> newModels = _availableModels;

        try {
          final data = jsonDecode(response.body);
          final models = (data['data'] as List<dynamic>?)
                  ?.map((e) => e['id'].toString())
                  .toList() ??
              [];

          if (models.isNotEmpty) {
            newModels = models;
            if (!_isCustomMode) {
              final currentId = await ApiConfig.getCurrentProviderId();
              await ApiConfig.updateProvider(
                id: currentId,
                models: models,
              );
            }
          }
        } catch (parseError) {
          debugPrint('模型列表解析失败: $parseError');
        }

        setState(() {
          _testStatus = 'valid';
          _testMessage = newTestMessage;
          _availableModels = newModels;
          if (newModels.isNotEmpty && !_selectedModel.isNotEmpty) {
            _selectedModel = newModels.first;
          }
        });

        await _saveConfig();

        _clearTestStatusAfterDelay();
      } else {
        setState(() {
          _testStatus = 'invalid';
          _testMessage =
              '失败: ${response.statusCode} - ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}';
        });

        _clearTestStatusAfterDelay();
      }
    } catch (e) {
      setState(() {
        _testStatus = 'invalid';
        _testMessage = '错误: $e';
      });

      _clearTestStatusAfterDelay();
    }
  }

  Future<void> _loadDeveloperMode() async {
    final mode = await _storage.getDeveloperMode();
    if (mounted) {
      setState(() {
        _developerMode = mode;
      });
    }
  }

  Future<void> _loadNarrationCentered() async {
    final centered = await _storage.getNarrationCentered();
    if (mounted) {
      setState(() {
        _narrationCentered = centered;
      });
    }
  }

  Widget _buildColorModeSelector() {
    final sem = context.sem;
    final currentMode = ref.watch(app_theme.appThemeProvider).themeMode;

    final modes = ['light', 'dark', 'system'];
    final modeLabels = ['亮色', '暗色', '跟随系统'];
    final icons = [Icons.light_mode, Icons.dark_mode, Icons.settings_suggest];

    final currentIndex = modes.indexOf(currentMode.name.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('色彩模式', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: sem.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: List.generate(3, (index) {
              final isSelected = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final newMode = app_theme.AppThemeMode.values[index];
                    await ref
                        .read(app_theme.appThemeProvider.notifier)
                        .updateThemeMode(newMode);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已切换到${modeLabels[index]}模式')),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? sem.primary : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icons[index],
                              color: isSelected
                                  ? Colors.white
                                  : sem.textSecondary),
                          const SizedBox(width: 8),
                          Text(modeLabels[index],
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : sem.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeControlPanel() {
    final sem = context.sem;
    final isCurrentlyDark = ref.watch(app_theme.appThemeProvider).isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主题操作',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        // 重置当前模式
        Container(
          decoration: BoxDecoration(
            color: sem.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.refresh,
              color: sem.primary,
            ),
            title: Text('重置当前模式', style: TextStyle(color: sem.textPrimary)),
            subtitle: Text(
              isCurrentlyDark ? '将暗色主题恢复为默认' : '将亮色主题恢复为默认',
              style: TextStyle(color: sem.textSecondary),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认重置?'),
                  content: Text(
                    isCurrentlyDark
                        ? '暗色主题将恢复为默认，亮色主题不受影响'
                        : '亮色主题将恢复为默认，暗色主题不受影响',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(app_theme.appThemeProvider.notifier)
                            .resetCurrentBrightness();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isCurrentlyDark ? '已重置暗色模式' : '已重置亮色模式',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sem.error,
                      ),
                      child: const Text('重置',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 重置所有主题
        Container(
          decoration: BoxDecoration(
            color: sem.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.settings_backup_restore,
              color: sem.primary,
            ),
            title: Text('重置所有主题', style: TextStyle(color: sem.textPrimary)),
            subtitle:
                Text('亮色和暗色都恢复为默认', style: TextStyle(color: sem.textSecondary)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认重置所有?'),
                  content: const Text('亮色和暗色主题都将恢复为默认'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(app_theme.appThemeProvider.notifier)
                            .resetAll();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已重置所有主题'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sem.error,
                      ),
                      child: const Text('重置所有',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUIThemeSelector() {
    final currentTheme = ref.watch(app_theme.appThemeProvider).currentUITheme;

    return DropdownButtonFormField<app_theme.UIThemeType>(
      initialValue: currentTheme,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '界面主题',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: app_theme.UIThemeType.values.map((theme) {
        return DropdownMenuItem<app_theme.UIThemeType>(
          value: theme,
          child: Row(
            children: [
              Icon(theme.icon),
              const SizedBox(width: 12),
              Text(theme.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) async {
        if (value != null) {
          await ref
              .read(app_theme.appThemeProvider.notifier)
              .updateUITheme(value);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已切换到${value.displayName}')),
            );
          }
        }
      },
    );
  }

  Widget _buildApiConfigSection() {
    final sem = context.sem;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API 配置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: sem.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<ApiProvider>>(
            future: ApiConfig.loadProviders(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final providers = snapshot.data!;
              final currentIdFuture = ApiConfig.getCurrentProviderId();

              return FutureBuilder<String>(
                future: currentIdFuture,
                builder: (context, currentSnap) {
                  String? currentId = currentSnap.data;
                  if (currentId == null ||
                      !providers.any((p) => p.id == currentId)) {
                    currentId = 'custom';
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: currentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: sem.border),
                      ),
                      labelText: 'API 来源',
                      labelStyle: TextStyle(color: sem.textSecondary),
                      filled: true,
                      fillColor: sem.surface,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: sem.border),
                      ),
                    ),
                    items: [
                      ...providers.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.name,
                              style: TextStyle(color: sem.textPrimary),
                            ),
                          )),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('自定义 (兼容 OpenAI)',
                            style: TextStyle(color: sem.textPrimary)),
                      ),
                    ],
                    onChanged: (newValue) async {
                      if (newValue == null) return;

                      if (newValue == 'custom') {
                        final prefs = await SharedPreferences.getInstance();
                        setState(() {
                          _isCustomMode = true;
                          _baseUrlController.text =
                              prefs.getString('custom_base_url') ?? '';
                          _apiKeyController.text =
                              prefs.getString('custom_api_key') ?? '';
                          _modelController.text =
                              prefs.getString('custom_model') ?? '';
                          _selectedModel = _modelController.text;
                          _availableModels = [];
                        });
                      } else {
                        final selected =
                            providers.firstWhere((p) => p.id == newValue);
                        setState(() {
                          _isCustomMode = false;
                          _baseUrlController.text = selected.baseUrl;
                          _apiKeyController.text = selected.apiKey;
                          _availableModels = selected.models;
                          if (_availableModels.isNotEmpty &&
                              !_availableModels.contains(_selectedModel)) {
                            _selectedModel = _availableModels.first;
                          }
                        });
                        await ApiConfig.setCurrent(newValue, _selectedModel);
                      }
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            style: TextStyle(color: sem.textPrimary),
            decoration: InputDecoration(
              labelText: 'Base URL',
              labelStyle: TextStyle(color: sem.textSecondary),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: sem.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: sem.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: sem.primary),
              ),
              hintText: 'https://api.example.com/v1',
              hintStyle: TextStyle(color: sem.textHint),
              filled: true,
              fillColor: sem.surface,
            ),
            enabled: _isCustomMode,
            readOnly: !_isCustomMode,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: TextStyle(color: sem.textPrimary),
            decoration: InputDecoration(
              labelText: 'API Key',
              labelStyle: TextStyle(color: sem.textSecondary),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: sem.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: sem.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: sem.primary),
              ),
              filled: true,
              fillColor: sem.surface,
            ),
          ),
          const SizedBox(height: 12),
          if (_availableModels.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedModel.isNotEmpty ? _selectedModel : null,
              hint: Text('选择模型', style: TextStyle(color: sem.textHint)),
              isExpanded: true,
              dropdownColor: sem.surface,
              style: TextStyle(color: sem.textPrimary),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: sem.border),
                ),
                labelText: '模型',
                labelStyle: TextStyle(color: sem.textSecondary),
                filled: true,
                fillColor: sem.surface,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: sem.border),
                ),
              ),
              items: _availableModels
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child:
                            Text(m, style: TextStyle(color: sem.textPrimary)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedModel = value);
              },
            )
          else if (_isCustomMode)
            TextField(
              controller: _modelController,
              style: TextStyle(color: sem.textPrimary),
              decoration: InputDecoration(
                labelText: '模型名（手动输入）',
                labelStyle: TextStyle(color: sem.textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: sem.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: sem.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: sem.primary),
                ),
                helperText: '如 deepseek-chat',
                helperStyle: TextStyle(color: sem.textHint),
                filled: true,
                fillColor: sem.surface,
              ),
              onChanged: (val) => setState(() => _selectedModel = val),
            )
          else
            Text(
              '请选择 API 来源后自动加载模型',
              style: TextStyle(color: sem.textSecondary),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sem.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saveConfig,
              child: const Text('保存配置',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: _testConnection,
                child: Text('测试连接',
                    style: TextStyle(color: sem.primary, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _testStatus == 'valid'
                      ? context.themeColor(app_theme.ColorSemantic.success)
                      : (_testStatus == 'invalid'
                          ? sem.error
                          : sem.textSecondary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _testMessage,
                  style: TextStyle(
                    color: _testStatus == 'valid'
                        ? context.themeColor(app_theme.ColorSemantic.success)
                        : (_testStatus == 'invalid' ? sem.error : null),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;

    return Scaffold(
      backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
      appBar: AppBar(
        title: const Text("设置"),
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        foregroundColor: context.themeColor(app_theme.ColorSemantic.appBarText),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ----- 1. API 配置 -----
          _buildApiConfigSection(),

          // ----- 2. 外观设置 -----
          Text("外观设置", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildUIThemeSelector(),
          const SizedBox(height: 24),
          _buildColorModeSelector(),
          const SizedBox(height: 24),

          // ----- 2.5. 主题操作 -----
          _buildThemeControlPanel(),
          const SizedBox(height: 24),

          // ----- 3. 界面设置 -----
          Text("界面设置", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: sem.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_narrationCentered == null)
                  const ListTile(
                    title: Text("旁白居中显示"),
                    subtitle: Text("加载中..."),
                    trailing: CircularProgressIndicator(),
                  )
                else
                  SwitchListTile(
                    title: const Text("旁白居中显示"),
                    subtitle: const Text("开启为居中对齐，关闭为左对齐（小说风格）"),
                    value: _narrationCentered!,
                    onChanged: (value) async {
                      setState(() => _narrationCentered = value);
                      await _storage.saveNarrationCentered(value);
                    },
                    activeThumbColor: context
                        .themeColor(app_theme.ColorSemantic.switchActive),
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text("开发者模式"),
                  subtitle: const Text("开启后可查看详细错误信息"),
                  value: _developerMode,
                  onChanged: (value) async {
                    setState(() => _developerMode = value);
                    await _storage.saveDeveloperMode(value);
                  },
                  activeThumbColor:
                      context.themeColor(app_theme.ColorSemantic.switchActive),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----- 4. 消息通知 -----
          Text("消息通知", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: sem.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading:
                  Icon(Icons.notifications_outlined, color: sem.textSecondary),
              title: Text("新消息通知", style: TextStyle(color: sem.textPrimary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "前往系统设置",
                    style: TextStyle(
                      color: sem.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: sem.textSecondary,
                  ),
                ],
              ),
              onTap: () async {
                await openAppSettings();
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
