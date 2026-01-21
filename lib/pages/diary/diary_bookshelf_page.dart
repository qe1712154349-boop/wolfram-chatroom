// lib/pages/diary/diary_bookshelf_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/diary_provider.dart';
import '../../models/diary_entry.dart';
import 'diary_editor_page.dart';
import 'diary_detail_page.dart';

class DiaryBookshelfPage extends ConsumerWidget {
  const DiaryBookshelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('📖 DiaryBookshelfPage 开始构建...');
    
    try {
      final diaries = ref.watch(diaryListProvider);
      print('✅ 成功获取日记数据，数量: ${diaries.length}');
      
      final isLoading = ref.watch(diaryListProvider).isEmpty && ref.read(diaryListProvider.notifier).state.isEmpty;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF5A7E),
          title: const Text(
            '我的日记书架',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => ref.refresh(diaryListProvider.notifier).loadAllDiaries(),
              tooltip: '刷新',
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF5A7E),
                ),
              )
            : diaries.isEmpty
                ? _buildEmptyState(context)
                : _buildBookshelfGrid(context, ref, diaries),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFF5A7E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DiaryEditorPage(),
              ),
            );
          },
          child: const Icon(Icons.add, size: 28),
        ),
      );
      
    } catch (e, stackTrace) {
      print('💥 DiaryBookshelfPage 构建时发生严重错误:');
      print('错误类型: ${e.runtimeType}');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      
      // 返回一个简单的错误页面，而不是崩溃
      return Scaffold(
        appBar: AppBar(
          title: const Text('日记本'),
          backgroundColor: const Color(0xFFFF5A7E),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                '日记本加载失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '错误: ${e.toString().split('\n').first}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A7E),
                ),
                child: const Text('返回', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            '日记书架空空如也',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角 + 写下第一篇日记吧',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5A7E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DiaryEditorPage(),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('开始写日记'),
              ],
            ),
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
      itemBuilder: (ctx, index) {
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
          MaterialPageRoute(
            builder: (_) => DiaryDetailPage(entry: entry),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<String>(
            future: ref.read(diaryListProvider.notifier).getCoverPath(entry),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data!.isNotEmpty &&
                  File(snapshot.data!).existsSync()) {
                return Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackCover(entry);
                  },
                );
              }
              return _buildFallbackCover(entry);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCover(DiaryEntry entry) {
    // 从十六进制颜色字符串解析为Color
    Color parseColor(String hexColor) {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse(hex, radix: 16) | 0xFF000000);
    }

    final color1 = entry.coverColor1 != null
        ? parseColor(entry.coverColor1!)
        : const Color(0xFFBAE1FF);
    final color2 = entry.coverColor2 != null
        ? parseColor(entry.coverColor2!)
        : const Color(0xFFFFB3BA);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
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
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black26,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy').format(entry.createdAt),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}