import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  final StorageService _storage = StorageService();
  
  // 模型选择相关变量
  String _selectedModel = 'claude-3-5-haiku-latest';
  List<String> _modelOptions = [];

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
    _loadModelSettings();
  }

  Future<void> _loadSavedConfig() async {
    final baseUrl = await _storage.getApiBaseUrl();
    final apiKey = await _storage.getApiKey();
    setState(() {
      _baseUrlController.text = baseUrl;
      _apiKeyController.text = apiKey ?? '';
    });
  }

  Future<void> _loadModelSettings() async {
    final model = await _storage.getSelectedModel();
    setState(() {
      _selectedModel = model;
      _modelOptions = _storage.getModelOptions();
    });
  }

  Future<void> _saveConfig() async {
    await _storage.saveApiConfig(_baseUrlController.text, _apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API 配置已保存')));
    }
  }

  Future<void> _saveModel(String model) async {
    await _storage.saveSelectedModel(model);
    if (mounted) {
      setState(() {
        _selectedModel = model;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('模型设置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("设置"), 
        backgroundColor: Colors.white
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API 配置部分
          const Text("API 配置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: "API Base URL",
              hintText: "https://api.deepseek.com",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: "API Key",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A7E), 
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            child: const Text("保存API配置", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 40),
          
          // 模型选择部分
          const Text("AI 模型选择", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
                  "选择默认对话模型：",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _saveModel(newValue);
                    }
                  },
                  items: _modelOptions.map<DropdownMenuItem<String>>((String value) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("模型说明：", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("• claude-3-5-haiku: 快速响应，适合测试", style: TextStyle(fontSize: 12)),
                Text("• claude-3-7-sonnet: 顶级情感模型，适合恋人对话", style: TextStyle(fontSize: 12)),
                Text("• deepseek-chat: 免费模型，性价比高", style: TextStyle(fontSize: 12)),
                Text("• gpt-4o-mini: OpenAI轻量模型", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // 其他设置项
          const Text("其他设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text("角色设置"),
            subtitle: const Text("编辑AI角色人设和头像"),
            leading: const Icon(Icons.person, color: Color(0xFFFF5A7E)),
            onTap: () {
              // 跳转到角色设置页面
              Navigator.pushNamed(context, '/character-edit');
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
          
          const SizedBox(height: 50),
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🐰 兔兔温馨提示：", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5A7E))),
          SizedBox(height: 8),
          Text("1. 去 https://platform.deepseek.com/ 注册账号并获取API Key"),
          SizedBox(height: 4),
          Text("2. Base URL 保持为 https://api.deepseek.com"),
          SizedBox(height: 4),
          Text("3. 保存配置后，在聊天页面测试是否正常"),
          SizedBox(height: 4),
          Text("4. 如果AI回复太正经，可以在角色设置中添加system prompt"),
        ],
      ),
    );
  }

  void _showNotImplementedSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature功能开发中..."),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}