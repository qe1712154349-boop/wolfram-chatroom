// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String defaultBaseUrl = 'https://api.deepseek.com/v1';
  static const String defaultApiKey = 'YOUR_DEEPSEEK_API_KEY_HERE';
  static const String defaultModel = 'deepseek-chat';

  Future<String?> sendChatMessage(List<Map<String, String>> messages, {String? model}) async {
    final prefs = await SharedPreferences.getInstance();

    // 优先用自定义配置，没有才用默认
    final baseUrl = prefs.getString('custom_base_url') ?? defaultBaseUrl;
    final apiKey = prefs.getString('custom_api_key') ?? defaultApiKey;
    final modelName = model ?? (prefs.getString('custom_model') ?? defaultModel);

    if (apiKey == defaultApiKey || apiKey.isEmpty) {
      throw Exception('请先在设置中配置 API Key');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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
}