// lib/pages/friends_circle/camera_capture_page.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'publish_moment_page.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRearCamera = true;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
        (c) => _isRearCamera ? c.lensDirection == CameraLensDirection.back : c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(firstCamera, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('相机初始化失败: $e');
    }
  }

  Future<void> _takePicture() async {
  try {
    await _initializeControllerFuture;
    if (!_controller!.value.isInitialized) {
      debugPrint('相机未初始化');
      return;
    }
    
    final XFile photo = await _controller!.takePicture();
    if (!mounted) return;

    // 修复：显式提供两个类型参数
    final success = await Navigator.pushReplacement<bool, void>(
      context,
      MaterialPageRoute(
        builder: (_) => PublishMomentPage(initialImages: [photo]),
      ),
    );
    
    // 可选：处理发布结果（success 为 PublishMomentPage pop 时返回的 bool?）
    if (success == true) {
      debugPrint('发布成功');
      // 如果需要，可以在这里 pop 或刷新上层朋友圈
    }
  } catch (e) {
    debugPrint('拍照失败: $e');
  }
}

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || _controller == null || !_controller!.value.isInitialized) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('相机初始化失败', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initCamera,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }
            
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                // 控制栏（微信式底部）
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                        onPressed: () {
                          setState(() => _isFlashOn = !_isFlashOn);
                          _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
                        },
                      ),
                      FloatingActionButton(
                        backgroundColor: Colors.white,
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt, color: Color(0xFFFF5A7E)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: () {
                          setState(() => _isRearCamera = !_isRearCamera);
                          _initCamera();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('相机初始化失败: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            );
          }
        },
      ),
    );
  }
}