// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  Future<String?> sendChatMessage(List<Map<String, String>> messages, {String? model}) async {
    final provider = await ApiConfig.getCurrentProvider();
    if (provider == null) {
      throw Exception('没有选择服务商');
    }

    final modelName = model ?? await ApiConfig.getCurrentModel();

    if (provider.apiKey.isEmpty) {
      throw Exception('请先在设置中配置 ${provider.name} 的 API Key');
    }

    if (!provider.isOpenAiCompatible) {
      throw Exception('当前服务商 ${provider.name} 不支持 OpenAI 格式，请切换其他服务商');
    }

    try {
      final response = await http.post(
        Uri.parse('${provider.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${provider.apiKey}',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': messages,
          'temperature': 0.9,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        throw Exception('API 错误: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  // 新增：获取当前服务商的可用模型
  Future<List<String>> getAvailableModels() async {
    final provider = await ApiConfig.getCurrentProvider();
    if (provider == null) return [];
    return provider.models;
  }

  // 测试连接（兼容原有）
  Future<bool> testConnection({
    String? baseUrl,
    String? apiKey,
    String? model,
  }) async {
    final provider = await ApiConfig.getCurrentProvider();
    if (provider == null) return false;

    final testBaseUrl = baseUrl ?? provider.baseUrl;
    final testApiKey = apiKey ?? provider.apiKey;
    
    if (testApiKey.isEmpty) {
      throw Exception('API Key 为空');
    }

    if (!provider.isOpenAiCompatible) {
      throw Exception('当前服务商不支持 OpenAI 格式');
    }

    try {
      final response = await http.get(
        Uri.parse('$testBaseUrl/models'),
        headers: {'Authorization': 'Bearer $testApiKey'},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('连接失败: $e');
    }
  }
}