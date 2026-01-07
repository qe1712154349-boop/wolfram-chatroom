import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../services/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  final StorageService _storage = StorageService();
  
  // 状态变量
  String _selectedProviderId = ApiConfig.defaultProviderId;
  String _selectedModel = '';
  ApiProvider? _currentProvider;
  List<String> _availableModels = [];
  
  // 开发者模式
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeveloperMode();
  }

// 修改 _loadDeveloperMode 方法，添加 mounted 检查：
Future<void> _loadDeveloperMode() async {
  final mode = await _storage.getDeveloperMode();
  if (mounted) {
    setState(() {
      _developerMode = mode;
    });
  }
}

        // 修改 _toggleDeveloperMode 方法
        Future<void> _toggleDeveloperMode(bool value) async {
          await _storage.saveDeveloperMode(value);
          
          if (mounted) {
            setState(() {
              _developerMode = value;
            });
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value ? '开发者模式已开启' : '开发者模式已关闭'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

  Future<void> _loadSettings() async {
    // 1. 加载用户选择的服务商
    final providerId = await _storage.getSelectedProvider();
    final provider = ApiConfig.getProvider(providerId) ?? ApiConfig.defaultProvider;
    
    // 2. 加载该服务商的API Key
    final apiKey = await _storage.getProviderApiKey(provider.id);
    
    // 3. 加载该服务商保存的模型选择
    final savedModel = await _storage.getSelectedModel();
    
    // 4. 获取去重后的模型列表
    final uniqueModels = provider.availableModels.toSet().toList();
    
    setState(() {
      _selectedProviderId = provider.id;
      _currentProvider = provider;
      _availableModels = uniqueModels;
      
      // 确保保存的模型在可用模型中，否则使用默认模型
      if (savedModel.isNotEmpty && uniqueModels.contains(savedModel)) {
        _selectedModel = savedModel;
      } else {
        _selectedModel = provider.defaultModel;
      }
      
      _apiKeyController.text = apiKey ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (_currentProvider == null) return;
    
    // 1. 保存服务商选择
    await _storage.saveSelectedProvider(_selectedProviderId);
    
    // 2. 保存该服务商的API Key
    if (_apiKeyController.text.isNotEmpty) {
      await _storage.saveProviderApiKey(_currentProvider!.id, _apiKeyController.text);
    }
    
    // 3. 保存模型选择
    if (_selectedModel.isNotEmpty) {
      await _storage.saveSelectedModel(_selectedModel);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
    }
  }

  void _onProviderChanged(String? newProviderId) {
    if (newProviderId == null || newProviderId == _selectedProviderId) return;
    
    final newProvider = ApiConfig.getProvider(newProviderId);
    if (newProvider == null) return;
    
    // 获取去重后的模型列表
    final uniqueModels = newProvider.availableModels.toSet().toList();
    
    setState(() {
      _selectedProviderId = newProviderId;
      _currentProvider = newProvider;
      _availableModels = uniqueModels;
      _selectedModel = newProvider.defaultModel;
      _apiKeyController.text = ''; // 切换服务商时清空Key输入框
    });
    
    // 加载新服务商保存的Key
    _loadProviderApiKey(newProviderId);
  }

  Future<void> _loadProviderApiKey(String providerId) async {
    final apiKey = await _storage.getProviderApiKey(providerId);
    if (mounted && apiKey != null) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  void _showErrorLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误日志'),
        content: FutureBuilder<List<String>>(
          future: _getErrorLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return const Text('暂无错误日志');
            }
            
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: logs.reversed.map((log) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        log,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: _clearErrorLogs,
            child: const Text('清空日志', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getErrorLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('error_logs') ?? [];
  }

  Future<void> _clearErrorLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('error_logs');
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志已清空')),
      );
    }
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
          // 服务商选择
          const Text(
            "AI 服务商", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "选择AI服务提供商：",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedProviderId,
                  isExpanded: true,
                  underline: Container(height: 0),
                  onChanged: _onProviderChanged,
                  items: ApiConfig.providers.entries.map((entry) {
                    final provider = entry.value;
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (provider.requiresProxy)
                            Text(
                              '可能需要VPN',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 服务商信息卡片
          if (_currentProvider != null) _buildProviderInfoCard(),
          
          const SizedBox(height: 24),
          
          // API Key 输入
          const Text(
            "API 配置", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: "API Key",
              hintText: "请输入您的API密钥",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 模型选择
          const Text(
            "AI 模型", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "选择对话模型：",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedModel.isNotEmpty && _availableModels.contains(_selectedModel)
                      ? _selectedModel
                      : (_currentProvider?.defaultModel ?? ''),
                  isExpanded: true,
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    if (newValue != null && _availableModels.contains(newValue)) {
                      setState(() {
                        _selectedModel = newValue;
                      });
                    }
                  },
                  items: _availableModels.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 模型说明
          if (_currentProvider != null) _buildModelDescription(),
          
          const SizedBox(height: 30),
          
          // 保存按钮
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A7E), 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "保存所有设置", 
              style: TextStyle(fontSize: 16, color: Colors.white)
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 设置指南
          if (_currentProvider != null) _buildSetupGuide(),
          
          const SizedBox(height: 40),
          
          // 输出格式配置
          const Text(
            "输出格式", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          _buildFormatSelector(),
          const SizedBox(height: 40),
          // 其他设置项
          const Text(
            "其他设置", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 16),
          
          // 开发者模式开关
          SwitchListTile(
            title: const Text("开发者模式"),
            subtitle: const Text("开启后可查看详细错误信息和日志"),
            value: _developerMode,
            onChanged: _toggleDeveloperMode,
            activeThumbColor: const Color(0xFFFF5A7E),
            activeTrackColor: const Color(0xFFFF5A7E).withValues(alpha: 0.5 * 255),
          ),
          const Divider(height: 1),

          // 开发者工具入口（仅当开发者模式开启时显示）
          if (_developerMode) ...[
            ListTile(
              title: const Text("错误日志"),
              subtitle: const Text("查看最近的错误信息"),
              leading: const Icon(Icons.bug_report, color: Colors.red),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onTap: _showErrorLogs,
            ),
            const Divider(height: 1),
          ],

if (_developerMode) ...[
            ListTile(
              title: const Text("错误日志"),
              subtitle: const Text("查看最近的错误信息"),
              leading: const Icon(Icons.bug_report, color: Colors.red),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onTap: _showErrorLogs,
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text("格式诊断"),
              subtitle: const Text("查看消息格式解析日志"),
              leading: const Icon(Icons.analytics, color: Colors.blue),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onTap: _showDebugLogs,
            ),
            const Divider(height: 1),
          ],

          // 角色设置
          ListTile(
            title: const Text("角色设置"),
            subtitle: const Text("编辑AI角色人设和头像"),
            leading: const Icon(Icons.person, color: Color(0xFFFF5A7E)),
            onTap: () {
              Navigator.pushNamed(context, '/character-edit');
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text("聊天记录"),
            subtitle: const Text("管理聊天历史记录"),
            leading: const Icon(Icons.chat, color: Colors.green),
            onTap: () {
              _showNotImplementedSnackbar("聊天记录管理");
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text("关于应用"),
            subtitle: const Text("版本信息和帮助"),
            leading: const Icon(Icons.info, color: Colors.blue),
            onTap: () {
              _showNotImplementedSnackbar("关于页面");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.api,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _currentProvider!.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'API地址：${_currentProvider!.baseUrl}',
            style: const TextStyle(fontSize: 13),
          ),
          if (_currentProvider!.requiresProxy) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_lock, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    '此服务可能需要VPN/代理才能访问',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelDescription() {
    final modelDescriptions = {
      'deepseek-chat': '通用聊天模型，性价比高，适合日常对话',
      'deepseek-coder': '代码专用模型，编程助手',
      'deepseek-reasoner': '推理能力更强的模型',
      'claude-3-5-haiku-20241022': '快速响应，适合测试和简单对话',
      'claude-3-5-haiku-latest': '最新版Claude快速模型',
      'gpt-4o-mini': 'OpenAI轻量模型，响应快成本低',
      'gpt-4-turbo': 'OpenAI强大模型，智能程度高',
      'gpt-3.5-turbo': 'OpenAI经典模型，性价比高',
      'claude-3-opus': 'Anthropic最强大模型，适合复杂任务',
    };
    
    final currentModel = _selectedModel.isNotEmpty ? _selectedModel : _currentProvider?.defaultModel ?? '';
    final description = modelDescriptions[currentModel] ?? '未找到模型描述';
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupGuide() {
    final lines = _currentProvider!.setupGuide.split('\n');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFFF5A7E)),
              const SizedBox(width: 8),
              Text(
                "设置指南 - ${_currentProvider!.name}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFFF5A7E)
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: const TextStyle(fontSize: 13),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_currentProvider!.requiresProxy)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '💡 提示：如果连接失败，请检查设备网络设置，确保可以访问国际服务',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
Widget _buildFormatSelector() {
    return FutureBuilder<Map<String, String>>(
      future: _getFormatInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final info = snapshot.data!;
        final currentFormat = info['current'] ?? 'auto';
        final recommended = info['recommended'] ?? 'markdown';
        final actual = info['actual'] ?? 'markdown';
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "AI 输出格式：",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    "当前使用：${_getFormatName(actual)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 格式选项
              _buildFormatOption('auto', '自动选择（推荐）', 
                  '根据模型自动选择最佳格式', currentFormat, recommended),
              const SizedBox(height: 8),
              _buildFormatOption('markdown', 'Markdown', 
                  '*旁白* "对话"，适合 DeepSeek', currentFormat, recommended),
              const SizedBox(height: 8),
              _buildFormatOption('xml', 'XML', 
                  '<narration>/<dialogue>，适合 Claude', currentFormat, recommended),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFormatOption(String value, String title, String subtitle, 
      String currentFormat, String recommended) {
    final isSelected = currentFormat == value;
    final isRecommended = value == 'auto' || value == recommended;
    
    return GestureDetector(
      onTap: () async {
        await _storage.saveOutputFormat(value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5A7E) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFFF5A7E) : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '推荐',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<Map<String, String>> _getFormatInfo() async {
    final current = await _storage.getOutputFormat();
    final recommended = await _storage.getRecommendedFormat();
    final actual = await _storage.getActualFormat();
    
    return {
      'current': current,
      'recommended': recommended,
      'actual': actual,
    };
  }
  
  String _getFormatName(String format) {
    switch (format) {
      case 'markdown':
        return 'Markdown';
      case 'xml':
        return 'XML';
      case 'json':
        return 'JSON';
      case 'auto':
        return '自动';
      default:
        return format;
    }
  }
  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('格式解析日志'),
        content: FutureBuilder<List<String>>(
          future: _storage.getDebugLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return const Text('暂无日志记录\n\n提示：开启开发者模式后，进行对话即可记录日志');
            }
            
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: logs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final log = logs[logs.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      log,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () async {
              await _storage.exportDebugLogsText();
              if (!mounted) return;  // ⬅️ 提前返回，更安全
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已准备，可添加分享功能')),
              );
            },
            child: const Text('导出'),
          ),
          TextButton(
            onPressed: () async {
              await _storage.clearDebugLogs();
              if (!mounted) return;  // ⬅️ 改成这样
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清空')),
              );
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotImplementedSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature 功能开发中..."),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}