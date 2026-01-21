import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import '../services/isar_service.dart';
import '../models/diary_entry.dart';

// 必须定义这个 Provider，否则 ref.read(isarServiceProvider) 会 undefined
final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

final diaryListProvider = AsyncNotifierProvider<DiaryNotifier, List<DiaryEntry>>(
  DiaryNotifier.new,
);

class DiaryNotifier extends AsyncNotifier<List<DiaryEntry>> {
  @override
  Future<List<DiaryEntry>> build() async {
    return _loadAllDiaries();
  }

  Future<List<DiaryEntry>> _loadAllDiaries() async {
    final isar = await ref.read(isarServiceProvider).isar;
    return await isar.diaryEntrys
        .where()
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> addDiary(String content) async {
    state = const AsyncLoading();
    try {
      final isar = await ref.read(isarServiceProvider).isar;
      final newEntry = DiaryEntry()
        ..content = content
        ..coverColor1 = _generateRandomPastelColor()
        ..coverColor2 = _generateRandomPastelColor();

      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(newEntry);
        await _generateAndSaveCover(newEntry);
      });

      state = AsyncData(await _loadAllDiaries());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateDiary(DiaryEntry entry, String newContent) async {
    state = const AsyncLoading();
    try {
      final isar = await ref.read(isarServiceProvider).isar;
      entry.content = newContent;

      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(entry);
      });

      state = AsyncData(await _loadAllDiaries());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteDiary(DiaryEntry entry) async {
    state = const AsyncLoading();
    try {
      final isar = await ref.read(isarServiceProvider).isar;

      await isar.writeTxn(() async {
        await isar.diaryEntrys.delete(entry.id);

        final coverPath = await ref.read(isarServiceProvider).getCoverFilePath(entry.coverFileName);
        final file = File(coverPath);
        if (await file.exists()) await file.delete();
      });

      state = AsyncData(await _loadAllDiaries());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String> getCoverPath(DiaryEntry entry) async {
    return await ref.read(isarServiceProvider).getCoverFilePath(entry.coverFileName);
  }

  String _generateRandomPastelColor() {
    final random = Random();
    final r = 150 + random.nextInt(106);
    final g = 150 + random.nextInt(106);
    final b = 150 + random.nextInt(106);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  Future<void> _generateAndSaveCover(DiaryEntry entry) async {
    const width = 300.0;
    const height = 450.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final color1 = _hexToColor(entry.coverColor1 ?? '#BAE1FF');
    final color2 = _hexToColor(entry.coverColor2 ?? '#FFB3BA');

    final gradient = LinearGradient(
      colors: [color1, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    final dateStr = DateFormat('yyyy.MM.dd').format(entry.createdAt);
    final textStyle = const TextStyle(
      fontSize: 28,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontFamily: 'sans-serif',
    );

    // 移除 const，因为 ui.ParagraphStyle 不是 const 构造器
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: ui.TextDirection.ltr,
    ))
      ..pushStyle(textStyle.getTextStyle())
      ..addText(dateStr);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: width));

    canvas.drawParagraph(
      paragraph,
      Offset((width - paragraph.width) / 2, 180),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final coverPath = await ref.read(isarServiceProvider).getCoverFilePath('${entry.id}.png');
    final file = File(coverPath);
    await file.writeAsBytes(pngBytes);
  }

  Color _hexToColor(String hexCode) {
    final hex = hexCode.replaceAll('#', '');
    return Color(int.parse(hex, radix: 16) | 0xFF000000);
  }
}