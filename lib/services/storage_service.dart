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
      if (kDebugMode) {
       debugPrint('角色数据解析失败: $e');
      }
      return [];
    }
  }

  // 可选：清空聊天记录（调试或用户需要时使用）
  Future<void> clearChatHistory() async {
    final prefs = await _prefs;
    await prefs.remove('chat_history_master');
  }

  // ────────────────────────────────────────────────────────────
  // ── 新增：角色编辑相关存储方法 ──
  // ────────────────────────────────────────────────────────────

  // 1. 保存角色头像路径
  Future<void> saveCharacterAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString('character_avatar_path', path);
  }

  // 2. 获取角色头像路径
  Future<String?> getCharacterAvatarPath() async {
    final prefs = await _prefs;
    return prefs.getString('character_avatar_path');
  }

  // 3. 保存角色数据（昵称、简介、私密设定、开场白）
  Future<void> saveCharacterData(Map<String, String> data) async {
    final prefs = await _prefs;
    await prefs.setString('character_data', jsonEncode(data));
  }

  // 4. 加载角色数据
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

    // 5. 获取完整系统提示（包含私密设定）
    Future<String> getCharacterSystemPrompt() async {
      final data = await loadCharacterData();
      final nickname = data['nickname'] ?? 'Master';
      final intro = data['intro'] ?? '';
      final privateSetting = data['private_setting'] ?? '';
      final opening = data['opening'] ?? '';
      
      // 构建系统提示，完全使用用户填写的内容
      String prompt = '';
      
      // 添加角色名称
      prompt += '角色名称：$nickname\n\n';
      
      // 添加简介（公开部分）
      if (intro.isNotEmpty) {
        prompt += '角色设定：\n$intro\n\n';
      }
      
      // 添加开场白
      if (opening.isNotEmpty) {
        prompt += '开场白示例：\n$opening\n\n';
      }
      
      // 添加私密设定（AI能看到，用户看不到）
      if (privateSetting.isNotEmpty) {
        prompt += '私密行为设定：\n$privateSetting\n\n';
      }
      
      // 如果用户什么都没填，提供一个默认提示
      if (prompt.isEmpty) {
        prompt = '''
    角色名称：$nickname

    角色设定：
    话少，对话自然，像人类，冷淡。
    ''';
      }
      
      return prompt.trim();
    }

  // 6. 获取角色昵称
  Future<String> getCharacterNickname() async {
    final data = await loadCharacterData();
    return data['nickname'] ?? 'Master';
  }

  // 7. 获取角色简介
  Future<String> getCharacterIntro() async {
    final data = await loadCharacterData();
    return data['intro'] ?? '';
  }

  // 8. 获取开场白
  Future<String> getCharacterOpening() async {
    final data = await loadCharacterData();
    return data['opening'] ?? '';
  }

  // 9. 复制文件到应用目录并返回新路径
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
      debugPrint('角色数据解析失败: $e');
      }
      rethrow;
    }
  }

  // 10. 检查是否有自定义头像
  Future<bool> hasCustomAvatar() async {
    final avatarPath = await getCharacterAvatarPath();
    if (avatarPath == null || avatarPath.isEmpty) {
      return false;
    }
    
    final file = File(avatarPath);
    return await file.exists();
  }

  // 11. 获取头像文件
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

  // 12. 清理所有角色数据（调试用）
  Future<void> clearAllCharacterData() async {
    final prefs = await _prefs;
    await prefs.remove('character_avatar_path');
    await prefs.remove('character_data');
  }

  // 13. 保存用户头像路径
  Future<void> saveUserAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString('user_avatar_path', path);
  }

  // 14. 获取用户头像路径
  Future<String?> getUserAvatarPath() async {
    final prefs = await _prefs;
    return prefs.getString('user_avatar_path');
  }

  // 15. 复制用户头像文件到应用目录
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
}