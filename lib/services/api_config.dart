// lib/services/api_config.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final List<String> availableModels;
  final String defaultModel;
  final bool requiresProxy; // 仅用于提示用户，App不控制代理
  final String setupGuide;
  final bool isCustom; // 新增：标记是否是自定义服务商
  
  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.availableModels,
    required this.defaultModel,
    this.requiresProxy = false,
    required this.setupGuide,
    this.isCustom = false,
  });
  
  // 转换为Map以便存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'availableModels': availableModels,
      'defaultModel': defaultModel,
      'requiresProxy': requiresProxy,
      'setupGuide': setupGuide,
      'isCustom': isCustom,
    };
  }
  
  // 从Map创建
  factory ApiProvider.fromMap(Map<String, dynamic> map) {
    return ApiProvider(
      id: map['id'] as String,
      name: map['name'] as String,
      baseUrl: map['baseUrl'] as String,
      availableModels: List<String>.from(map['availableModels']),
      defaultModel: map['defaultModel'] as String,
      requiresProxy: map['requiresProxy'] as bool,
      setupGuide: map['setupGuide'] as String,
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }
}

class ApiConfig {
  // 默认服务商（硬编码）
  static final Map<String, ApiProvider> defaultProviders = {
    'deepseek': ApiProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com',
      availableModels: [
        'deepseek-chat',
        'deepseek-coder',
        'deepseek-reasoner',
      ],
      defaultModel: 'deepseek-chat',
      requiresProxy: false,
      setupGuide: '1. 访问 https://platform.deepseek.com\n2. 注册账号并获取API Key\n3. 将Key粘贴到下方',
    ),
    'ohmygpt': ApiProvider(
      id: 'ohmygpt',
      name: 'OhMyGPT',
      baseUrl: 'https://api.ohmygpt.com/v1',
      availableModels: [
        'claude-3-5-haiku-20241022',
        'gpt-4o-mini',
        'gpt-4-turbo',
        'claude-3-opus',
      ],
      defaultModel: 'claude-3-5-haiku-20241022',
      requiresProxy: true,
      setupGuide: '1. 访问 https://www.ohmygpt.com/dashboard\n2. 确保账户有余额\n3. 将Key粘贴到下方\n4. 可能需要VPN/代理才能访问',
    ),
    'openai': ApiProvider(
      id: 'openai',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      availableModels: [
        'gpt-4o',
        'gpt-4-turbo',
        'gpt-3.5-turbo',
      ],
      defaultModel: 'gpt-3.5-turbo',
      requiresProxy: true,
      setupGuide: '1. 访问 https://platform.openai.com\n2. 注册账号并获取API Key\n3. 将Key粘贴到下方\n4. 可能需要VPN/代理才能访问',
    ),
  };
  
  // 动态获取所有服务商（默认 + 自定义）
  static Future<Map<String, ApiProvider>> getProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, ApiProvider> allProviders = {...defaultProviders};
    
    // 加载自定义服务商
    final customProvidersJson = prefs.getString('custom_providers');
    if (customProvidersJson != null) {
      try {
        final List<dynamic> list = jsonDecode(customProvidersJson);
        for (final item in list) {
          final provider = ApiProvider.fromMap(item);
          allProviders[provider.id] = provider;
        }
      } catch (e) {
        print('加载自定义服务商失败: $e');
      }
    }
    
    // 添加 NVIDIA 服务商（作为默认的一部分）
    if (!allProviders.containsKey('nvidia')) {
      allProviders['nvidia'] = ApiProvider(
        id: 'nvidia',
        name: 'NVIDIA API',
        baseUrl: 'https://integrate.api.nvidia.com/v1',
        availableModels: [
          'meta/llama-3.1-405b-instruct',
          'meta/llama-3.1-70b-instruct',
          'z-ai/glm-4',
          'minimaxai/minimax-m2.1',
        ],
        defaultModel: 'meta/llama-3.1-70b-instruct',
        requiresProxy: true,
        setupGuide: '1. 访问 https://build.nvidia.com\n2. 获取 API Key\n3. 可能需要 VPN/代理',
      );
    }
    
    return allProviders;
  }
  
  // 保存自定义服务商
  static Future<void> saveCustomProvider(ApiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 如果是自定义服务商，添加到列表
    if (provider.isCustom) {
      final customProvidersJson = prefs.getString('custom_providers') ?? '[]';
      final List<dynamic> list = jsonDecode(customProvidersJson);
      list.add(provider.toMap());
      await prefs.setString('custom_providers', jsonEncode(list));
    }
  }
  
  // 删除自定义服务商
  static Future<void> deleteCustomProvider(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customProvidersJson = prefs.getString('custom_providers') ?? '[]';
    final List<dynamic> list = jsonDecode(customProvidersJson);
    
    // 过滤掉要删除的
    final newList = list.where((item) => item['id'] != id).toList();
    await prefs.setString('custom_providers', jsonEncode(newList));
  }
  
  // 根据ID获取服务商
  static Future<ApiProvider?> getProvider(String id) async {
    final providers = await getProviders();
    return providers[id];
  }
  
  // 获取默认服务商ID
  static String get defaultProviderId => 'deepseek';
  
  // 获取默认服务商
  static Future<ApiProvider> get defaultProvider async {
    return (await getProvider(defaultProviderId))!;
  }
}