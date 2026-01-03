// lib/services/api_config.dart
class ApiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final List<String> availableModels;
  final String defaultModel;
  final bool requiresProxy; // 仅用于提示用户，App不控制代理
  final String setupGuide;

  const ApiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.availableModels,
    required this.defaultModel,
    this.requiresProxy = false,
    required this.setupGuide,
  });
}

class ApiConfig {
  // 所有可用的服务商
  static final Map<String, ApiProvider> providers = {
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
      requiresProxy: true, // 提示用户可能需要VPN
      setupGuide: '1. 访问 https://www.ohmygpt.com/dashboard\n2. 确保账户有余额\n3. 将Key粘贴到下方\n4. 可能需要VPN/代理才能访问',
    ),
    // 未来可以添加更多服务商
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

  // 获取默认服务商ID
  static String get defaultProviderId => 'deepseek';
  
  // 根据ID获取服务商
  static ApiProvider? getProvider(String id) {
    return providers[id];
  }
  
  // 获取默认服务商
  static ApiProvider get defaultProvider => providers[defaultProviderId]!;
}