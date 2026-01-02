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

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final baseUrl = await _storage.getApiBaseUrl();
    final apiKey = await _storage.getApiKey();
    setState(() {
      _baseUrlController.text = baseUrl;   // 直接赋值，因为它不可能 null
      _apiKeyController.text = apiKey ?? '';
    });
  }

  Future<void> _saveConfig() async {
    await _storage.saveApiConfig(_baseUrlController.text, _apiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API 配置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(title: const Text("设置"), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("API 配置（DeepSeek）", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A7E), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text("保存配置", style: TextStyle(fontSize: 16, color: Colors.white)),
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
          Text("4. 如果AI回复太正经，可以在设置中添加system prompt"),
        ],
      ),
    );
  }
}