import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPickerUtil {
  /// 单选图片（头像/背景等），支持 picker 内 pinch zoom + pan
  static Future<AssetEntity?> pickSingleImage(BuildContext context) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image, // 只选图片
        specialPickerType: SpecialPickerType.noPreview, // 去掉底部预览条，更简洁
        maxAssets: 1, // 单选
        themeColor: Theme.of(context).primaryColor,
        pickerTheme: AssetPickerThemeData(
          // 匹配你 App 粉色主题
          primaryColor: const Color(0xFFFF5A7E),
          // 可选：更多自定义（背景、文字等）
          textTheme: Theme.of(context).textTheme.copyWith(
                bodyMedium: TextStyle(color: Colors.white),
              ),
        ),
        // 核心参数（最新版命名）
        previewThumbnailSize: const ThumbnailSize(150, 150), // 预览缩略图大小
        gridCount: 4, // 网格 4 列（微信默认）
        pageSize: 80, // 每页加载量
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
        previewThumbnailSize: const ThumbnailSize(200, 200),
        gridCount: 4,
        pageSize: 80,
      ),
    );
  }

  /// AssetEntity → File（可在此加压缩）
  static Future<File?> getFileFromAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    // 可选：在这里插入你已有的压缩逻辑（用 image 包或 extended_image）
    // 示例：final compressedPath = await _compress(file.path);
    // return File(compressedPath);

    return file;
  }
}
