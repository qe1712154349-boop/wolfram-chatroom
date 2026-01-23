// lib/pages/entrance/moments_detail_page.dart - 终极修复版
import 'package:flutter/material.dart';
import 'package:my_new_app/pages/friends_circle/publish_moment_page.dart';
import 'package:my_new_app/pages/friends_circle/camera_capture_page.dart';
import 'package:my_new_app/utils/asset_picker_util.dart';
import 'package:image_picker/image_picker.dart'; // XFile 来自这里

class MomentsDetailPage extends StatefulWidget {
  const MomentsDetailPage({super.key});

  @override
  State<MomentsDetailPage> createState() => _MomentsDetailPageState();
}

class _MomentsDetailPageState extends State<MomentsDetailPage> {
  bool _showActionSheet = false;

  void _showImageSourceActionSheet() {
    setState(() => _showActionSheet = true);
  }

  void _hideActionSheet() {
    setState(() => _showActionSheet = false);
  }

  Future<void> _openCamera() async {
    _hideActionSheet();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
  }

  Future<void> _pickFromGallery() async {
    _hideActionSheet();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final assets =
        await AssetPickerUtil.pickMultipleImagesDirectly(context, maxAssets: 9);
    if (assets == null || assets.isEmpty) return;

    final List<XFile> images = [];
    for (var asset in assets) {
      final file = await asset.originFile;
      if (file != null) images.add(XFile(file.path));
    }

    if (images.isEmpty) return;
    if (!mounted) return;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublishMomentPage(initialImages: images),
      ),
    );

    if (success == true && mounted) {
      debugPrint('发布成功，需要刷新朋友圈');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF060405) : const Color(0xFFF5F5F5),
          body: ListView(
            children: [
              Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://via.placeholder.com/800x400?text=Moments+Cover'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: _showImageSourceActionSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Row(
                      children: [
                        const Text(
                          "尘不言",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black45)
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  'https://via.placeholder.com/150'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMomentItem(
                context: context,
                avatar: 'https://via.placeholder.com/150',
                name: '',
                content: '',
                images: [],
                time: '4天前',
              ),
            ],
          ),
        ),
        if (_showActionSheet)
          GestureDetector(
            onTap: _hideActionSheet,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withAlpha(
                  _showActionSheet ? 102 : 0), // 替换 withValues(alpha: ...)
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                        0, _showActionSheet ? 0 : 200, 0),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActionItem(
                          icon: Icons.camera_alt_outlined,
                          title: '拍摄',
                          subtitle: '照片或视频',
                          onTap: _openCamera,
                          showDivider: true,
                        ),
                        _buildActionItem(
                          icon: Icons.photo_library_outlined,
                          title: '从相册选择',
                          subtitle: null,
                          onTap: _pickFromGallery,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    transform: Matrix4.translationValues(
                        0, _showActionSheet ? 0 : 200, 0),
                    margin:
                        const EdgeInsets.only(left: 12, right: 12, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildActionItem(
                      icon: null,
                      title: '取消',
                      subtitle: null,
                      onTap: _hideActionSheet,
                      showDivider: false,
                      isCancel: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData? icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
    required bool showDivider,
    bool isCancel = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isCancel ? Colors.red : const Color(0xFF333333),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                isCancel ? FontWeight.w400 : FontWeight.w500,
                            color:
                                isCancel ? Colors.red : const Color(0xFF333333),
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF888888)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 0.5,
            color: const Color(0xFFE0E0E0),
          ),
      ],
    );
  }

  Widget _buildMomentItem({
    required BuildContext context,
    required String avatar,
    required String name,
    required String content,
    required List<String> images,
    required String time,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: images.length == 1 ? 1 : 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length > 9 ? 9 : images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_horiz,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
