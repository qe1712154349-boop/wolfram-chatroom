// lib/services/api_config.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiProvider {
  final String id;                // 唯一标识，如 'deepseek', 'groq', 'custom_1'
  final String name;              // 显示名
  final String baseUrl;           // 基础 URL
  final String apiKey;            // 密钥（保存时加密更好，但先明文）
  final List<String> models;      // 可用模型列表
  final bool isOpenAiCompatible;  // 是否 OpenAI 格式（header Bearer, /chat/completions）
  final bool isCustom;            // 是否用户自定义
  final bool requiresProxy;       // 仅用于提示用户，App不控制代理
  final String setupGuide;        // 设置指南

  ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.models = const [],
    this.isOpenAiCompatible = true,
    this.isCustom = false,
    this.requiresProxy = false,
    this.setupGuide = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'models': models,
        'isOpenAiCompatible': isOpenAiCompatible,
        'isCustom': isCustom,
        'requiresProxy': requiresProxy,
        'setupGuide': setupGuide,
      };

  factory ApiProvider.fromMap(Map<String, dynamic> map) => ApiProvider(
        id: map['id'] as String,
        name: map['name'] as String,
        baseUrl: map['baseUrl'] as String,
        apiKey: map['apiKey'] as String,
        models: List<String>.from(map['models'] ?? []),
        isOpenAiCompatible: map['isOpenAiCompatible'] ?? true,
        isCustom: map['isCustom'] ?? false,
        requiresProxy: map['requiresProxy'] ?? false,
        setupGuide: map['setupGuide'] ?? '',
      );
}

class ApiConfig {
  static const String _providersKey = 'api_providers';
  static const String _currentProviderIdKey = 'current_provider_id';
  static const String _currentModelKey = 'current_model';

  // 预设模板（硬编码）- 基于你原有的provider信息改进
  static final List<ApiProvider> defaultProviders = [
    ApiProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      apiKey: '', // 用户必须自己填
      models: ['deepseek-chat', 'deepseek-coder', 'deepseek-reasoner'],
      isOpenAiCompatible: true,
      requiresProxy: false,
      setupGuide: '1. 访问 https://platform.deepseek.com\n2. 注册账号并获取API Key\n3. 将Key粘贴到下方',
    ),
    ApiProvider(
      id: 'ohmygpt',
      name: 'OhMyGPT',
      baseUrl: 'https://api.ohmygpt.com/v1',
      apiKey: '',
      models: ['claude-3-5-haiku-20241022', 'gpt-4o-mini', 'gpt-4-turbo', 'claude-3-opus'],
      isOpenAiCompatible: true,
      requiresProxy: true,
      setupGuide: '1. 访问 https://www.ohmygpt.com/dashboard\n2. 确保账户有余额\n3. 将Key粘贴到下方\n4. 可能需要VPN/代理才能访问',
    ),
    ApiProvider(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      models: ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'],
      isOpenAiCompatible: true,
      requiresProxy: true,
      setupGuide: '1. 访问 https://platform.openai.com\n2. 注册账号并获取API Key\n3. 将Key粘贴到下方\n4. 可能需要VPN/代理才能访问',
    ),
    ApiProvider(
      id: 'nvidia',
      name: 'NVIDIA API',
      baseUrl: 'https://integrate.api.nvidia.com/v1',
      apiKey: '',
      models: ['meta/llama-3.1-405b-instruct', 'meta/llama-3.1-70b-instruct', 'z-ai/glm-4', 'minimaxai/minimax-m2.1'],
      isOpenAiCompatible: true,
      requiresProxy: true,
      setupGuide: '1. 访问 https://build.nvidia.com\n2. 获取 API Key\n3. 可能需要 VPN/代理',
    ),
    // 新增预设
    ApiProvider(
      id: 'groq',
      name: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      apiKey: '',
      models: ['llama3-70b-8192', 'mixtral-8x7b-32768', 'gemma2-9b-it', 'llama-3.1-70b-versatile'],
      isOpenAiCompatible: true,
      requiresProxy: false,
      setupGuide: '1. 访问 https://console.groq.com\n2. 注册并获取API Key',
    ),
    ApiProvider(
      id: 'anthropic',
      name: 'Anthropic (Claude)',
      baseUrl: 'https://api.anthropic.com/v1',
      apiKey: '',
      models: ['claude-3-5-sonnet-20241022', 'claude-3-opus-20240229', 'claude-3-haiku-20240307'],
      isOpenAiCompatible: false,
      requiresProxy: true,
      setupGuide: '1. 访问 https://console.anthropic.com\n2. 获取 API Key\n3. 需要特殊格式请求',
    ),
  ];

  // 加载所有 provider（预设 + 自定义）
  static Future<List<ApiProvider>> loadProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_providersKey);
    
    if (jsonStr == null || jsonStr.isEmpty) {
      // 第一次：返回预设
      return List.from(defaultProviders);
    }
    
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => ApiProvider.fromMap(e)).toList();
    } catch (e) {
      print('加载服务商失败: $e');
      return List.from(defaultProviders);
    }
  }

  // 保存所有 provider
  static Future<void> saveProviders(List<ApiProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(providers.map((p) => p.toMap()).toList());
    await prefs.setString(_providersKey, json);
  }

  // 获取当前 provider ID 和 model
  static Future<String> getCurrentProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentProviderIdKey) ?? 'deepseek';
  }

  static Future<String> getCurrentModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentModelKey) ?? 'deepseek-chat';
  }

  // 设置当前
  static Future<void> setCurrent(String providerId, String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProviderIdKey, providerId);
    await prefs.setString(_currentModelKey, model);
  }

  // 获取当前完整 provider
  static Future<ApiProvider?> getCurrentProvider() async {
    final id = await getCurrentProviderId();
    final all = await loadProviders();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (e) {
      return defaultProviders.first;
    }
  }

  // 尝试从 /models 拉取模型列表（OpenAI 兼容的才有效）
  static Future<List<String>> tryFetchModels(ApiProvider provider) async {
    if (!provider.isOpenAiCompatible) return provider.models; // 非兼容的跳过
    if (provider.apiKey.isEmpty) return provider.models; // 没有API Key不尝试

    try {
      final response = await http.get(
        Uri.parse('${provider.baseUrl}/models'),
        headers: {'Authorization': 'Bearer ${provider.apiKey}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> modelList = data['data'] ?? [];
        return modelList.map((m) => m['id'].toString()).toList();
      } else {
        print('拉取模型失败: ${response.statusCode}');
        return provider.models;
      }
    } catch (e) {
      print('拉取模型异常: $e');
      return provider.models;
    }
  }

  // 添加自定义provider
  static Future<void> addCustomProvider({
    required String name,
    required String baseUrl,
    required String apiKey,
    bool isOpenAiCompatible = true,
    bool requiresProxy = false,
  }) async {
    final all = await loadProviders();
    
    // 生成唯一ID
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    
    final newProvider = ApiProvider(
      id: id,
      name: name,
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: [], // 初始为空，后续可以拉取
      isOpenAiCompatible: isOpenAiCompatible,
      isCustom: true,
      requiresProxy: requiresProxy,
      setupGuide: '自定义服务商',
    );
    
    all.add(newProvider);
    await saveProviders(all);
  }

  // 删除provider
  static Future<void> deleteProvider(String id) async {
    final all = await loadProviders();
    all.removeWhere((p) => p.id == id);
    await saveProviders(all);
  }

  // 更新provider的API Key和模型
  static Future<void> updateProvider({
    required String id,
    String? apiKey,
    List<String>? models,
  }) async {
    final all = await loadProviders();
    final index = all.indexWhere((p) => p.id == id);
    
    if (index != -1) {
      final provider = all[index];
      all[index] = ApiProvider(
        id: provider.id,
        name: provider.name,
        baseUrl: provider.baseUrl,
        apiKey: apiKey ?? provider.apiKey,
        models: models ?? provider.models,
        isOpenAiCompatible: provider.isOpenAiCompatible,
        isCustom: provider.isCustom,
        requiresProxy: provider.requiresProxy,
        setupGuide: provider.setupGuide,
      );
      await saveProviders(all);
    }
  }
}