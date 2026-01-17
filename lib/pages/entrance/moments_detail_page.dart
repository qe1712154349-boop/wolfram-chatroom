// lib/pages/entrance/moments_detail_page.dart - 完整替换
import 'package:flutter/material.dart';

class MomentsDetailPage extends StatelessWidget {
  const MomentsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060405) : const Color(0xFFF5F5F5),
      body: ListView(
        children: [
          Stack(
            children: [
              Container(
                height: 300,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/800x400?text=Moments+Cover'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white), 
                        onPressed: () => Navigator.pop(context)
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white), 
                        onPressed: () {}
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
                    const Text("尘不言", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          shadows: [Shadow(blurRadius: 10, color: Colors.black45)]
                        )),
                    const SizedBox(width: 15),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: NetworkImage('https://via.placeholder.com/150'), 
                          fit: BoxFit.cover
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
                Text(name, 
                    style: TextStyle(
                      color: Theme.of(context).primaryColor, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    )),
                const SizedBox(height: 8),
                Text(content, 
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black
                    )),
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
                            fit: BoxFit.cover
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
                    Text(time, 
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey, 
                          fontSize: 13
                        )),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: isDark ? Colors.grey[400] : Colors.grey), 
                      onPressed: () {}
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