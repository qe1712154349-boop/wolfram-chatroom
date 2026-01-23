// lib/utils/asset_picker_util.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AssetPickerUtil {
  /// 统一单选入口（头像、提取主题色） - 微信风格
  static Future<AssetEntity?> pickSingleImageDirectly(
      BuildContext context) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps != PermissionState.authorized && ps != PermissionState.limited)
      return null;

    final result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image,
        maxAssets: 1,
        gridCount: 4,
        pageSize: 80,
        pickerTheme: ThemeData(
          primaryColor: const Color(0xFFFF5A7E),
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5A7E)),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF5A7E),
              foregroundColor: Colors.white),
          scaffoldBackgroundColor: Colors.white,
          bottomSheetTheme:
              const BottomSheetThemeData(backgroundColor: Colors.white),
        ),
      ),
    );
    return result?.first;
  }

  /// 统一多选入口（朋友圈发图，最多9张） - 微信风格
  static Future<List<AssetEntity>?> pickMultipleImagesDirectly(
    BuildContext context, {
    int maxAssets = 9,
  }) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps != PermissionState.authorized && ps != PermissionState.limited)
      return null;

    return await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image,
        maxAssets: maxAssets,
        gridCount: 4,
        pageSize: 80,
        pickerTheme: ThemeData(
          primaryColor: const Color(0xFFFF5A7E),
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5A7E)),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFF5A7E),
              foregroundColor: Colors.white),
        ),
      ),
    );
  }

  /// 从 AssetEntity 获取 File（兼容旧代码）
  static Future<File?> getFileFromAsset(AssetEntity asset) async {
    return await asset.originFile;
  }

  /// 异步压缩单张（原生 flutter_image_compress）
  static Future<String?> compressImage(String sourcePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1920,
        rotate: 0,
        keepExif: false,
        numberOfRetries: 5,
        format: CompressFormat.jpeg,
      );

      if (result == null) return sourcePath;
      return result.path;
    } catch (e) {
      debugPrint('压缩失败: $e，使用原图');
      return sourcePath;
    }
  }

  /// 批量压缩（并行）
  static Future<List<String>> compressMultiple(List<String> paths) async {
    final futures = paths.map(compressImage);
    final results = await Future.wait(futures);
    return results.whereType<String>().toList();
  }

  /// 提取调色板（4 主色）
  static Future<Map<String, Color>?> extractPalette(AssetEntity asset) async {
    try {
      final file = await asset.originFile;
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(Uint8List.fromList(bytes)),
        size: const Size(400, 400),
        maximumColorCount: 12,
      );
      return {
        'primary': palette.dominantColor?.color ?? const Color(0xFFFF5A7E),
        'accent': palette.vibrantColor?.color ??
            palette.dominantColor!.color.withAlpha((0.85 * 255).round()),
        'background': palette.lightVibrantColor?.color ??
            palette.dominantColor!.color.withAlpha((0.1 * 255).round()),
        'darkAccent':
            palette.darkVibrantColor?.color ?? palette.dominantColor!.color,
      };
    } catch (e) {
      debugPrint('提取失败: $e');
      return null;
    }
  }
}
