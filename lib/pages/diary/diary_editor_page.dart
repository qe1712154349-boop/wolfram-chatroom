import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/diary_provider.dart';
import '../../models/diary_entry.dart';
import '../../theme/theme.dart' as app_theme;

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

    if (widget.entry != null && widget.entry!.content.isNotEmpty) {
      try {
        final contentJson = json.decode(widget.entry!.content);
        if (contentJson is List && contentJson.isNotEmpty) {
          final text = _extractTextFromDelta(contentJson);
          _textController.text = text;
        } else {
          _textController.text = widget.entry!.content;
        }
      } catch (e) {
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
        SnackBar(
          content: const Text('日记内容不能为空'),
          backgroundColor: context.themeColor(app_theme.ColorSemantic.warning),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final deltaJson = [
        {'insert': '$text\n'}
      ];
      final contentStr = json.encode(deltaJson);

      if (widget.entry != null) {
        await ref.read(diaryListProvider.notifier).updateDiary(
              widget.entry!,
              contentStr,
            );
      } else {
        await ref.read(diaryListProvider.notifier).addDiary(contentStr);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry != null ? '日记已更新' : '日记已保存'),
            backgroundColor:
                context.themeColor(app_theme.ColorSemantic.success),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: context.themeColor(app_theme.ColorSemantic.error),
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
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        title: Text(
          widget.entry != null ? '编辑日记' : '写日记',
          style: TextStyle(
            color: context.themeColor(app_theme.ColorSemantic.appBarText),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        context.themeColor(app_theme.ColorSemantic.appBarText),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.save,
                color: context.themeColor(app_theme.ColorSemantic.appBarText),
              ),
              onPressed: _saveDiary,
              tooltip: '保存',
            ),
        ],
      ),
      backgroundColor: context.themeColor(app_theme.ColorSemantic.background),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.themeColor(app_theme.ColorSemantic.surface),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.themeColor(app_theme.ColorSemantic.border),
                  ),
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
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '今天发生了什么？写下你的心情...',
                      hintStyle: TextStyle(
                        color: context
                            .themeColor(app_theme.ColorSemantic.textHint),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: context
                          .themeColor(app_theme.ColorSemantic.textPrimary),
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
                  backgroundColor:
                      context.themeColor(app_theme.ColorSemantic.buttonPrimary),
                  foregroundColor: context
                      .themeColor(app_theme.ColorSemantic.buttonPrimaryText),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saveDiary,
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.themeColor(
                              app_theme.ColorSemantic.buttonPrimaryText),
                        ),
                      )
                    : const Text(
                        '保存日记',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
