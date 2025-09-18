import 'package:flutter/material.dart';
import 'package:mama_meow/screens/navigationbar/home/home_screen.dart';
import 'package:mama_meow/screens/navigationbar/learn/learn_screen.dart';
import 'package:mama_meow/screens/navigationbar/meal-plan/meal_plan_screen.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/my_baby_screen.dart';
import 'package:mama_meow/screens/navigationbar/profile/profile_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MamaMeowHomePage(),
    MyBabyScreen(),
    LearnPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.pets, label: 'Ask Meow', index: 0),
              _buildNavItem(
                icon: Icons.child_friendly,
                label: 'My Baby',
                index: 1,
              ),
              _buildNavItem(icon: Icons.menu_book, label: 'Learn', index: 2),
              _buildNavItem(icon: Icons.person, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.pink.shade600 : Colors.grey.shade600;
    final bgColor = isSelected ? Colors.pink.shade50 : Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
