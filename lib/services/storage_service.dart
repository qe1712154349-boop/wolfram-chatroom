// storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // ── API配置相关 ──
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

  // ── 聊天记录相关 ──
  Future<void> saveChatHistory(List<Map<String, dynamic>> history) async {
    final prefs = await _prefs;
    final jsonString = jsonEncode(history);
    await prefs.setString('chat_history_master', jsonString);
  }

  Future<List<Map<String, dynamic>>> loadChatHistory() async {
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
          'timestamp': e['timestamp'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('聊天记录解析失败: $e');
      }
      return [];
    }
  }

    // 可选：清空聊天记录（调试或用户需要时使用）
    Future<void> clearChatHistory() async {
      final prefs = await _prefs;
      await prefs.remove('chat_history_master');
    }

  // ── 角色编辑相关 ──
  Future<void> saveCharacterAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString('character_avatar_path', path);
  }

  Future<String?> getCharacterAvatarPath() async {
    final prefs = await _prefs;
    return prefs.getString('character_avatar_path');
  }

  Future<void> saveCharacterData(Map<String, String> data) async {
    final prefs = await _prefs;
    await prefs.setString('character_data', jsonEncode(data));
  }

  Future<Map<String, String>> loadCharacterData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString('character_data');
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String, String>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('角色数据解析失败: $e');
      }
      return {};
    }
  }

  Future<String> getCharacterSystemPrompt({String? currentTime}) async {
    final data = await loadCharacterData();
    final nickname = data['nickname'] ?? 'Master';
    final intro = data['intro'] ?? '';
    final privateSetting = data['private_setting'] ?? '';
    final opening = data['opening'] ?? '';
    
    String prompt = '';
    
    if (currentTime != null && currentTime.isNotEmpty) {
      prompt += '当前时间：$currentTime\n\n';
    }
    
    prompt += '角色名称：$nickname\n\n';
    
    if (intro.isNotEmpty) {
      prompt += '角色设定：\n$intro\n\n';
    }
    
    if (opening.isNotEmpty) {
      prompt += '开场白示例：\n$opening\n\n';
    }
    
    if (privateSetting.isNotEmpty) {
      prompt += '私密行为设定：\n$privateSetting\n\n';
    }
    
    if (prompt.isEmpty) {
      prompt = '''
    角色名称：$nickname

    角色设定：
    话少，对话自然，像人类，冷淡。
    ''';
    }
    
    return prompt.trim();
  }

  Future<String> getCharacterNickname() async {
    final data = await loadCharacterData();
    return data['nickname'] ?? 'Master';
  }

  Future<String> getCharacterIntro() async {
    final data = await loadCharacterData();
    return data['intro'] ?? '';
  }

  Future<String> getCharacterOpening() async {
    final data = await loadCharacterData();
    return data['opening'] ?? '';
  }

  Future<String> copyFileToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(sourcePath)}';
      final newPath = '${appDir.path}/$fileName';
      
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        return newPath;
      } else {
        throw Exception('源文件不存在: $sourcePath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('复制文件失败: $e');
      }
      rethrow;
    }
  }

  Future<bool> hasCustomAvatar() async {
    final avatarPath = await getCharacterAvatarPath();
    if (avatarPath == null || avatarPath.isEmpty) {
      return false;
    }
    
    final file = File(avatarPath);
    return await file.exists();
  }

  Future<File?> getAvatarFile() async {
    final avatarPath = await getCharacterAvatarPath();
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    
    final file = File(avatarPath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<void> clearAllCharacterData() async {
    final prefs = await _prefs;
    await prefs.remove('character_avatar_path');
    await prefs.remove('character_data');
  }

  // ── 用户头像相关 ──
  Future<void> saveUserAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString('user_avatar_path', path);
  }

  Future<String?> getUserAvatarPath() async {
    final prefs = await _prefs;
    return prefs.getString('user_avatar_path');
  }

  Future<String> copyUserAvatarToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(sourcePath)}';
      final newPath = '${appDir.path}/$fileName';
      
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(newPath);
        return newPath;
      } else {
        throw Exception('源文件不存在: $sourcePath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('复制用户头像失败: $e');
      }
      rethrow;
    }
  }

  // ── 新增：模型管理方法 ──
  // 保存选择的模型
  Future<void> saveSelectedModel(String modelName) async {
    final prefs = await _prefs;
    await prefs.setString('selected_model', modelName);
  }

  // 获取选择的模型（默认使用 claude-3-5-haiku-latest）
  Future<String> getSelectedModel() async {
    final prefs = await _prefs;
    return prefs.getString('selected_model') ?? 'claude-3-5-haiku-latest';
  }

  // 获取可用模型列表
  List<String> getModelOptions() {
    return [
      'claude-3-5-haiku-latest',
      'claude-3-7-sonnet',
      'deepseek-chat',
      'gpt-4o-mini'
    ];
  }

  // 清空模型设置
  Future<void> clearModelSettings() async {
    final prefs = await _prefs;
    await prefs.remove('selected_model');
  }
}