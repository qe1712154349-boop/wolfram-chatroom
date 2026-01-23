import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:image_picker/image_picker.dart'; // 🆕 加这一行！pickMultipleAsXFile 用到 XFile

class AssetPickerUtil {
  /// 单选图片（头像/背景等），支持 picker 内 pinch zoom + pan
  static Future<AssetEntity?> pickSingleImage(BuildContext context) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image,
        specialPickerType: SpecialPickerType.noPreview,
        maxAssets: 1,
        themeColor: Theme.of(context).primaryColor,
        // ✅ 修正：使用正确的主题设置方式
        pickerTheme: ThemeData(
          primaryColor: const Color(0xFFFF5A7E),
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5A7E)),
          textTheme: Theme.of(context).textTheme.copyWith(
                bodyMedium: const TextStyle(color: Colors.white),
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF5A7E),
            foregroundColor: Colors.white,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        previewThumbnailSize: const ThumbnailSize.square(150),
        gridCount: 4,
        pageSize: 80,
      ),
    );

    return result?.isNotEmpty == true ? result!.first : null;
  }

  /// 多选图片（发朋友圈等）
  static Future<List<AssetEntity>?> pickMultipleImages(
    BuildContext context, {
    int maxAssets = 9,
  }) async {
    return await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image,
        maxAssets: maxAssets,
        specialPickerType: SpecialPickerType.noPreview,
        themeColor: const Color(0xFFFF5A7E),
        // ✅ 修正：使用 ThemeData
        pickerTheme: ThemeData(
          primaryColor: const Color(0xFFFF5A7E),
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF5A7E)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF5A7E),
            foregroundColor: Colors.white,
          ),
        ),
        previewThumbnailSize: const ThumbnailSize.square(200),
        gridCount: 4,
        pageSize: 80,
      ),
    );
  }

  /// AssetEntity → File（兼容原有压缩逻辑）
  static Future<File?> getFileFromAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;
    return file;
  }

  /// 如果需要兼容原有 XFile（moments_detail_page 用）
  static Future<List<XFile>?> pickMultipleAsXFile(
    BuildContext context, {
    int maxAssets = 9,
  }) async {
    final assets = await pickMultipleImages(context, maxAssets: maxAssets);
    if (assets == null || assets.isEmpty) return null;

    final List<XFile> files = [];
    for (final asset in assets) {
      final file = await getFileFromAsset(asset);
      if (file != null) {
        files.add(XFile(file.path));
      }
    }
    return files.isEmpty ? null : files;
  }
}
