//lib/providers/diary_provider.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/isar_service.dart';
import '../models/diary_entry.dart';  // 这个必须有！因为 .g.dart 是 part of 这个文件，扩展依赖它
import 'package:isar_community/isar.dart';  // 或你用的社区版 import

// Provider 1: IsarService 的单例提供者
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService();
});

// Provider 2: 日记列表的状态管理
final diaryListProvider = StateNotifierProvider<DiaryNotifier, List<DiaryEntry>>((ref) {
  return DiaryNotifier(ref);
});

class DiaryNotifier extends StateNotifier<List<DiaryEntry>> {
  final Ref ref;
  DiaryNotifier(this.ref) : super([]) {
    // 初始化时加载所有日记
    loadAllDiaries();
  }

  // 加载所有日记（按创建时间倒序）
  Future<void> loadAllDiaries() async {
    final isar = ref.read(isarServiceProvider).isar;
// 正确的写法：
final diaries = await isar.diaryEntrys
    .where()                // 1. 先 where()
    .sortByCreatedAtDesc()  // 2. 再排序（这个方法是存在的！）
    .findAll();
    state = diaries;
  }

  // 添加新日记
  Future<void> addDiary(String content) async {
    final isar = ref.read(isarServiceProvider).isar;
    
    // 创建新日记条目
    final newEntry = DiaryEntry()
      ..content = content
      ..coverColor1 = _generateRandomPastelColor()
      ..coverColor2 = _generateRandomPastelColor();

    await isar.writeTxn(() async {
      // 保存到数据库
      await isar.diaryEntrys.put(newEntry);
      // 生成封面图片
      await _generateAndSaveCover(newEntry);
    });

    // 重新加载列表
    await loadAllDiaries();
  }

  // 更新日记内容
  Future<void> updateDiary(DiaryEntry entry, String newContent) async {
    final isar = ref.read(isarServiceProvider).isar;
    
    entry.content = newContent;
    
    await isar.writeTxn(() async {
      await isar.diaryEntrys.put(entry);
    });
    
    await loadAllDiaries();
  }

  // 删除日记
  Future<void> deleteDiary(DiaryEntry entry) async {
    final isar = ref.read(isarServiceProvider).isar;
    
    await isar.writeTxn(() async {
      // 从数据库删除
      await isar.diaryEntrys.delete(entry.id);
      
      // 删除对应的封面图片文件
      try {
        final coverPath = await ref.read(isarServiceProvider).getCoverFilePath(entry.coverFileName);
        final file = File(coverPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('删除封面文件失败: $e');
      }
    });
    
    await loadAllDiaries();
  }

  // 获取封面路径
  Future<String> getCoverPath(DiaryEntry entry) async {
    return ref.read(isarServiceProvider).getCoverFilePath(entry.coverFileName);
  }

  // 生成随机柔和的颜色
  String _generateRandomPastelColor() {
    final random = Random();
    // 生成柔和的RGB值（150-255之间）
    final r = 150 + random.nextInt(106); // 150-255
    final g = 150 + random.nextInt(106);
    final b = 150 + random.nextInt(106);
    
    return '#${r.toRadixString(16).padLeft(2, '0')}'
           '${g.toRadixString(16).padLeft(2, '0')}'
           '${b.toRadixString(16).padLeft(2, '0')}';
  }

  // 生成并保存封面图片
  Future<void> _generateAndSaveCover(DiaryEntry entry) async {
    const width = 300.0;
    const height = 450.0;
    
    // 创建 PictureRecorder 和 Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    
    // 解析颜色
    final color1 = _hexToColor(entry.coverColor1!);
    final color2 = _hexToColor(entry.coverColor2!);
    
    // 绘制渐变背景
    final gradient = LinearGradient(
      colors: [color1, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    
    // 绘制日期文本
    final dateStr = DateFormat('yyyy.MM.dd').format(entry.createdAt);
    final textStyle = const TextStyle(
      fontSize: 28,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontFamily: 'sans-serif',
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: ui.TextDirection.ltr,  // 添加 ui. 前缀
    ))
      ..pushStyle(textStyle.getTextStyle())
      ..addText(dateStr);
    
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width));
    
    canvas.drawParagraph(
      paragraph,
      Offset((width - paragraph.width) / 2, 180),
    );
    
    // 结束录制并转换为图片
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    
    // 保存到文件
    final coverPath = await ref.read(isarServiceProvider).getCoverFilePath(entry.coverFileName);
    final file = File(coverPath);
    await file.writeAsBytes(pngBytes);
  }

  // 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexCode) {
    final hex = hexCode.replaceAll('#', '');
    return Color(int.parse(hex, radix: 16) | 0xFF000000);
  }
}