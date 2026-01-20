// lib/pages/friends_circle/publish_moment_page.dart - 终极修复版：并行压缩 + 路径校验 + 美观进度 + 渐进预览
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:image/image.dart' as img_lib;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/storage_service.dart';

class PublishMomentPage extends StatefulWidget {
  final List<XFile>? initialImages;
  const PublishMomentPage({super.key, this.initialImages});

  static Future<bool?> show(BuildContext context, {List<XFile>? images}) {
    return Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PublishMomentPage(initialImages: images),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  List<String> _imagePaths = [];
  bool _isCompressing = false;
  double _compressProgress = 0.0; // 0~1 进度
  late AnimationController _progressAnim;
  String _visibility = '公开';
  final StorageService _storage = StorageService();
  String _userName = '我';
  String? _userAvatar;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _loadUserInfo();
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      _addImages(widget.initialImages!);
    }
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final profile = await _storage.getUserProfile();
    if (mounted) setState(() {
      _userName = profile['name'] ?? '我';
      _userAvatar = profile['avatarPath'];
    });
  }

  // 并行批量压缩（Future.wait 最高效）
  Future<void> _addImages(List<XFile> files) async {
    if (files.isEmpty) return;
    setState(() {
      _isCompressing = true;
      _compressProgress = 0.0;
    });

    final futures = files.asMap().entries.map((entry) async {
      final idx = entry.key;
      final file = entry.value;
      final path = await compute(_compressImageIsolate, {
        'path': file.path,
        'index': idx,
        'total': files.length,
      });
      if (path != null && await File(path).exists()) {
        setState(() {
          _imagePaths.add(path);
          _compressProgress = (_imagePaths.length / files.length);
        });
      } else {
        debugPrint('压缩失败，使用原图: ${file.path}');
        setState(() => _imagePaths.add(file.path));
      }
    });

    await Future.wait(futures);
    if (mounted) setState(() => _isCompressing = false);
  }

  // Isolate 压缩函数（静态）
  static Future<String?> _compressImageIsolate(Map<String, dynamic> params) async {
    final path = params['path'] as String;
    try {
      final bytes = await File(path).readAsBytes();
      final image = img_lib.decodeImage(bytes);
      if (image == null) return null;

      final resized = img_lib.copyResize(
        image,
        width: 1080,
        interpolation: img_lib.Interpolation.cubic,
      );

      final fileSizeKB = bytes.length / 1024;
      final quality = fileSizeKB > 2048 ? 70 : 85;

      final compressedBytes = img_lib.encodeJpg(resized, quality: quality);

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outputPath).writeAsBytes(compressedBytes);

      debugPrint('压缩成功: $outputPath, 大小: ${(compressedBytes.length / 1024).toStringAsFixed(1)} KB');
      return outputPath;
    } catch (e) {
      debugPrint('Isolate 压缩失败: $e');
      return null;
    }
  }

  Future<void> _pickMore() async {
    final List<XFile>? more = await _picker.pickMultiImage(
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 88,
      limit: 9 - _imagePaths.length,
    );
    if (more != null && more.isNotEmpty) await _addImages(more);
  }

  Future<void> _publish() async {
    if (_textController.text.trim().isEmpty && _imagePaths.isEmpty) return;
    // TODO: 保存
    Navigator.pop(context, true);
  }

  void _deleteImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: const Text('发布'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _isCompressing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (_, __) => CircularProgressIndicator(
                          value: _compressProgress,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5A7E).withOpacity(0.7 + 0.3 * _progressAnim.value)),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _publish,
                      child: const Text('发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF5A7E))),
                    ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _textController,
                maxLines: null,
                minLines: 4,
                autofocus: true,
                style: const TextStyle(fontSize: 16, height: 1.6),
                decoration: const InputDecoration.collapsed(
                  hintText: '分享今天的心情吧...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_imagePaths.isNotEmpty || _isCompressing)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: _isCompressing && _imagePaths.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                    : MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          final path = _imagePaths[index];
                          return _ImagePreview(
                            path: path,
                            onDelete: () => _deleteImage(index),
                          );
                        },
                      ),
              ),

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
                  child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('谁可以看'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_visibility),
                      const Icon(Icons.keyboard_arrow_right),
                    ]),
                    onTap: () {
                      setState(() => _visibility = _visibility == '公开' ? '私密' : '公开');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('添加位置'),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_outlined),
                    title: const Text('提醒谁看'),
                    trailing: const Icon(Icons.keyboard_arrow_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const _ImagePreview({required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ExtendedImage.file(
            File(path),
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
            cacheRawData: true,
            loadStateChanged: (ExtendedImageState state) {
              switch (state.extendedImageLoadState) {
                case LoadState.loading:
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                case LoadState.completed:
                  return null;
                case LoadState.failed:
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error, color: Colors.red),
                  );
              }
            },
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}