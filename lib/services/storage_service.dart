// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import '../models/message.dart';

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

  // ── 服务商管理方法 ──
  Future<void> saveSelectedProvider(String providerId) async {
    final prefs = await _prefs;
    await prefs.setString('selected_provider', providerId);
  }

  Future<String> getSelectedProvider() async {
    final prefs = await _prefs;
    return prefs.getString('selected_provider') ?? ApiConfig.defaultProviderId;
  }

  Future<void> saveProviderApiKey(String providerId, String apiKey) async {
    final prefs = await _prefs;
    await prefs.setString('api_key_$providerId', apiKey);
  }

  Future<String?> getProviderApiKey(String providerId) async {
    final prefs = await _prefs;
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
  Future<void> saveChatHistory(List<Message> history) async {
    final prefs = await _prefs;
    
    // 转换为Map列表
    final List<Map<String, dynamic>> serializableHistory = history.map((msg) {
      return msg.toMap();
    }).toList();
    
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
      return decoded.map<Message>((e) {
        return Message.fromMap(e as Map<String, dynamic>);
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
      prompt += '附加设定（私密，不对外展示）：\n$privateSetting\n\n';
    }
    
// ⭐ 动态生成格式要求（根据配置）
    final actualFormat = await getActualFormat();
    
 if (actualFormat == 'markdown') {
  prompt += '''
=== 📋 输出格式要求（Markdown 格式 - 简化版）===

你的回复必须遵循以下规则：

【格式规则】
- 对话：用 "双引号" 包裹
- 旁白/动作：不用引号，直接写

【示例】
他轻轻笑出声，那笑声在石室里回荡。

"多么……可爱的要求。"

他后退一步，优雅地行了个礼。

"但亲爱的,您似乎搞错了一件事。"

【重要提示】
- 只有对话才用引号
- 旁白和动作描写不要加任何标记
- 保持自然流畅的叙述
''';
}
    
    if (prompt.isEmpty) {
      prompt = '''
角色名称：$nickname

角色设定：
话少，对话自然，像人类，冷淡。

=== 格式要求（重复强调）===
你的每个回复必须是：
<message>
  <narration>动作/表情</narration>
  <dialogue>对话</dialogue>
</message>

不要在标签外写任何东西！
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

  // ── 用户资料相关 ──
  Future<void> saveUserName(String userName) async {
    final prefs = await _prefs;
    await prefs.setString('user_name', userName);
  }

  Future<String> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString('user_name') ?? '尘不言';
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
    if (profile['name'] != null) {
      await saveUserName(profile['name'] as String);
    }
    if (profile['avatarPath'] != null) {
      await saveUserAvatarPath(profile['avatarPath'] as String);
    }
    if (profile['showAvatar'] != null) {
      await saveShowUserAvatar(profile['showAvatar'] as bool);
    }
  }

  // ── 模型管理方法 ──
  Future<void> saveSelectedModel(String modelName) async {
    final prefs = await _prefs;
    await prefs.setString('selected_model', modelName);
  }

  Future<String> getSelectedModel() async {
    final prefs = await _prefs;
    return prefs.getString('selected_model') ?? 'deepseek-chat';
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
    return ['deepseek-chat'];
  }

  // 旧方法（保持兼容）
  List<String> getModelOptions() {
    return ['deepseek-chat', 'claude-3-5-haiku-20241022', 'gpt-4o-mini'];
  }

  Future<void> clearModelSettings() async {
    final prefs = await _prefs;
    await prefs.remove('selected_model');
  }
  // ── 格式配置相关 ──
  
  /// 保存输出格式配置
  Future<void> saveOutputFormat(String format) async {
    final prefs = await _prefs;
    await prefs.setString('output_format', format);
  }
  
  /// 获取输出格式配置
  /// 返回值：'auto' | 'markdown' | 'xml' | 'json'
  Future<String> getOutputFormat() async {
    final prefs = await _prefs;
    return prefs.getString('output_format') ?? 'auto';
  }
  
  /// 根据当前模型自动推荐格式
  Future<String> getRecommendedFormat() async {
    final model = await getSelectedModel();
    
    if (model.contains('deepseek')) {
      return 'markdown';
    } else if (model.contains('claude') || model.contains('gemini')) {
      return 'xml';
    } else if (model.contains('gpt')) {
      return 'json';
    }
    
    return 'markdown'; // 默认
  }
  
  /// 获取实际使用的格式（考虑自动模式）
  Future<String> getActualFormat() async {
    final format = await getOutputFormat();
    
    if (format == 'auto') {
      return await getRecommendedFormat();
    }
    
    return format;
  }
  
  // ── 开发者日志相关 ──
  
  /// 保存调试日志（只在开发者模式下记录）
  Future<void> saveDebugLog(String message) async {
    final isDeveloperMode = await getDeveloperMode();
    if (!isDeveloperMode) return;
    
    final prefs = await _prefs;
    final logs = prefs.getStringList('debug_logs') ?? [];
    
    final timestamp = DateTime.now().toString().substring(0, 19);
    logs.add('[$timestamp] $message');
    
    // 只保留最近 50 条
    if (logs.length > 50) {
      logs.removeAt(0);
    }
    
    await prefs.setStringList('debug_logs', logs);
  }
  
  /// 获取调试日志
  Future<List<String>> getDebugLogs() async {
    final prefs = await _prefs;
    return prefs.getStringList('debug_logs') ?? [];
  }
  
  /// 清空调试日志
  Future<void> clearDebugLogs() async {
    final prefs = await _prefs;
    await prefs.remove('debug_logs');
  }
  
  /// 导出日志为文本（用于分享）
  Future<String> exportDebugLogsText() async {
    final logs = await getDebugLogs();
    if (logs.isEmpty) {
      return '暂无日志记录';
    }
    return logs.join('\n');
  }
}