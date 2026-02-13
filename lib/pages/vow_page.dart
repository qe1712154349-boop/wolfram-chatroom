// lib/pages/vow_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../components/mood_day.dart';
import '../components/order_card.dart';

class VowPage extends ConsumerWidget {
  const VowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sem = context.sem;

    return Container(
      color: sem.background,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 60),
          _buildTopHeader(context),
          const SizedBox(height: 25),
          Text(
            "MOOD CALENDAR",
            style: TextStyle(
              letterSpacing: 1.5,
              color: sem.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: sem.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MoodDay(day: "Mon", emoji: "😊", hasMood: true),
                MoodDay(day: "Tue", emoji: "😴", hasMood: false),
                MoodDay(day: "Wed", emoji: "💖", hasMood: true),
                MoodDay(day: "Thu", emoji: "😶", hasMood: false),
                MoodDay(day: "Fri", emoji: "？", hasMood: false),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "ORDERS",
            style: TextStyle(
              letterSpacing: 1.5,
              color: sem.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          const OrderCard(
              title: "Wear the collar for 1 hour",
              subtitle: "Or else: No dessert",
              isLocked: true),
          const OrderCard(
              title: "Drink 2L of water",
              subtitle: "Stay hydrated",
              isLocked: false),
          const SizedBox(height: 20),
          _buildRewardsAccumulator(context), // ← 加 (context)
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final sem = context.sem;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The Vow",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: sem.textPrimary,
              ),
            ),
            Text(
              "☁ Collar Time: 12 days",
              style: TextStyle(color: sem.primary),
            ),
          ],
        ),
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "MASTER'S STATUS\nWorking late.",
              style: TextStyle(
                fontSize: 10,
                color: sem.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsAccumulator(BuildContext context) {
    final sem = context.sem;

    final startColor = sem.primary;
    final endColor = startColor
        .withAlpha((255 * 0.85).round()); // 用 withAlpha 替换 withBrightness（如果冲突）

    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REWARDS ACCUMULATOR",
                style: TextStyle(
                  color: Colors.white.withAlpha((255 * 0.7).round()),
                  fontSize: 10,
                ),
              ),
              Text(
                "0 Kisses Owed",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.favorite,
            color: Colors.white.withAlpha((255 * 0.3).round()),
            size: 40,
          ),
        ],
      ),
    );
  }
}
