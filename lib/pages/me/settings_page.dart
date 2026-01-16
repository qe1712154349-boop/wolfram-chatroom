// lib/pages/me/settings_page.dart
import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  bool _developerMode = false;
  bool? _narrationCentered;  // 改为 nullable，初始 null 表示未加载

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  String _testStatus = ''; // 测试结果提示

  @override
  void initState() {
    super.initState();
    _loadDeveloperMode();
    _loadNarrationCentered();
    _loadConfig();
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
        _narrationCentered = centered;  // centered已经是bool，不需要?? true
      });
    }
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('custom_base_url') ?? 'https://api.deepseek.com/v1';
    _keyController.text = prefs.getString('custom_api_key') ?? '';
    _modelController.text = prefs.getString('custom_model') ?? 'deepseek-chat';
    setState(() {});
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', _urlController.text.trim());
    await prefs.setString('custom_api_key', _keyController.text.trim());
    await prefs.setString('custom_model', _modelController.text.trim());
  }

  Future<void> _testConnection() async {
    setState(() => _testStatus = '测试中...');
    try {
      final response = await http.get(
        Uri.parse('${_urlController.text.trim()}/models'),
        headers: {'Authorization': 'Bearer ${_keyController.text.trim()}'},
      );
      if (response.statusCode == 200) {
        setState(() => _testStatus = '连接成功！');
        await _saveConfig();
      } else {
        setState(() => _testStatus = '连接失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _testStatus = '连接失败: $e');
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
          const Text("自定义 API 配置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: "Base URL",
              hintText: "https://api.deepseek.com/v1",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "API Key",
              hintText: "sk-...",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: "Model",
              hintText: "deepseek-chat",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _testConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A7E),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("测试连接", style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 16),
          Text(_testStatus, style: TextStyle(color: _testStatus.contains('成功') ? Colors.green : Colors.red)),

          const SizedBox(height: 32),
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

          // 旁白开关（如果未加载，禁用并显示 loading）
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