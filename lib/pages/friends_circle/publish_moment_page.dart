// publish_moment_page.dart
import 'dart:io';
import 'dart:isolate';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../services/storage_service.dart';

class PublishMomentPage extends StatefulWidget {
  final List<XFile>? initialImages;

  const PublishMomentPage({super.key, this.initialImages});

  static Future<void> show(BuildContext context, {List<XFile>? images}) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PublishMomentPage(initialImages: images),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<PublishMomentPage> createState() => _PublishMomentPageState();
}

class _PublishMomentPageState extends State<PublishMomentPage> {
  final _textController = TextEditingController();
  List<String> _imagePaths = []; // 压缩后的本地路径
  bool _isCompressing = false;
  String _visibility = '公开'; // 公开 / 私密 / 分组...

  final StorageService _storage = StorageService();
  String _userName = '我';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    
    // 调试：打印平台信息
    print('=== 🚀 PublishMomentPage 初始化 ===');
    print('运行平台: ${Platform.operatingSystem}');
    print('是 Android 吗: ${Platform.isAndroid}');
    print('是 iOS 吗: ${Platform.isIOS}');
    
    _loadUserInfo();
    if (widget.initialImages != null && widget.initialImages!.isNotEmpty) {
      print('📱 接收到初始图片: ${widget.initialImages!.length} 张');
      _compressAndAdd(widget.initialImages!);
    } else {
      print('📱 无初始图片');
    }
  }

  Future<void> _loadUserInfo() async {
    final profile = await _storage.getUserProfile();
    setState(() {
      _userName = profile['name'] ?? '我';
      _userAvatar = profile['avatarPath'];
    });
  }

  Future<void> _compressAndAdd(List<XFile> files) async {
    print('\n=== 📸 开始压缩图片 ===');
    print('需要压缩的图片数量: ${files.length}');
    
    setState(() => _isCompressing = true);
    List<String> compressed = [];

    for (var i = 0; i < files.length; i++) {
      print('\n--- 处理第 ${i + 1} 张图片 ---');
      print('原文件路径: ${files[i].path}');
      
      final path = await _compressInIsolate(files[i].path);
      
      if (path != null) {
        compressed.add(path);
        print('✅ 压缩成功，保存到: $path');
      } else {
        print('❌ 压缩失败');
      }
    }

    print('\n=== 🎉 压缩完成 ===');
    print('成功: ${compressed.length}/${files.length} 张');
    
    setState(() {
      _imagePaths.addAll(compressed);
      _isCompressing = false;
    });
  }

  Future<String?> _compressInIsolate(String path) async {
    print('🎯 创建 Isolate 进行压缩...');
    
    final receivePort = ReceivePort();
    
    try {
      await Isolate.spawn(_isolateCompress, [receivePort.sendPort, path]);
      print('✅ Isolate 启动成功');
    } catch (e) {
      print('❌ 无法启动 Isolate: $e');
      return null;
    }
    
    final result = await receivePort.first as String?;
    print('🔚 Isolate 返回结果: ${result ?? "null"}');
    return result;
  }

  static void _isolateCompress(List<dynamic> args) async {
    final send = args[0] as SendPort;
    final path = args[1] as String;

    print('\n[Isolate] 🔧 开始处理文件: $path');
    
    try {
      // 1. 检查文件是否存在
      final file = File(path);
      final exists = await file.exists();
      print('[Isolate] 文件是否存在: $exists');
      
      if (!exists) {
        print('[Isolate] ❌ 文件不存在，中止压缩');
        send.send(null);
        return;
      }
      
      // 2. 获取文件信息
      final stat = await file.stat();
      final size = await file.length();
      print('[Isolate] 文件大小: ${size ~/ 1024} KB');
      print('[Isolate] 修改时间: ${stat.modified}');
      
      // 3. 尝试读取文件（验证可访问性）
      try {
        final testBytes = await file.readAsBytes();
        print('[Isolate] 文件可读取，字节数: ${testBytes.length}');
      } catch (e) {
        print('[Isolate] ❌ 文件无法读取: $e');
        send.send(null);
        return;
      }
      
      // 4. 尝试压缩
      print('[Isolate] 开始调用 compressAndGetFile...');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        '$path.compressed.jpg',
        quality: 75,
        minWidth: 1080,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        print('[Isolate] ✅ 压缩成功，输出路径: ${result.path}');
        
        // 验证输出文件
        final outputFile = File(result.path);
        if (await outputFile.exists()) {
          final outputSize = await outputFile.length();
          print('[Isolate] 输出文件大小: ${outputSize ~/ 1024} KB');
          print('[Isolate] 压缩率: ${(outputSize / size * 100).toStringAsFixed(1)}%');
        }
      } else {
        print('[Isolate] ❌ 压缩返回 null');
      }
      
      send.send(result?.path);
      
    } catch (e, stack) {
      print('[Isolate] ❌❌❌ 压缩过程中出错 ❌❌❌');
      print('[Isolate] 错误类型: ${e.runtimeType}');
      print('[Isolate] 错误信息: $e');
      print('[Isolate] 堆栈跟踪:');
      print(stack);
      print('[Isolate] 错误详情结束');
      
      send.send(null);
    }
    
    print('[Isolate] 🏁 处理完成');
  }

  Future<void> _pickMore() async {
    print('\n=== 📁 选择更多图片 ===');
    
    final picker = ImagePicker();
    final List<XFile>? more = await picker.pickMultiImage();
    
    if (more != null && more.isNotEmpty) {
      print('选择了 ${more.length} 张新图片');
      _compressAndAdd(more);
    } else {
      print('未选择图片');
    }
  }

  Future<void> _publish() async {
    if (_textController.text.trim().isEmpty && _imagePaths.isEmpty) {
      print('⚠️ 发布失败：无内容和图片');
      return;
    }

    print('\n=== 📤 发布动态 ===');
    print('文字内容: ${_textController.text}');
    print('图片数量: ${_imagePaths.length}');
    print('可见性: $_visibility');
    
    // TODO: 保存到你的后端或本地Moments列表
    // 例如：await _storage.saveMoment(...);

    print('✅ 发布成功，返回上一页');
    Navigator.pop(context, true); // 返回成功，刷新feed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('发布'),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text('发布', style: TextStyle(color: Color(0xFFFF5A7E), fontSize: 16)),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 文字输入区
            TextField(
              controller: _textController,
              maxLines: null,
              minLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '这一刻的想法...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),

            // 调试信息显示
            if (_isCompressing)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 12),
                    const Text('正在压缩图片...', style: TextStyle(color: Colors.blue)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bug_report, size: 18),
                      onPressed: () {
                        print('\n=== 🔍 手动触发调试 ===');
                        print('当前图片路径列表: $_imagePaths');
                        print('压缩状态: $_isCompressing');
                      },
                    ),
                  ],
                ),
              ),

            // 图片预览 + 重排
            if (_imagePaths.isNotEmpty || _isCompressing)
              _buildImageGrid(),

            if (!_isCompressing)
              GestureDetector(
                onTap: _pickMore,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            // 谁可以看
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('谁可以看'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_visibility, style: const TextStyle(color: Color(0xFFFF5A7E))),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                // TODO: show bottom sheet 选择 公开/私密/分组/三天可见等
                setState(() => _visibility = _visibility == '公开' ? '私密' : '公开'); // 临时toggle
              },
            ),

            // 占位：位置、提醒谁看、心情等
            ListTile(leading: const Icon(Icons.location_on), title: const Text('所在位置'), onTap: () {}),
            ListTile(leading: const Icon(Icons.alarm), title: const Text('提醒谁看'), onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _imagePaths.length + (_isCompressing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _imagePaths.length && _isCompressing) {
          return const Center(child: CircularProgressIndicator());
        }

        final path = _imagePaths[index];
        return GestureDetector(
          onLongPress: () {
            // 长按菜单：删除 / 替换
            showModalBottomSheet(
              context: context,
              builder: (_) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('删除'),
                    onTap: () {
                      print('🗑️ 删除图片: $path');
                      setState(() => _imagePaths.removeAt(index));
                      Navigator.pop(context);
                    },
                  ),
                  // 可加替换
                ],
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ExtendedImage.file(
              File(path),
              fit: BoxFit.cover,
              height: 120, // 固定高，masonry自适应宽
              cacheRawData: true,
            ),
          ),
        );
      },
    );
  }
}