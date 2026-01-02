import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<String?> getApiBaseUrl() async {
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
}