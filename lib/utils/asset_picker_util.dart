// lib/utils/asset_picker_util.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:palette_generator/palette_generator.dart';

class AssetPickerUtil {
  /// 统一入口：直接弹出微信风格相册（单选）
  static Future<AssetEntity?> pickImageDirectly(BuildContext context) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: AndroidPermissionType.readMediaImages,
          mediaTypes: [AndroidMediaType.image],
        ),
      ),
    );

    if (!ps.hasPermission) return null;

    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image,
        maxAssets: 1,
        gridCount: 4,
        pageSize: 80,
        specialPickerType: SpecialPickerType.noPreview,
        pickerTheme: ThemeData(
          primaryColor: const Color(0xFFFF5A7E),
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5A7E)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF5A7E),
            foregroundColor: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
          bottomSheetTheme:
              const BottomSheetThemeData(backgroundColor: Colors.white),
        ),
        // 关键：不传 themeColor，避免断言失败
      ),
    );

    return result?.first;
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
            palette.dominantColor!.color.withValues(alpha: 0.85),
        'background': palette.lightVibrantColor?.color ??
            palette.dominantColor!.color.withValues(alpha: 0.1),
        'darkAccent':
            palette.darkVibrantColor?.color ?? palette.dominantColor!.color,
      };
    } catch (e) {
      debugPrint('提取失败: $e');
      return null;
    }
  }

  // 兼容原有方法（头像页用）
  static Future<File?> getFileFromAsset(AssetEntity asset) async {
    return await asset.originFile;
  }
}
