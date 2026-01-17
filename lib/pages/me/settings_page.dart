// lib/pages/me/settings_page.dart
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
        const SnackBar(content: Text('配置已保存')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("设置"),
        backgroundColor: Colors.white,
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
                const Text(
                  'API 配置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'API 来源',
                          ),
                          items: [
                            ...providers.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
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
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://api.example.com/v1',
                  ),
                  enabled: _isCustomMode, // 预设模式下禁用（锁定）
                  readOnly: !_isCustomMode,
                ),
                const SizedBox(height: 12),

                // 3. API Key（一直可编辑）
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Model（下拉或手动输入）
                if (_availableModels.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedModel.isNotEmpty ? _selectedModel : null,
                    hint: const Text('选择模型'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '模型',
                    ),
                    items: _availableModels.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
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
                    decoration: const InputDecoration(
                      labelText: '模型名（手动输入）',
                      border: OutlineInputBorder(),
                      helperText: '如 deepseek-chat',
                    ),
                    onChanged: (val) {
                      setState(() => _selectedModel = val);
                    },
                  )
                else
                  const Text('请选择 API 来源后自动加载模型'),

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

          // ==================== 界面设置 ====================
          const Text("界面设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          SwitchListTile(
            title: const Text("开发者模式"),
            subtitle: const Text("开启后可查看详细错误信息"),
            value: _developerMode,
            onChanged: (value) async {
              setState(() => _developerMode = value);
              await _storage.saveDeveloperMode(value);
            },
            activeThumbColor: const Color(0xFFFF5A7E),
          ),

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
                await _saveNarrationCentered(value);
              },
              activeThumbColor: const Color(0xFFFF5A7E),
            ),
        ],
      ),
    );
  }
}