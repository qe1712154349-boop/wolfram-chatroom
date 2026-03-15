import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/diary_provider.dart';
import '../../models/diary_entry.dart';
import 'diary_editor_page.dart';
import 'diary_detail_page.dart';
import '../../theme/theme.dart' as app_theme;

class DiaryBookshelfPage extends ConsumerWidget {
  const DiaryBookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('📖 DiaryBookshelfPage 开始构建...');

    final diariesAsync = ref.watch(diaryListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        title: Text(
          '我的日记书架',
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.appBarText),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: context.themeColor(app_theme.ColorSemantic.appBarText),
            ),
            onPressed: () => ref.invalidate(diaryListProvider),
            tooltip: '刷新',
          ),
        ],
      ),
      body: diariesAsync.when(
        data: (diaries) {
          debugPrint('✅ 成功获取日记数据,数量: ${diaries.length}');
          return diaries.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildBookshelfGrid(context, ref, diaries);
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: context.themeColor(app_theme.ColorSemantic.primary),
          ),
        ),
        error: (error, stackTrace) {
          debugPrint('日记加载错误: $error\n$stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: context.themeColor(app_theme.ColorSemantic.error),
                ),
                const SizedBox(height: 24),
                Text(
                  '加载日记失败',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        context.themeColor(app_theme.ColorSemantic.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context
                          .themeColor(app_theme.ColorSemantic.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context
                        .themeColor(app_theme.ColorSemantic.buttonPrimary),
                    foregroundColor: context
                        .themeColor(app_theme.ColorSemantic.buttonPrimaryText),
                  ),
                  onPressed: () => ref.invalidate(diaryListProvider),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.buttonPrimary),
        foregroundColor:
            context.themeColor(app_theme.ColorSemantic.buttonPrimaryText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
          ).then((_) {
            if (context.mounted) {
              ref.invalidate(diaryListProvider);
            }
          });
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 120,
            color: context.themeColor(app_theme.ColorSemantic.textHint),
          ),
          const SizedBox(height: 24),
          Text(
            '日记书架空空如也',
            style: TextStyle(
              fontSize: 22,
              color: context.themeColor(app_theme.ColorSemantic.textSecondary),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右下角 + 开始记录你的心情吧',
            style: TextStyle(
              fontSize: 16,
              color: context.themeColor(app_theme.ColorSemantic.textSecondary),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('写第一篇日记'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  context.themeColor(app_theme.ColorSemantic.buttonPrimary),
              foregroundColor:
                  context.themeColor(app_theme.ColorSemantic.buttonPrimaryText),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
              ).then((_) {
                if (context.mounted) {
                  ref.invalidate(diaryListProvider);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookshelfGrid(
      BuildContext context, WidgetRef ref, List<DiaryEntry> diaries) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.67,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: diaries.length,
      itemBuilder: (context, index) {
        final entry = diaries[index];
        return _buildDiaryCard(context, ref, entry);
      },
    );
  }

  Widget _buildDiaryCard(
      BuildContext context, WidgetRef ref, DiaryEntry entry) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DiaryDetailPage(entry: entry)),
        ).then((_) {
          if (context.mounted) {
            ref.invalidate(diaryListProvider);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.themeColor(app_theme.ColorSemantic.border),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context
                  .themeColor(app_theme.ColorSemantic.border)
                  .withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: FutureBuilder<String>(
            future: ref.read(diaryListProvider.notifier).getCoverPath(entry),
            builder: (context, snapshot) {
              final hasCover = snapshot.hasData &&
                  snapshot.data!.isNotEmpty &&
                  File(snapshot.data!).existsSync();

              if (hasCover) {
                return Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildFallbackCover(context, entry),
                );
              }
              return _buildFallbackCover(context, entry);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(BuildContext context, DiaryEntry entry) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) {
        return context.themeColor(app_theme.ColorSemantic.primaryContainer);
      }
      final clean = hex.replaceAll('#', '');
      return Color(int.parse(clean, radix: 16) | 0xFF000000);
    }

    final c1 = parseColor(entry.coverColor1);
    final c2 = parseColor(entry.coverColor2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MM.dd').format(entry.createdAt),
              style: const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black45,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy').format(entry.createdAt),
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
