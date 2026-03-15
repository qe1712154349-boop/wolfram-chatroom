// lib/pages/entrance/entrance_main_page.dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart' as app_theme;
import 'moments_detail_page.dart';

class EntranceMainPage extends StatelessWidget {
  const EntranceMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sem = context.sem;

    return Scaffold(
      backgroundColor: sem.background,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + 100,
            color: sem.primary.withValues(alpha: 0.15),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: sem.textSecondary, size: 28),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MomentsDetailPage()));
                      },
                      child: Row(
                        children: [
                          Text("朋友圈",
                              style: TextStyle(
                                color: sem.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: sem.textSecondary),
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
                  color: sem.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
