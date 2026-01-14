// lib/services/storage_service.dart
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import 'dart:convert';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // ── 开发者模式相关 ──
  Future<void> saveDeveloperMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('developer_mode', enabled);
  }

  Future<bool> getDeveloperMode() async {
    final prefs = await _prefs;
    return prefs.getBool('developer_mode') ?? false;
  }

  // ── 聊天记录相关 ──（必须保留）
  Future<void> saveChatHistory(List<Message> history) async {
    final prefs = await _prefs;
    final List<Map<String, dynamic>> serializableHistory = 
        history.map((msg) => msg.toMap()).toList();
    final jsonString = jsonEncode(serializableHistory);
    await prefs.setString('chat_history_master', jsonString);
  }

  Future<List<Message>> loadChatHistory() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString('chat_history_master');
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) {
        return Message.fromMap(e as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('聊天记录解析失败: $e');
      return [];
    }
  }

  Future<void> clearChatHistory() async {
    final prefs = await _prefs;
    await prefs.remove('chat_history_master');
  }

  // ── 角色编辑相关 ──
  Future<void> saveCharacterData(Map<String, String> data) async {
    final prefs = await _prefs;
    final jsonString = jsonEncode(data);
    await prefs.setString('character_data', jsonString);
  }

  Future<Map<String, String>> loadCharacterData() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString('character_data');
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      if (kDebugMode) debugPrint('角色数据解析失败: $e');
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
      prompt += '附加设定（私密，不对外展示）：\n$privateSetting\n\n';
    }
    
    // 固定格式（清理后不再动态）
    prompt += '''
=== 输出格式要求 ===
你的回复必须是：
<message>
  <narration>动作/表情</narration>
  <dialogue>对话</dialogue>
</message>
不要在标签外写任何东西！
''';
    
    return prompt.trim();
  }

  Future<void> saveLastStatus(String status) async {
    final prefs = await _prefs;
    await prefs.setString('last_valid_status', status.trim());
  }

  Future<String> getLastStatus() async {
    final prefs = await _prefs;
    return prefs.getString('last_valid_status') ?? '空白';
  }
  
  Future<String> getCharacterNickname() async {
    final data = await loadCharacterData();
    return data['nickname'] ?? '';  // ← 改成空字符串
  }

  Future<String> getCharacterIntro() async {
    final data = await loadCharacterData();
    return data['intro'] ?? '';
  }

  Future<String> getCharacterOpening() async {
    final data = await loadCharacterData();
    return data['opening'] ?? '';
  }

  // ── 角色头像路径相关 ──
  Future<void> saveCharacterAvatarPath(String path) async {
    final prefs = await _prefs;
    await prefs.setString('character_avatar_path', path);
  }

  Future<String?> getCharacterAvatarPath() async {
    final prefs = await _prefs;
    return prefs.getString('character_avatar_path');
  }

  Future<bool> hasCustomAvatar() async {
    final avatarPath = await getCharacterAvatarPath();
    if (avatarPath == null || avatarPath.isEmpty) return false;
    final file = File(avatarPath);
    return await file.exists();
  }

  Future<File?> getAvatarFile() async {
    final avatarPath = await getCharacterAvatarPath();
    if (avatarPath == null || avatarPath.isEmpty) return null;
    final file = File(avatarPath);
    if (await file.exists()) return file;
    return null;
  }

  Future<void> clearAllCharacterData() async {
    final prefs = await _prefs;
    await prefs.remove('character_avatar_path');
    await prefs.remove('character_data');
  }

  // ── 用户头像和资料相关 ──
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
      if (kDebugMode) debugPrint('复制用户头像失败: $e');
      rethrow;
    }
  }

  Future<void> saveUserName(String userName) async {
    final prefs = await _prefs;
    await prefs.setString('user_name', userName);
  }

  Future<String> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString('user_name') ?? '';  // ← 改成空字符串
  }

  Future<void> saveShowUserAvatar(bool show) async {
    final prefs = await _prefs;
    await prefs.setBool('show_user_avatar', show);
  }

  Future<bool> getShowUserAvatar() async {
    final prefs = await _prefs;
    return prefs.getBool('show_user_avatar') ?? true;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final name = await getUserName();
    final avatarPath = await getUserAvatarPath();
    final showAvatar = await getShowUserAvatar();
    
    return {
      'name': name,
      'avatarPath': avatarPath,
      'showAvatar': showAvatar,
    };
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    if (profile['name'] != null) await saveUserName(profile['name'] as String);
    if (profile['avatarPath'] != null) await saveUserAvatarPath(profile['avatarPath'] as String);
    if (profile['showAvatar'] != null) await saveShowUserAvatar(profile['showAvatar'] as bool);
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
      if (kDebugMode) debugPrint('复制文件失败: $e');
      rethrow;
    }
  }
}