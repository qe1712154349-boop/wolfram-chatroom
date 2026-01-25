import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import '../services/isar_service.dart';
import '../models/diary_entry.dart';

final diaryListProvider =
    AsyncNotifierProvider<DiaryNotifier, List<DiaryEntry>>(
  DiaryNotifier.new,
);

class DiaryNotifier extends AsyncNotifier<List<DiaryEntry>> {
  @override
  Future<List<DiaryEntry>> build() async {
    final Isar isar = await ref.watch(isarProvider.future); // 显式声明 Isar 类型
    return isar.diaryEntrys.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> addDiary(String content) async {
    state = const AsyncLoading();
    try {
      final Isar isar = await ref.watch(isarProvider.future);
      final newEntry = DiaryEntry()
        ..content = content
        ..coverColor1 = _generateRandomPastelColor()
        ..coverColor2 = _generateRandomPastelColor();

      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(newEntry);
        await _generateAndSaveCover(newEntry);
      });

      state = AsyncData(await build());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateDiary(DiaryEntry entry, String newContent) async {
    state = const AsyncLoading();
    try {
      final Isar isar = await ref.watch(isarProvider.future);
      entry.content = newContent;

      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(entry);
      });

      state = AsyncData(await build());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteDiary(DiaryEntry entry) async {
    state = const AsyncLoading();
    try {
      final Isar isar = await ref.watch(isarProvider.future);

      await isar.writeTxn(() async {
        await isar.diaryEntrys.delete(entry.id);

        final coverPath = await getCoverFilePath('${entry.id}.png');
        final file = File(coverPath);
        if (await file.exists()) await file.delete();
      });

      state = AsyncData(await build());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String> getCoverPath(DiaryEntry entry) async {
    return await getCoverFilePath('${entry.id}.png');
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

    final coverPath = await getCoverFilePath('${entry.id}.png');
    final file = File(coverPath);
    await file.writeAsBytes(pngBytes);
  }

  Color _hexToColor(String hexCode) {
    final hex = hexCode.replaceAll('#', '');
    return Color(int.parse(hex, radix: 16) | 0xFF000000);
  }
}
