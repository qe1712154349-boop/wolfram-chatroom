import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class AssetPickerUtil {
  /// 单选图片（头像/背景等），支持 picker 内 pinch zoom
  static Future<AssetEntity?> pickSingleImage(BuildContext context) async {
    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        requestType: RequestType.image, // 只选图片
        specialPickerType: SpecialPickerType.noPreview, // 可选：去掉底部预览条（更简洁）
        maxAssets: 1, // 单选
        themeColor: Theme.of(context).primaryColor,
        pickerTheme: AssetPickerThemeData(
          // 可选：匹配你 App 粉色主题
          primaryColor: const Color(0xFFFF5A7E),
        ),
        // 核心：启用预览大图 pinch zoom + pan
        previewThumbSize: const Size(150, 150), // 缩略图质量
        gridCount: 4, // 网格列数（微信默认4）
        pageSize: 80, // 每页加载量
      ),
    );

    return result?.isNotEmpty == true ? result!.first : null;
  }

  /// 多选图片（发朋友圈等），支持 picker 内 zoom
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
        gridCount: 4,
        pageSize: 80,
        // 启用微信式预览 zoom
        previewThumbSize: const Size(200, 200),
      ),
    );
  }

  /// 把 AssetEntity 转 File（压缩后路径）
  static Future<File?> getFileFromAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    // 可选：在这里加压缩逻辑（用你已有的 image 包）
    // final compressed = await _compressImage(file);
    // return compressed;

    return file;
  }
}
