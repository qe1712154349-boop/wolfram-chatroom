// lib/pages/friends_circle/publish_moment_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart'; // ← 必须导入！XFile 来自这里
import '../../utils/asset_picker_util.dart';

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
  List<String> _imagePaths = [];
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('朋友圈'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _isCompressing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '发布',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5A7E),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(fontSize: 17, height: 1.6),
                decoration: const InputDecoration.collapsed(
                  hintText: '这一刻的想法...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 图片网格
            if (_imagePaths.isNotEmpty || _isCompressing)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isCompressing && _imagePaths.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // 谁可以看 等（保持原样）
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('谁可以看'),
                      trailing: const Text('公开'),
                      onTap: () {}),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('添加位置'),
                      onTap: () {}),
                  const Divider(height: 1),
                  ListTile(
                      leading: const Icon(Icons.notifications_none_outlined),
                      title: const Text('提醒谁看'),
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
