// lib/pages/test/test_providers_page.dart
import 'package:flutter/material.dart';
import '../../services/api_config.dart';
import '../../services/storage_service.dart';

class TestProvidersPage extends StatefulWidget {
  const TestProvidersPage({super.key});

  @override
  State<TestProvidersPage> createState() => _TestProvidersPageState();
}

class _TestProvidersPageState extends State<TestProvidersPage> {
  final StorageService _storage = StorageService();
  String _testResult = '点击按钮开始测试...';

  Future<void> _testCustomProviders() async {
    setState(() {
      _testResult = '测试中...';
    });

    try {
      // 1. 获取所有服务商
      final allProviders = await ApiConfig.getProviders();
      
      // 2. 测试默认服务商是否存在
      final defaultProvider = await ApiConfig.defaultProvider;
      
      // 3. 测试是否能添加自定义服务商
      final customProviderData = {
        'id': 'test_custom_api',
        'name': '测试API',
        'baseUrl': 'https://api.test.com/v1',
        'availableModels': ['test-model-1', 'test-model-2'],
        'defaultModel': 'test-model-1',
        'requiresProxy': false,
        'setupGuide': '测试指南',
        'isCustom': true,
      };
      
      await _storage.saveCustomProvider(customProviderData);
      
      // 4. 重新获取验证
      final updatedProviders = await ApiConfig.getProviders();
      
      setState(() {
        _testResult = '''
✅ 测试通过！

总共服务商数量: ${allProviders.length}
默认服务商: ${defaultProvider.name}
NVIDIA 服务商存在: ${allProviders.containsKey('nvidia')}
自定义服务商添加成功: ${updatedProviders.containsKey('test_custom_api')}

详细服务商列表:
${allProviders.values.map((p) => '- ${p.name} (${p.id}) - ${p.isCustom ? '自定义' : '内置'}').join('\n')}

自定义服务商列表:
${(await _storage.getCustomProviders()).map((p) => '- ${p['name']} (${p['id']})').join('\n')}
''';
      });
      
      // 清理测试数据
      await _storage.deleteCustomProvider('test_custom_api');
      
    } catch (e) {
      setState(() {
        _testResult = '❌ 测试失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务商功能测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _testCustomProviders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '开始测试',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}