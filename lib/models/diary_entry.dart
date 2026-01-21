// lib/models/diary_entry.dart
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

part 'diary_entry.g.dart';

@collection
class DiaryEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late String uuid; // 用于封面文件名

  late DateTime createdAt;
  late String content; // Quill Delta JSON 字符串
  String? coverColor1; // 渐变色1 (十六进制，如 #FFB3BA)
  String? coverColor2; // 渐变色2 (十六进制，如 #BAE1FF)

  DiaryEntry() {
    uuid = const Uuid().v4();
    createdAt = DateTime.now();
  }

  // 封面图片的文件名（不包含完整路径）
  String get coverFileName => 'diary_cover_$uuid.png';
}