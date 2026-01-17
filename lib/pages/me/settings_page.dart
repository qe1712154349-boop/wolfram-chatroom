// lib/pages/me/settings_page.dart - 完整替换
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_config.dart';
import '../../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  bool _developerMode = false;
  bool? _narrationCentered;  // 改为 nullable，初始 null 表示未加载
  String? _themeSetting;     // 新增：三状态主题设置 'light', 'dark', 'system'
  
  // API 配置相关变量
  bool _isCustomMode = true; // 默认自定义
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  List<String> _availableModels = [];
  String _selectedModel = '';
  String _testStatus = ''; // 'valid', 'invalid', ''
  String _testMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDeveloperMode();
    _loadNarrationCentered();
    _loadApiConfig();
    _loadThemeSetting();  // 修改：改为 _loadThemeSetting
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

  Future<void> _loadThemeSetting() async {
    final themeMode = await _storage.getThemeMode();
    if (mounted) {
      setState(() {
        _themeSetting = themeMode;
      });
    }
  }

  Future<void> _loadApiConfig() async {
    // 加载当前 provider 设置
    final currentId = await ApiConfig.getCurrentProviderId();
    final currentModel = await ApiConfig.getCurrentModel();
    
    setState(() {
      _selectedModel = currentModel;
      _isCustomMode = currentId == 'custom';
    });
    
    // 如果是自定义模式，加载自定义配置
    if (_isCustomMode) {
      final prefs = await SharedPreferences.getInstance();
      _baseUrlController.text = prefs.getString('custom_base_url') ?? 'https://api.deepseek.com';
      _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
      _modelController.text = prefs.getString('custom_model') ?? 'deepseek-chat';
      _selectedModel = _modelController.text;
    } else {
      // 预设模式：加载预设 provider
      final providers = await ApiConfig.loadProviders();
      final provider = providers.firstWhere(
        (p) => p.id == currentId,
        orElse: () => ApiConfig.defaultProviders.first,
      );
      
      _baseUrlController.text = provider.baseUrl;
      _apiKeyController.text = provider.apiKey;
      _availableModels = provider.models;
      if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
        _selectedModel = _availableModels.first;
      }
    }
  }

  Future<void> _saveConfig() async {
    // 保存逻辑：如果是自定义，保存到 prefs
    if (_isCustomMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', _baseUrlController.text.trim());
      await prefs.setString('custom_api_key', _apiKeyController.text.trim());
      await prefs.setString('custom_model', _selectedModel);
    }
    
    // 统一保存当前 providerId 和 model
    final currentId = _isCustomMode ? 'custom' : (await ApiConfig.getCurrentProviderId());
    await ApiConfig.setCurrent(currentId, _selectedModel);
    
    // 更新 preset 的 API Key
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
        SnackBar(
          content: const Text('配置已保存'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    // 先把 UI 置为"测试中"（同步）
    setState(() {
      _testStatus = '';
      _testMessage = '测试中...';
    });

    try {
      final baseUrl = _baseUrlController.text.trim();
      final apiKey = _apiKeyController.text.trim();

      if (apiKey.isEmpty) {
        throw Exception('API Key 不能为空');
      }

      if (baseUrl.isEmpty) {
        throw Exception('Base URL 不能为空');
      }

      final url = Uri.parse('$baseUrl/models');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 先在 setState 外面处理所有 await 操作
        String newTestMessage = '连接成功！';
        List<String> newModels = _availableModels;

        try {
          final data = jsonDecode(response.body);
          final models = (data['data'] as List<dynamic>?)
              ?.map((e) => e['id'].toString())
              .toList() ?? [];

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
          // 解析失败不影响连接成功状态
          debugPrint('模型列表解析失败: $parseError');
        }

        // 所有异步操作完成后，再统一更新 UI（同步）
        setState(() {
          _testStatus = 'valid';
          _testMessage = newTestMessage;
          _availableModels = newModels;
          if (newModels.isNotEmpty && !_selectedModel.isNotEmpty) {
            _selectedModel = newModels.first;
          }
        });

        // 成功后自动保存
        await _saveConfig();
      } else {
        setState(() {
          _testStatus = 'invalid';
          _testMessage = '失败: ${response.statusCode} - ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _testStatus = 'invalid';
        _testMessage = '错误: $e';
      });
    }
  }

  Future<void> _saveNarrationCentered(bool value) async {
    await _storage.saveNarrationCentered(value);
  }

  // 新增：构建主题选择器
  Widget _buildThemeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '主题设置',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // 选项1：强制亮色
          RadioListTile<String>(
            title: Text(
              '亮色模式',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              '始终使用亮色主题',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            value: 'light',
            groupValue: _themeSetting,
            onChanged: (value) async {
              setState(() => _themeSetting = value);
              await _storage.saveThemeMode('light');
              _showRestartDialog();
            },
            activeColor: const Color(0xFFFF5A7E),
          ),
          
          // 选项2：强制暗色
          RadioListTile<String>(
            title: Text(
              '暗色模式',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              '始终使用暗色主题',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            value: 'dark',
            groupValue: _themeSetting,
            onChanged: (value) async {
              setState(() => _themeSetting = value);
              await _storage.saveThemeMode('dark');
              _showRestartDialog();
            },
            activeColor: const Color(0xFFFF5A7E),
          ),
          
          // 选项3：跟随系统
          RadioListTile<String>(
            title: Text(
              '跟随系统',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              '根据系统设置自动切换',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            value: 'system',
            groupValue: _themeSetting,
            onChanged: (value) async {
              setState(() => _themeSetting = value);
              await _storage.saveThemeMode('system');
              _showRestartDialog();
            },
            activeColor: const Color(0xFFFF5A7E),
          ),
        ],
      ),
    );
  }

  // 重启提示对话框
  void _showRestartDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(
          '主题已更改',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          '需要重启应用才能使主题更改生效。\n请关闭应用后重新打开。',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '知道了',
              style: TextStyle(color: const Color(0xFFFF5A7E)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060405) : const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("设置"),
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================== API 配置 ====================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API 配置',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // 1. 下拉菜单：选择 API 来源
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
                        if (currentId == null || !providers.any((p) => p.id == currentId)) {
                          currentId = 'custom'; // 默认自定义
                        }

                        return DropdownButtonFormField<String>(
                          value: currentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                              ),
                            ),
                            labelText: 'API 来源',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                              ),
                            ),
                          ),
                          items: [
                            ...providers.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                )),
                            const DropdownMenuItem(
                              value: 'custom',
                              child: Text('自定义 (兼容 OpenAI)'),
                            ),
                          ],
                          onChanged: (newValue) async {  // 修复：添加 async
                            if (newValue == null) return;

                            if (newValue == 'custom') {
                              // 自定义模式：清空或保留上次输入
                              final prefs = await SharedPreferences.getInstance();
                              setState(() {
                                _isCustomMode = true;
                                _baseUrlController.text = prefs.getString('custom_base_url') ?? '';
                                _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
                                _modelController.text = prefs.getString('custom_model') ?? '';
                                _selectedModel = _modelController.text;
                                _availableModels = [];
                              });
                            } else {
                              // 预设模式：填充并锁定
                              final selected = providers.firstWhere((p) => p.id == newValue);
                              setState(() {
                                _isCustomMode = false;
                                _baseUrlController.text = selected.baseUrl;
                                _apiKeyController.text = selected.apiKey;
                                _availableModels = selected.models;
                                if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
                                  _selectedModel = _availableModels.first;
                                }
                              });
                              // 保存当前选择
                              await ApiConfig.setCurrent(newValue, _selectedModel);
                            }
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 2. Base URL（自定义可编辑，预设锁定）
                TextField(
                  controller: _baseUrlController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFFFF5A7E),
                      ),
                    ),
                    hintText: 'https://api.example.com/v1',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  ),
                  enabled: _isCustomMode, // 预设模式下禁用（锁定）
                  readOnly: !_isCustomMode,
                ),
                const SizedBox(height: 12),

                // 3. API Key（一直可编辑）
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: const Color(0xFFFF5A7E),
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Model（下拉或手动输入）
                if (_availableModels.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedModel.isNotEmpty ? _selectedModel : null,
                    hint: Text(
                      '选择模型',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                      labelText: '模型',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                    ),
                    items: _availableModels.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedModel = value);
                      }
                    },
                  )
                else if (_isCustomMode)
                  TextField(
                    controller: _modelController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: '模型名（手动输入）',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color(0xFFFF5A7E),
                        ),
                      ),
                      helperText: '如 deepseek-chat',
                      helperStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    ),
                    onChanged: (val) {
                      setState(() => _selectedModel = val);
                    },
                  )
                else
                  Text(
                    '请选择 API 来源后自动加载模型',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),

                const SizedBox(height: 16),

                // 5. 保存按钮（保存当前配置）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A7E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _saveConfig,
                    child: const Text('保存配置', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 24),

                // 6. 测试连接
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: _testConnection,
                      child: const Text('测试连接', style: TextStyle(color: Color(0xFFFF5A7E), fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _testStatus == 'valid' ? Colors.green : (_testStatus == 'invalid' ? Colors.red : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _testMessage,
                        style: TextStyle(
                          color: _testStatus == 'valid' ? Colors.green : (_testStatus == 'invalid' ? Colors.red : null),
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
          ),

          // ==================== 主题设置 ====================
          _buildThemeSelector(),
          const SizedBox(height: 16),

          // ==================== 界面设置 ====================
          Text(
            "界面设置", 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            )
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: Text(
                "开发者模式",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                "开启后可查看详细错误信息",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              value: _developerMode,
              onChanged: (value) async {
                setState(() => _developerMode = value);
                await _storage.saveDeveloperMode(value);
              },
              activeThumbColor: const Color(0xFFFF5A7E),
            ),
          ),

          if (_narrationCentered == null)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                title: Text("旁白居中显示"),
                subtitle: Text("加载中..."),
                trailing: CircularProgressIndicator(),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text(
                  "旁白居中显示",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  "开启为居中对齐，关闭为左对齐（小说风格）",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                value: _narrationCentered!,
                onChanged: (value) async {
                  setState(() => _narrationCentered = value);
                  await _saveNarrationCentered(value);
                },
                activeThumbColor: const Color(0xFFFF5A7E),
              ),
            ),
        ],
      ),
    );
  }
}