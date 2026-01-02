import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  Future<String?> sendChatMessage(List<Map<String, String>> messages) async {
    final apiKey = await _storage.getApiKey();
    final baseUrl = await _storage.getApiBaseUrl();
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key未配置');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages.map((m) => {'role': m['role'], 'content': m['content']}).toList(),
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }
}