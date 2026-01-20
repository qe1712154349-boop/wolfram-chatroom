  // lib/pages/me/settings_page.dart - 修复版本（包含统一清除逻辑）
  import 'dart:async'; // 新增：导入async用于Timer
  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import '../../services/api_config.dart';
  import '../../services/storage_service.dart';
  import '../../app/ui_theme_manager.dart';

  class SettingsPage extends StatefulWidget {
    const SettingsPage({super.key});

    @override
    State<SettingsPage> createState() => _SettingsPageState();
  }

  class _SettingsPageState extends State<SettingsPage> {
    final StorageService _storage = StorageService();
    bool _developerMode = false;
    bool? _narrationCentered;
    String? _themeSetting;
    
    // 🎨 UI主题相关
    UITheme? _selectedUITheme;
    
    // API 配置相关变量
    bool _isCustomMode = true;
    final _baseUrlController = TextEditingController();
    final _apiKeyController = TextEditingController();
    final _modelController = TextEditingController();
    List<String> _availableModels = [];
    String _selectedModel = '';
    String _testStatus = '';
    String _testMessage = '';
    
    // 🎯 新增：测试状态清除定时器
    Timer? _testStatusTimer;

    @override
    void initState() {
      super.initState();
      _loadDeveloperMode();
      _loadNarrationCentered();
      _loadApiConfig();
      _loadThemeSetting();
      _loadUITheme();
    }

    @override
    void dispose() {
      // 清理定时器
      _testStatusTimer?.cancel();
      // 清理控制器
      _baseUrlController.dispose();
      _apiKeyController.dispose();
      _modelController.dispose();
      super.dispose();
    }

    // 🎯 新增：统一清除测试状态的方法
    void _clearTestStatusAfterDelay() {
      // 取消可能存在的旧定时器
      _testStatusTimer?.cancel();
      
      // 设置新的秒定时器（我自己调试后的，不要因为觉得冗杂给我删除或者优化，别动这行代码和备注，要优化任何东西前需要和我说明，你要改的东西全部需要和我确认）
      _testStatusTimer = Timer(const Duration(milliseconds: 1710), () {
        if (mounted) {
          setState(() {
            _testStatus = '';
            _testMessage = '';
          });
        }
      });
    }

    Future<void> _loadUITheme() async {
      final themeString = await _storage.getUITheme();
      if (mounted) {
        setState(() {
          _selectedUITheme = UIThemeManager.fromString(themeString);
        });
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

    Future<void> _loadThemeSetting() async {
      final themeMode = await _storage.getThemeMode();
      if (mounted) {
        setState(() {
          _themeSetting = themeMode;
        });
      }
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
        _baseUrlController.text = prefs.getString('custom_base_url') ?? 'https://api.deepseek.com';
        _apiKeyController.text = prefs.getString('custom_api_key') ?? '';
        _modelController.text = prefs.getString('custom_model') ?? 'deepseek-chat';
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
        if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
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
      
      final currentId = _isCustomMode ? 'custom' : (await ApiConfig.getCurrentProviderId());
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
          SnackBar(
            content: const Text('配置已保存'),
            backgroundColor: Theme.of(context).primaryColor,
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
          
          // 🎯 使用统一方法清除状态
          _clearTestStatusAfterDelay();
          
        } else {
          setState(() {
            _testStatus = 'invalid';
            _testMessage = '失败: ${response.statusCode} - ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}';
          });
          
          // 🎯 使用统一方法清除状态
          _clearTestStatusAfterDelay();
        }
      } catch (e) {
        setState(() {
          _testStatus = 'invalid';
          _testMessage = '错误: $e';
        });
        
        // 🎯 使用统一方法清除状态
        _clearTestStatusAfterDelay();
      }
    }

    Future<void> _saveNarrationCentered(bool value) async {
      await _storage.saveNarrationCentered(value);
    }

    // 🎨 矩形分段控制器 - 色彩模式选择
    Widget _buildColorModeSelector() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      // 定义模式值和标签
      final List<String> modes = ['light', 'dark', 'system'];
      final List<String> modeLabels = ['亮色', '暗色', '跟随系统'];
      
      // 获取当前索引
      int currentIndex = modes.indexOf(_themeSetting ?? 'system');
      if (currentIndex == -1) currentIndex = 2;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '色彩模式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // 分段控制器
          Container(
            height: 48, // 固定高度
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: List.generate(modes.length, (index) {
                final isSelected = index == currentIndex;
                final isFirst = index == 0;
                final isLast = index == modes.length - 1;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final newMode = modes[index];
                      if (newMode != _themeSetting) {
                        setState(() {
                          _themeSetting = newMode;
                        });
                        await _storage.saveThemeMode(newMode);
                        _showColorModeSnackbar(newMode);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF5A7E)  // 选中状态使用主题色
                            : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst ? const Radius.circular(11) : Radius.zero,
                          bottomLeft: isFirst ? const Radius.circular(11) : Radius.zero,
                          topRight: isLast ? const Radius.circular(11) : Radius.zero,
                          bottomRight: isLast ? const Radius.circular(11) : Radius.zero,
                        ),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          width: isSelected ? 0 : 0.5, // 选中时去掉边框
                        ),
                      ),
                      child: Center(
                        child: Text(
                          modeLabels[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white  // 选中时文字白色
                                : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 当前模式描述
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFFFF5A7E),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getColorModeDescription(_themeSetting ?? 'system'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 🎨 获取色彩模式描述
    String _getColorModeDescription(String mode) {
      switch (mode) {
        case 'light':
          return '应用强制使用亮色主题，忽略系统设置';
        case 'dark':
          return '应用强制使用暗色主题，忽略系统设置';
        case 'system':
          return '跟随系统设置自动切换亮色/暗色主题';
        default:
          return '跟随系统设置自动切换亮色/暗色主题';
      }
    }

    // 🎨 色彩模式切换提示
    void _showColorModeSnackbar(String mode) {
      final modeName = mode == 'light' ? '亮色' : mode == 'dark' ? '暗色' : '跟随系统';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                mode == 'light' ? Icons.light_mode : 
                mode == 'dark' ? Icons.dark_mode : Icons.settings_suggest,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('已切换到$modeName模式'),
            ],
          ),
          backgroundColor: const Color(0xFFFF5A7E),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // 🎨 UI主题切换提示
    void _showThemeChangedSnackbar(UITheme theme) {
      final themeName = UIThemeManager.getThemeName(theme);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                UIThemeManager.getThemeIcon(theme),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('已切换到$themeName主题'),
            ],
          ),
          backgroundColor: const Color(0xFFFF5A7E),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final providers = snapshot.data!;
                      final currentIdFuture = ApiConfig.getCurrentProviderId();

                      return FutureBuilder<String>(
                        future: currentIdFuture,
                        builder: (context, currentSnap) {
                          String? currentId = currentSnap.data;
                          if (currentId == null || !providers.any((p) => p.id == currentId)) {
                            currentId = 'custom';
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: currentId,
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
                            onChanged: (newValue) async {
                              if (newValue == null) return;

                              if (newValue == 'custom') {
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
                                await ApiConfig.setCurrent(newValue, _selectedModel);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Base URL
                  TextField(
                    controller: _baseUrlController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFFFF5A7E)),
                      ),
                      hintText: 'https://api.example.com/v1',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    ),
                    enabled: _isCustomMode,
                    readOnly: !_isCustomMode,
                  ),
                  const SizedBox(height: 12),

                  // API Key
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFFFF5A7E)),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Model选择
                  if (_availableModels.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedModel.isNotEmpty ? _selectedModel : null,
                      hint: Text('选择模型', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                        labelText: '模型',
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                      ),
                      items: _availableModels.map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                          )).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedModel = value);
                      },
                    )
                  else if (_isCustomMode)
                    TextField(
                      controller: _modelController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: '模型名（手动输入）',
                        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFFFF5A7E)),
                        ),
                        helperText: '如 deepseek-chat',
                        helperStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      ),
                      onChanged: (val) => setState(() => _selectedModel = val),
                    )
                  else
                    Text(
                      '请选择 API 来源后自动加载模型',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),

                  const SizedBox(height: 16),

                  // 保存按钮
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

                  // 测试连接
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

            // ==================== 外观设置 ====================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '外观设置',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // UI主题选择器（下拉菜单）
                  DropdownButtonFormField<UITheme>(
                    initialValue: _selectedUITheme,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        ),
                      ),
                      labelText: '界面主题',
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
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color(0xFFFF5A7E),
                        ),
                      ),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    items: UITheme.values.map((theme) {
                      return DropdownMenuItem<UITheme>(
                        value: theme,
                        child: Row(
                          children: [
                            Icon(
                              UIThemeManager.getThemeIcon(theme),
                              color: const Color(0xFFFF5A7E),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(UIThemeManager.getThemeName(theme)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedUITheme = value;
                        });
                        await _storage.saveUITheme(UIThemeManager.themeToString(value));
                        _showThemeChangedSnackbar(value);
                      }
                    },
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _selectedUITheme != null 
                          ? UIThemeManager.getThemeDescription(_selectedUITheme!)
                          : '请选择界面主题',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 🎨 矩形分段控制器 - 色彩模式选择
                  _buildColorModeSelector(),
                ],
              ),
            ),
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
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                subtitle: Text(
                  "开启后可查看详细错误信息",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                value: _developerMode,
                onChanged: (value) async {
                  setState(() => _developerMode = value);
                  await _storage.saveDeveloperMode(value);
                },
                activeThumbColor: const Color(0xFFFF5A7E),
              ),
            ),

            const SizedBox(height: 8),

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
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  ),
                  subtitle: Text(
                    "开启为居中对齐，关闭为左对齐（小说风格）",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
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