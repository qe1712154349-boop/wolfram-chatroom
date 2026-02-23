// lib/utils/asset_picker_util.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
    if (ps != PermissionState.authorized && ps != PermissionState.limited) {
      return null;
    }

    // await 前检查：避免在已 dispose 的页面上 push picker
    if (!context.mounted) return null;

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

    // await 后检查：确保返回后 context 还活着（虽然这里你没后续用 context，但养成习惯防未来改动）
    if (!context.mounted) return null;

    return result?.first;
  }

  /// 统一多选入口（朋友圈发图，最多9张） - 微信风格
  static Future<List<AssetEntity>?> pickMultipleImagesDirectly(
    BuildContext context, {
    int maxAssets = 9,
  }) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps != PermissionState.authorized && ps != PermissionState.limited) {
      return null;
    }

    if (!context.mounted) return null;

    final result = await AssetPicker.pickAssets(
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

    if (!context.mounted) return null;

    return result;
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
  /// 提取调色板（4 主色）- 改进版
  static Future<Map<String, Color>?> extractPalette(AssetEntity asset) async {
    try {
      // ✅ 改进1：先压缩图片，减少内存占用
      final file = await asset.originFile;
      if (file == null) return null;

      // 先获取原始文件大小
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      debugPrint('📸 原始图片大小: ${fileSizeInMB.toStringAsFixed(2)} MB');

      // 如果大于 5MB，先压缩
      String imagePath = file.path;
      if (fileSizeInMB > 5) {
        debugPrint('⚙️ 图片过大，开始压缩...');
        final compressed = await compressImage(file.path);
        if (compressed != null) {
          imagePath = compressed;
          debugPrint('✅ 压缩完成: $imagePath');
        }
      }

      // ✅ 改进2：使用 File 直接读取，而不是一次性读全部到内存
      // palette_generator 可以接受 FileImage
      final imageProvider = FileImage(File(imagePath));

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100), // ✅ 改进3：降到 100x100 进行内存抖动检测
        maximumColorCount: 8, // 降低颜色数量
      );

      // 如果所有颜色都是 null，返回默认值
      final dominantColor =
          palette.dominantColor?.color ?? const Color(0xFFFF5A7E);

      return {
        'dominant': dominantColor, // 🔑 改名！原来的 'primary' 改成 'dominant'
        'vibrant': palette.vibrantColor?.color ??
            dominantColor.withAlpha((0.85 * 255).round()),
        'lightVibrant': palette.lightVibrantColor?.color ??
            dominantColor.withAlpha((0.2 * 255).round()),
        'darkVibrant': palette.darkVibrantColor?.color ??
            dominantColor.withAlpha((0.95 * 255).round()),
        'muted': palette.mutedColor?.color ?? dominantColor.withOpacity(0.5),
      };
    } catch (e) {
      debugPrint('❌ 提取失败: $e');
      return null;
    }
  }
}
