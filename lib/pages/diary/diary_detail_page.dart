import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/diary_provider.dart';
import 'diary_editor_page.dart';
import '../../models/diary_entry.dart';
import '../../theme/theme.dart' as app_theme;

class DiaryDetailPage extends ConsumerWidget {
  final DiaryEntry entry;
  const DiaryDetailPage({super.key, required this.entry});

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.themeColor(app_theme.ColorSemantic.surface),
        title: Text(
          '删除日记',
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.textPrimary),
          ),
        ),
        content: Text(
          '确定要删除这篇日记吗？删除后无法恢复。',
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '取消',
              style: TextStyle(
                color:
                    context.themeColor(app_theme.ColorSemantic.textSecondary),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(
                color: context.themeColor(app_theme.ColorSemantic.error),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await ref.read(diaryListProvider.notifier).deleteDiary(entry);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        title: Text(
          DateFormat('yyyy年MM月dd日').format(entry.createdAt),
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.appBarText),
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: context.themeColor(app_theme.ColorSemantic.appBarText),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiaryEditorPage(entry: entry),
                ),
              );
            },
            tooltip: '编辑',
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: context.themeColor(app_theme.ColorSemantic.appBarText),
            ),
            onPressed: () => _showDeleteDialog(context, ref),
            tooltip: '删除',
          ),
        ],
      ),
      backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverPreview(context, ref),
            const SizedBox(height: 30),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color:
                      context.themeColor(app_theme.ColorSemantic.textSecondary),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN')
                      .format(entry.createdAt),
                  style: TextStyle(
                    fontSize: 16,
                    color: context
                        .themeColor(app_theme.ColorSemantic.textSecondary),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_outlined,
                  color:
                      context.themeColor(app_theme.ColorSemantic.textSecondary),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(entry.createdAt),
                  style: TextStyle(
                    fontSize: 16,
                    color: context
                        .themeColor(app_theme.ColorSemantic.textSecondary),
                  ),
                ),
              ],
            ),
            Divider(
              height: 30,
              color: context.themeColor(app_theme.ColorSemantic.divider),
            ),
            _buildDiaryContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPreview(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(diaryListProvider.notifier).getCoverPath(entry),
      builder: (context, snapshot) {
        final hasCoverImage = snapshot.hasData &&
            snapshot.data!.isNotEmpty &&
            File(snapshot.data!).existsSync();

        Color parseColor(String hexColor) {
          final hex = hexColor.replaceAll('#', '');
          return Color(int.parse(hex, radix: 16) | 0xFF000000);
        }

        final color1 = entry.coverColor1 != null
            ? parseColor(entry.coverColor1!)
            : context.themeColor(app_theme.ColorSemantic.primaryContainer);
        final color2 = entry.coverColor2 != null
            ? parseColor(entry.coverColor2!)
            : context.themeColor(app_theme.ColorSemantic.secondary);

        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.themeColor(app_theme.ColorSemantic.border),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context
                    .themeColor(app_theme.ColorSemantic.border)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasCoverImage
                ? Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color1, color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('MM.dd').format(entry.createdAt),
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black38,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDiaryContent(BuildContext context) {
    try {
      final contentJson = json.decode(entry.content);
      if (contentJson is List && contentJson.isNotEmpty) {
        String text = '';
        for (var element in contentJson) {
          if (element is Map && element.containsKey('insert')) {
            final insert = element['insert'];
            if (insert is String) {
              text += insert;
            }
          }
        }

        return Text(
          text.trim(),
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: context.themeColor(app_theme.ColorSemantic.textPrimary),
          ),
        );
      }
    } catch (e) {
      // 如果解析失败，显示纯文本
    }

    return Text(
      entry.content,
      style: TextStyle(
        fontSize: 16,
        height: 1.6,
        color: context.themeColor(app_theme.ColorSemantic.textPrimary),
      ),
    );
  }
}
