// lib/pages/entrance/entrance_main_page.dart - 完整替换
import 'package:flutter/material.dart';
import 'moments_detail_page.dart';

class EntranceMainPage extends StatelessWidget {
  const EntranceMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + 100,
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFE4E9),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.white70, size: 28),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsDetailPage()));
                      },
                      child: Row(
                        children: [
                          Text("朋友圈", 
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87, 
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              )),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: isDark ? Colors.grey[400] : Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "这里是入口页面\n后续功能可以在这里添加",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  color: isDark ? Colors.grey[400] : Colors.grey
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}