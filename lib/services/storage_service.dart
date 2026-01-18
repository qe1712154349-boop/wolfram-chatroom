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

    // ── 新增：夜间模式相关 ──
  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString('theme_mode', mode); // 'light', 'dark', 'system'
  }

  Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString('theme_mode') ?? 'system'; // 默认跟随系统
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
    
    // 读取基础字段
    final nickname = data['nickname'] ?? 'Master';
    final intro = data['intro'] ?? '';
    final privateSetting = data['private_setting'] ?? '';
    final opening = data['opening'] ?? '';
    
    // 读取自定义格式相关字段
    final enableCustomFormat = data['enable_custom_format'] == 'true';
    final customFormat = data['custom_format'] ?? '';
    
    String prompt = '';
    
    // 1. 拼接基础设定
    if (nickname.isNotEmpty) {
      prompt += '角色名称：$nickname\n\n';
    }
    
    if (intro.isNotEmpty) {
      prompt += '角色设定：$intro\n\n';
    }
    
    if (privateSetting.isNotEmpty) {
      prompt += '附加设定（私密，不对外展示）：$privateSetting\n\n';
    }
    
    if (opening.isNotEmpty) {
      prompt += '开场白示例：$opening\n\n';
    }
    
    // 2. 如果启用自定义格式且有内容，作为单独段落追加
    if (enableCustomFormat && customFormat.isNotEmpty) {
      prompt += '\n=== 以下为格式要求 ===\n';
      prompt += '$customFormat\n';
    }
    
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
    return data['nickname'] ?? '';
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
    return prefs.getString('user_name') ?? '';
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
  
  // 保存旁白居中设置（使用 SharedPreferences）
  Future<void> saveNarrationCentered(bool centered) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('narration_centered', centered);
  }

  // 读取旁白居中设置
  Future<bool> getNarrationCentered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('narration_centered') ?? true;  // 默认 true（居中）
  }

// 在StorageService类中添加以下方法：

// ── 新增：UI主题相关 ──
Future<void> saveUITheme(String theme) async {
  final prefs = await _prefs;
  await prefs.setString('ui_theme', theme);
}

Future<String> getUITheme() async {
  final prefs = await _prefs;
  return prefs.getString('ui_theme') ?? 'system'; // 默认跟随系统
}

// 获取边框样式（兼容旧版本）
Future<String> getBorderStyle() async {
  final prefs = await _prefs;
  return prefs.getString('border_style') ?? '无边框';
}

Future<void> saveBorderStyle(String style) async {
  final prefs = await _prefs;
  await prefs.setString('border_style', style);
}

}