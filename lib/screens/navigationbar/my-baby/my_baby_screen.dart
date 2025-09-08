import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/add_sleep_bottom_sheet.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';

class MyBabyScreen extends StatelessWidget {
  const MyBabyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: 12),
                Icon(LucideIcons.baby, color: AppColors.pink500, size: 64),
                SizedBox(height: 8),
                Text(
                  "My Baby 👶",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "I may be small, but my stories are big! Don't miss a meowment! 🐾✨",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
          _babyCard(
            emoji: '🍼',
            title: 'Feeding',
            subtitle: 'Today: 0 times',
            gradient: LinearGradient(
              colors: [Colors.orange.shade200, Colors.yellow.shade200],
            ),
            textColor: Colors.orange.shade700,
            bgColor: Colors.orange.shade50,
            onPlusPressed: () {},
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: sleepService.todaySleepCountStream(),
            builder: (context, snapshot) {
              int sleepTime = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '😴',
                title: 'Sleep',
                subtitle: 'Today: $sleepTime times',
                gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.purple.shade200],
                ),
                textColor: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
                onPlusPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SleepExtendedMultiSliderBottomSheet(
                      initialStartEnds: [12 * 60, 15 * 60],
                      sleepDate: DateTime.now(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _babyCard(
            emoji: '👶',
            title: 'Diaper',
            subtitle: 'Today: 0 times',
            gradient: LinearGradient(
              colors: [Colors.green.shade200, Colors.tealAccent.shade200],
            ),
            textColor: Colors.green.shade700,
            bgColor: Colors.green.shade50,
            onPlusPressed: () {},
          ),
          const SizedBox(height: 16),
          _babyCard(
            emoji: '📏',
            title: 'Growth',
            subtitle: 'Today: 0 times',
            gradient: LinearGradient(
              colors: [Colors.pink.shade50, Colors.pink.shade100],
            ),
            textColor: Colors.pink.shade700,
            bgColor: Colors.pink.shade50,
            onPlusPressed: () {},
          ),
          const SizedBox(height: 16),
          _babyCard(
            emoji: '📔',
            title: 'Journal',
            subtitle: 'Today: 0 times',
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.indigo.shade200],
            ),
            textColor: Colors.purple.shade600,
            bgColor: Colors.purple.shade50,
            onPlusPressed: () {},
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade100, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Tips for Today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amberAccent, width: 2),
                  ),
                  child: const Text(
                    '💡 Tip of the day: Babies typically need 8-12 feedings per day. Watch for hunger cues like rooting or sucking motions!',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _babyCard({
    required String emoji,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required Color textColor,
    required Color bgColor,
    required void Function() onPlusPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(LucideIcons.barChart3, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        onPlusPressed();
                      },
                      icon: Icon(LucideIcons.plus, color: textColor, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "No records today",
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
