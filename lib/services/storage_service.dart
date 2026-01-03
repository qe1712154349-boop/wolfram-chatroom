// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter/foundation.dart';
import 'api_config.dart'; // 新增导入

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // ── 新增：服务商管理方法 ──
  Future<void> saveSelectedProvider(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_provider', providerId);
  }

  Future<String> getSelectedProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_provider') ?? ApiConfig.defaultProviderId;
  }

  Future<void> saveProviderApiKey(String providerId, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key_$providerId', apiKey);
  }

  Future<String?> getProviderApiKey(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_key_$providerId');
  }
  
  // 兼容旧方法（可选，如果其他代码还在使用）
  Future<void> saveApiConfig(String baseUrl, String apiKey) async {
    // 简单实现：保存到最后使用的服务商
    final providerId = await getSelectedProvider();
    await saveProviderApiKey(providerId, apiKey);
  }
  
  Future<String> getApiBaseUrl() async {
    final providerId = await getSelectedProvider();
    final provider = ApiConfig.getProvider(providerId);
    return provider?.baseUrl ?? ApiConfig.defaultProvider.baseUrl;
  }
  
  Future<String?> getApiKey() async {
    final providerId = await getSelectedProvider();
    return await getProviderApiKey(providerId);
  }

  // ── 聊天记录相关 ──
  Future<void> saveChatHistory(List<Map<String, dynamic>> history) async {
    final prefs = await _prefs;
    
    // 转换数据，确保可以序列化
    final List<Map<String, dynamic>> serializableHistory = history.map((msg) {
      final Map<String, dynamic> serialized = {
        'role': msg['role'] as String? ?? '',
        'content': msg['content'] as String? ?? '',
        'timestamp': msg['timestamp']?.toString() ?? '',
      };
      
      // 添加额外字段（如果有）
      if (msg['type'] != null) {
        serialized['type'] = msg['type'] as String;
      }
      if (msg['displayText'] != null) {
        serialized['displayText'] = msg['displayText'] as String;
      }
      if (msg['parsed'] != null) {
        serialized['parsed'] = msg['parsed'] as bool;
      }
      
      return serialized;
    }).toList();
    
    final jsonString = jsonEncode(serializableHistory);
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
      return decoded.map<Map<String, dynamic>>((e) {
        final map = e as Map<String, dynamic>;
        return {
          'role': map['role'] as String? ?? '',
          'content': map['content'] as String? ?? '',
          'timestamp': map['timestamp']?.toString() ?? '',
          'type': map['type'] as String?,
          'displayText': map['displayText'] as String?,
          'parsed': map['parsed'] as bool? ?? false,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('聊天记录解析失败: $e');
      }
      return [];
    }
  }

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
    
    // 添加XML格式要求
    prompt += '''
===重要格式指令===
你必须严格按照以下XML格式回复，任何时候都不准打破结构：
<message>
  <narration>这里是旁白、动作、环境描述</narration>
  <dialogue>这里是角色说的话语</dialogue>
</message>

规则：
1. 所有内容必须放在<message>标签里
2. 不准出现标签以外的任何文字
3. <narration>用于叙述、动作、心理、环境描述
4. <dialogue>只用于角色直接说的话
5. 如果有多段内容，可以包含多个<narration>和<dialogue>标签
6. 确保每个<dialogue>都是完整的对话，不要截断
''';
    
    if (prompt.isEmpty) {
      prompt = '''
角色名称：$nickname

角色设定：
话少，对话自然，像人类，冷淡。

===重要格式指令===
你必须严格按照以下XML格式回复，任何时候都不准打破结构：
<message>
  <narration>这里是旁白、动作、环境描述</narration>
  <dialogue>这里是角色说的话语</dialogue>
</message>

规则：
1. 所有内容必须放在<message>标签里
2. 不准出现标签以外的任何文字
3. <narration>用于叙述、动作、心理、环境描述
4. <dialogue>只用于角色直接说的话
5. 如果有多段内容，可以包含多个<narration>和<dialogue>标签
6. 确保每个<dialogue>都是完整的对话，不要截断
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

  // ── 模型管理方法 ──
  Future<void> saveSelectedModel(String modelName) async {
    final prefs = await _prefs;
    await prefs.setString('selected_model', modelName);
  }

  Future<String> getSelectedModel() async {
    final prefs = await _prefs;
    return prefs.getString('selected_model') ?? 'deepseek-chat'; // 改为更通用的默认值
  }

  // 根据服务商获取模型列表
  List<String> getModelOptionsForCurrentProvider(String currentBaseUrl) {
    if (currentBaseUrl.contains('deepseek.com')) {
      return ['deepseek-chat', 'deepseek-coder', 'deepseek-reasoner'];
    } else if (currentBaseUrl.contains('ohmygpt.com')) {
      return ['claude-3-5-haiku-20241022', 'gpt-4o-mini', 'gpt-4-turbo', 'claude-3-opus'];
    } else if (currentBaseUrl.contains('openai.com')) {
      return ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'];
    }
    return ['deepseek-chat']; // 默认
  }

  // 旧方法（保持兼容）
  List<String> getModelOptions() {
    return ['deepseek-chat', 'claude-3-5-haiku-20241022', 'gpt-4o-mini'];
  }

  Future<void> clearModelSettings() async {
    final prefs = await _prefs;
    await prefs.remove('selected_model');
  }
}