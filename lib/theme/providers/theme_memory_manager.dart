import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme_state.dart';
import '../core/color_semantics.dart';
import '../../services/storage_service.dart';

/// ============ 【核心业务逻辑层】 ============
/// 专门管理亮/暗两套记忆的独立性和同步

/// 主题记忆管理器 - 追踪和保存两套独立的记忆
class ThemeMemoryManager {
  final StorageService _storage = StorageService();

  /// 根据当前 brightness 更新对应的 memory
  /// 参数 brightness：指定更新哪个 memory（light/dark）
  /// 参数 newMemory：新的 memory 对象
  Future<void> updateMemoryForBrightness({
    required Brightness brightness,
    required ThemeMemory newMemory,
  }) async {
    try {
      final key = brightness == Brightness.dark
          ? _StorageKeys.darkMemory
          : _StorageKeys.lightMemory;

      // 序列化后保存
      final serialized = _serializeThemeMemory(newMemory);
      await _storage.saveString(key, serialized);

      debugPrint('✅ 已保存 ${brightness.name} 模式的记忆: $newMemory');
    } catch (e) {
      debugPrint('❌ 保存记忆失败: $e');
    }
  }

  /// 加载指定 brightness 的记忆
  Future<ThemeMemory> loadMemoryForBrightness(Brightness brightness) async {
    try {
      final key = brightness == Brightness.dark
          ? _StorageKeys.darkMemory
          : _StorageKeys.lightMemory;

      final serialized = await _storage.getString(key);

      if (serialized == null || serialized.isEmpty) {
        debugPrint('ℹ️ ${brightness.name} 模式无保存记忆，使用初始值');
        return ThemeMemory.initial();
      }

      final memory = _deserializeThemeMemory(serialized);
      debugPrint('✅ 已加载 ${brightness.name} 模式的记忆: $memory');
      return memory;
    } catch (e) {
      debugPrint('❌ 加载记忆失败: $e，使用初始值');
      return ThemeMemory.initial();
    }
  }

  /// 更新当前 brightness 对应的主题选择
  /// 自动设置 lastOperationType = themeSwitch
  ThemeMemory updateThemeSwitchInMemory(
    ThemeMemory currentMemory,
    UIThemeType newTheme,
  ) {
    return currentMemory.copyWith(
      uiTheme: newTheme,
      lastOperationType: ThemeMemoryOperationType.themeSwitch,
    );
  }

  /// 更新当前 brightness 对应的提取色
  /// 自动设置 lastOperationType = imageExtract
  ThemeMemory updateImageExtractInMemory(
    ThemeMemory currentMemory,
    Map<ExtractedColorType, Color> extractedColors,
  ) {
    return currentMemory.copyWith(
      extractedColors: extractedColors,
      lastOperationType: ThemeMemoryOperationType.imageExtract,
    );
  }

  /// 重置为默认主题（相当于"主动切回默认"）
  ThemeMemory resetMemoryToDefault() {
    return ThemeMemory.initial();
  }

  /// ========== 序列化/反序列化（用于存储） ==========

  String _serializeThemeMemory(ThemeMemory memory) {
    // 简化版本：用 JSON 字符串表示
    // 生产环境应该用 json_serializable 或类似工具
    final themeIdStr = memory.uiTheme.id;
    final opTypeStr =
        memory.lastOperationType == ThemeMemoryOperationType.themeSwitch
            ? 'switch'
            : 'extract';

    // 提取色序列化（简化：只存 dominant 和 vibrant）
    final extractStr = _serializeExtractedColors(memory.extractedColors);

    return '$themeIdStr|$opTypeStr|$extractStr';
  }

  ThemeMemory _deserializeThemeMemory(String data) {
    try {
      final parts = data.split('|');
      if (parts.length < 3) {
        return ThemeMemory.initial();
      }

      final themeIdStr = parts[0];
      final opTypeStr = parts[1];
      final extractStr = parts[2];

      final uiTheme = UIThemeTypeExtensions.fromString(themeIdStr);
      final opType = opTypeStr == 'switch'
          ? ThemeMemoryOperationType.themeSwitch
          : ThemeMemoryOperationType.imageExtract;

      final extracted = _deserializeExtractedColors(extractStr);

      return ThemeMemory(
        uiTheme: uiTheme,
        extractedColors: extracted,
        lastOperationType: opType,
      );
    } catch (e) {
      debugPrint('反序列化失败: $e');
      return ThemeMemory.initial();
    }
  }

  String _serializeExtractedColors(Map<ExtractedColorType, Color>? colors) {
    if (colors == null || colors.isEmpty) return '';

    // 简化：只保存 dominant 和 vibrant
    final dominant = colors[ExtractedColorType.dominant];
    final vibrant = colors[ExtractedColorType.vibrant];

    if (dominant == null || vibrant == null) return '';

    return '${dominant.value.toRadixString(16)},${vibrant.value.toRadixString(16)}';
  }

  Map<ExtractedColorType, Color>? _deserializeExtractedColors(String data) {
    if (data.isEmpty) return null;

    try {
      final parts = data.split(',');
      if (parts.length < 2) return null;

      final dominant = Color(int.parse(parts[0], radix: 16));
      final vibrant = Color(int.parse(parts[1], radix: 16));

      return {
        ExtractedColorType.dominant: dominant,
        ExtractedColorType.vibrant: vibrant,
        ExtractedColorType.lightVibrant: vibrant.withValues(alpha: 0.7),
        ExtractedColorType.darkVibrant: vibrant.withValues(alpha: 0.5),
        ExtractedColorType.muted: dominant.withValues(alpha: 0.6),
      };
    } catch (e) {
      debugPrint('提取色反序列化失败: $e');
      return null;
    }
  }
}

/// ========== 存储键常量 ==========
class _StorageKeys {
  static const String lightMemory = 'theme_light_memory';
  static const String darkMemory = 'theme_dark_memory';
  static const String themeMode = 'theme_mode';
}

/// ========== Provider ==========

final themeMemoryManagerProvider = Provider<ThemeMemoryManager>((ref) {
  return ThemeMemoryManager();
});
