//lib/pages/diary/diary_editor_page.dart
import 'dart:convert';  // 修复1：改为 dart:convert
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/diary_provider.dart';
import '../../models/diary_entry.dart';  // 修复2：添加 DiaryEntry 的导入

class DiaryEditorPage extends ConsumerStatefulWidget {
  const DiaryEditorPage({this.entry, super.key});
  final DiaryEntry? entry;

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // 如果是编辑模式，加载现有内容
    if (widget.entry != null && widget.entry!.content.isNotEmpty) {
      try {
        // 尝试解析 JSON 内容
        final contentJson = json.decode(widget.entry!.content);
        if (contentJson is List && contentJson.isNotEmpty) {
          // 提取文本内容
          final text = _extractTextFromDelta(contentJson);
          _textController.text = text;
        } else {
          _textController.text = widget.entry!.content;
        }
      } catch (e) {
        // 如果解析失败，直接显示原始内容
        _textController.text = widget.entry!.content;
      }
    }
  }

  String _extractTextFromDelta(List<dynamic> delta) {
    String text = '';
    for (var element in delta) {
      if (element is Map && element.containsKey('insert')) {
        final insert = element['insert'];
        if (insert is String) {
          text += insert;
        }
      }
    }
    return text.trim();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDiary() async {
    if (_isSaving) return;
    
    final text = _textController.text.trim();
    
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日记内容不能为空'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 创建一个简单的 Delta JSON
      final deltaJson = [
        {'insert': '$text\n'}
      ];
      final contentStr = json.encode(deltaJson);

      if (widget.entry != null) {
        // 更新现有日记
        await ref.read(diaryListProvider.notifier).updateDiary(
              widget.entry!,
              contentStr,
            );
      } else {
        // 创建新日记
        await ref.read(diaryListProvider.notifier).addDiary(contentStr);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.entry != null ? '日记已更新' : '日记已保存'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        
        // 保存成功后返回
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF5A7E),
        title: Text(
          widget.entry != null ? '编辑日记' : '写日记',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveDiary,
              tooltip: '保存',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '今天发生了什么？写下你的心情...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A7E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saveDiary,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '保存日记',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}