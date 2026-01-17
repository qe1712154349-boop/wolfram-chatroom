// lib/pages/vow_page.dart - 完整替换
import 'package:flutter/material.dart';
import '../components/mood_day.dart';
import '../components/order_card.dart';
import '../app/theme.dart'; // 导入主题

class VowPage extends StatelessWidget {
  const VowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // 使用主题背景色
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 60),
          _buildTopHeader(context),
          const SizedBox(height: 25),
          Text("MOOD CALENDAR",
              style: TextStyle(
                letterSpacing: 1.5, 
                color: isDark ? Colors.grey[400] : Colors.grey, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white, 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                MoodDay(day: "Mon", emoji: "😊", hasMood: true),
                MoodDay(day: "Tue", emoji: "😴", hasMood: false),
                MoodDay(day: "Wed", emoji: "💖", hasMood: true),
                MoodDay(day: "Thu", emoji: "😶", hasMood: false),
                MoodDay(day: "Fri", emoji: "？", hasMood: false),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("ORDERS", 
              style: TextStyle(
                letterSpacing: 1.5, 
                color: isDark ? Colors.grey[400] : Colors.grey, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )),
          const SizedBox(height: 15),
          const OrderCard(title: "Wear the collar for 1 hour", subtitle: "Or else: No dessert", isLocked: true),
          const OrderCard(title: "Drink 2L of water", subtitle: "Stay hydrated", isLocked: false),
          const SizedBox(height: 20),
          _buildRewardsAccumulator(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("The Vow", 
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : const Color(0xFF4A4A4A)
                )),
            Text("☁ Collar Time: 12 days", 
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ],
        ),
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text("MASTER'S STATUS\nWorking late.", 
                style: TextStyle(
                  fontSize: 10, 
                  color: isDark ? Colors.grey[400] : Colors.grey
                )),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsAccumulator() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF5A7E), Color(0xFFFF8E9E)]),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("REWARDS ACCUMULATOR", style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text("0 Kisses Owed", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.favorite, color: Colors.white30, size: 40),
        ],
      ),
    );
  }
}