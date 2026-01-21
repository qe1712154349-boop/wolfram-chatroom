import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 全局 FutureProvider：Riverpod 自动 await 初始化 + 缓存 Isar 实例
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [DiaryEntrySchema],
    directory: dir.path,
    inspector: true, // release 版建议改为 false
  );
  return isar;
});

// 独立封面路径工具函数（无需依赖 Isar）
Future<String> getCoverFilePath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final coversDir = Directory('${dir.path}/diary_covers');
  if (!await coversDir.exists()) {
    await coversDir.create(recursive: true);
  }
  return '${coversDir.path}/$fileName';
}