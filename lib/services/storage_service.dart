// storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // ── 原有方法保持不变 ──
  Future<String> getApiBaseUrl() async {
    final prefs = await _prefs;
    return prefs.getString('api_base_url') ?? 'https://api.deepseek.com';
  }

  Future<String?> getApiKey() async {
    final prefs = await _prefs;
    return prefs.getString('api_key');
  }

  Future<void> saveApiConfig(String baseUrl, String apiKey) async {
    final prefs = await _prefs;
    await prefs.setString('api_base_url', baseUrl.trim());
    await prefs.setString('api_key', apiKey.trim());
  }

  // ── 新增：保存聊天记录 ──
  Future<void> saveChatHistory(List<Map<String, String>> history) async {
    final prefs = await _prefs;
    final jsonString = jsonEncode(history);
    await prefs.setString('chat_history_master', jsonString);
  }

  // ── 新增：读取聊天记录 ──
  Future<List<Map<String, String>>> loadChatHistory() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString('chat_history_master');
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'role': e['role'] as String,
          'content': e['content'] as String,
        };
      }).toList();
    } catch (e) {
      print('聊天记录解析失败: $e');
      return [];
    }
  }

  // 可选：清空聊天记录（调试或用户需要时使用）
  Future<void> clearChatHistory() async {
    final prefs = await _prefs;
    await prefs.remove('chat_history_master');
  }
}