// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'api_config.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<String?> sendChatMessage(List<Map<String, String>> messages, {String? model}) async {
    // 1. 获取用户选择的服务商
    final providerId = await _storage.getSelectedProvider();
    final provider = ApiConfig.getProvider(providerId);
    if (provider == null) {
      throw Exception('未找到服务商配置');
    }
    
    // 2. 获取该服务商的API Key
    final apiKey = await _storage.getProviderApiKey(provider.id);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先配置${provider.name}的API Key');
    }
    
    // 3. 确定使用的模型
    final savedModel = await _storage.getSelectedModel();
    final modelName = model ?? (savedModel.isNotEmpty ? savedModel : provider.defaultModel);
    
    // 4. 发送请求（不处理代理，交给系统网络）
    try {
      final response = await http.post(
        Uri.parse('${provider.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
body: jsonEncode({
          'model': modelName,
          'messages': messages,
          'temperature': 0.9,
          'stream': false,
          // 预留：如果格式配置为 JSON，可以启用
          // 'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('${provider.name} API错误: ${response.statusCode}');
      }
    } catch (e) {
      // 网络错误时给出友好提示
      String errorMsg = '网络请求失败: $e';
      if (provider.requiresProxy && e.toString().contains('timed out')) {
        errorMsg = '连接超时，${provider.name}可能需要VPN/代理才能访问，请检查设备网络设置';
      }
      throw Exception(errorMsg);
    }
  }
}