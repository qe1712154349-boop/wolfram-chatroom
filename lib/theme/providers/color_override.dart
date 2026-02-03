// lib/theme/providers/color_override.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/color_semantics.dart';

/// 图片提取颜色Provider
final extractedColorsProvider =
    StateProvider<Map<ExtractedColorType, Color>?>((ref) {
  return null;
});

/// 提取颜色工具Provider
final extractedColorsUtilsProvider = Provider<ExtractedColorsUtils>((ref) {
  return ExtractedColorsUtils(ref);
});

/// 提取颜色工具类
class ExtractedColorsUtils {
  final Ref _ref;

  ExtractedColorsUtils(this._ref);

  /// 是否有提取颜色
  bool get hasExtractedColors {
    final colors = _ref.read(extractedColorsProvider);
    return colors != null && colors.isNotEmpty;
  }

  /// 获取提取颜色
  Map<ExtractedColorType, Color>? get extractedColors {
    return _ref.read(extractedColorsProvider);
  }

  /// 更新提取颜色
  Future<void> updateColors(Map<ExtractedColorType, Color> colors) async {
    _ref.read(extractedColorsProvider.notifier).state = colors;
  }

  /// 应用测试颜色
  Future<void> applyTestColor(Color color) async {
    final testColors = {
      ExtractedColorType.dominant: color,
      ExtractedColorType.vibrant: color.withValues(
          alpha: 255,
          red: color.red + 30,
          green: color.green + 30,
          blue: color.blue + 30),
      ExtractedColorType.lightVibrant: color.withValues(
          alpha: 255,
          red: color.red + 60,
          green: color.green + 60,
          blue: color.blue + 60),
      ExtractedColorType.darkVibrant: color.withValues(
          alpha: 255,
          red: color.red - 30,
          green: color.green - 30,
          blue: color.blue - 30),
      ExtractedColorType.muted: color.withOpacity(0.5),
    };

    await updateColors(testColors);
  }

  /// 重置提取颜色
  Future<void> reset() async {
    _ref.read(extractedColorsProvider.notifier).state = null;
  }

  /// 从字符串Map转换为ExtractedColorType Map
  Map<ExtractedColorType, Color> convertFromStringMap(
      Map<String, Color> stringMap) {
    final result = <ExtractedColorType, Color>{};

    for (final entry in stringMap.entries) {
      final type = _stringToExtractedColorType(entry.key);
      if (type != null) {
        result[type] = entry.value;
      }
    }

    return result;
  }

  /// 字符串转ExtractedColorType
  ExtractedColorType? _stringToExtractedColorType(String value) {
    switch (value) {
      case 'dominant':
        return ExtractedColorType.dominant;
      case 'vibrant':
        return ExtractedColorType.vibrant;
      case 'lightVibrant':
        return ExtractedColorType.lightVibrant;
      case 'darkVibrant':
        return ExtractedColorType.darkVibrant;
      case 'muted':
        return ExtractedColorType.muted;
      default:
        return null;
    }
  }
}
