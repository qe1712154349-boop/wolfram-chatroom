// lib/pages/friends_circle/publish_moment_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/asset_picker_util.dart';
import '../../theme/theme.dart' as app_theme;

class PublishMomentPage extends StatefulWidget {
  final List<XFile>? initialImages;

  const PublishMomentPage({super.key, this.initialImages});

  static Future<bool?> show(BuildContext context, {List<XFile>? images}) {
    return Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PublishMomentPage(initialImages: images),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> {
  final _textController = TextEditingController();
  final List<String> _imagePaths = [];
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      _compressAndAdd(widget.initialImages!);
    }
  }

  Future<void> _compressAndAdd(List<XFile> files) async {
    if (files.isEmpty) return;
    setState(() => _isCompressing = true);

    final paths = files.map((f) => f.path).toList();
    final compressed = await AssetPickerUtil.compressMultiple(paths);

    if (!mounted) return;
    setState(() {
      _imagePaths.addAll(compressed);
      _isCompressing = false;
    });
  }

  Future<void> _pickMore() async {
    final assets = await AssetPickerUtil.pickMultipleImagesDirectly(
      context,
      maxAssets: 9 - _imagePaths.length,
    );

    if (assets == null || assets.isEmpty) return;

    final List<XFile> files = [];
    for (var asset in assets) {
      final file = await asset.originFile;
      if (file != null) {
        files.add(XFile(file.path));
      }
    }

    if (files.isNotEmpty) await _compressAndAdd(files);
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;

    return Scaffold(
      backgroundColor: sem.background,
      appBar: AppBar(
        backgroundColor:
            context.themeColor(app_theme.ColorSemantic.appBarBackground),
        foregroundColor: context.themeColor(app_theme.ColorSemantic.appBarText),
        elevation: 0,
        title: const Text('朋友圈'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _isCompressing
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(sem.primary),
                      ),
                    )
                  : TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        '发布',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sem.primary,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // 文字区
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sem.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                autofocus: true,
                style: TextStyle(
                    fontSize: 17, height: 1.6, color: sem.textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: '这一刻的想法...',
                  hintStyle: TextStyle(color: sem.textHint),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 图片网格
            if (_imagePaths.isNotEmpty || _isCompressing)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sem.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isCompressing && _imagePaths.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(sem.primary),
                          ),
                        ),
                      )
                    : MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        itemCount: _imagePaths.length,
                        itemBuilder: (_, i) => RepaintBoundary(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ExtendedImage.file(
                                  File(_imagePaths[i]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                  cacheRawData: true,
                                ),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _imagePaths.removeAt(i)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

            // 加号
            if (!_isCompressing && _imagePaths.length < 9)
              GestureDetector(
                onTap: _pickMore,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: sem.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sem.border),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: sem.textSecondary),
                ),
              ),

            const SizedBox(height: 24),

            // 谁可以看 等
            Container(
              decoration: BoxDecoration(
                  color: sem.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                      leading:
                          Icon(Icons.lock_outline, color: sem.textSecondary),
                      title: Text('谁可以看',
                          style: TextStyle(color: sem.textPrimary)),
                      trailing: Text('公开',
                          style: TextStyle(color: sem.textSecondary)),
                      onTap: () {}),
                  Divider(height: 1, color: sem.divider),
                  ListTile(
                      leading: Icon(Icons.location_on_outlined,
                          color: sem.textSecondary),
                      title: Text('添加位置',
                          style: TextStyle(color: sem.textPrimary)),
                      onTap: () {}),
                  Divider(height: 1, color: sem.divider),
                  ListTile(
                      leading: Icon(Icons.notifications_none_outlined,
                          color: sem.textSecondary),
                      title: Text('提醒谁看',
                          style: TextStyle(color: sem.textPrimary)),
                      onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
