// lib/services/isar_service.dart
import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';

class IsarService {
  // 单例模式
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  late Isar _isar;
  bool _isInitialized = false;

  // 获取 Isar 实例
  Isar get isar => _isar;

  // 初始化数据库
  Future<void> init() async {
    if (_isInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DiaryEntrySchema],
      directory: dir.path,
      inspector: true, // 仅在开发时启用，方便调试
    );
    
    _isInitialized = true;
  }

  // 获取封面图片的完整存储路径
  Future<String> getCoverFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${dir.path}/diary_covers');
    
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    
    return '${coversDir.path}/$fileName';
  }

  // 关闭数据库（通常在应用退出时调用）
  Future<void> close() async {
    await _isar.close();
    _isInitialized = false;
  }
}