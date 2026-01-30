import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/service/app_update_service.dart';

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService().checkAndShowUpdateIfNeeded(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell, // aktif branch burada render edilir
      bottomNavigationBar: SafeArea(
        bottom: Platform.isAndroid ? true : false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _navItem(
                  context,
                  imagePath: "assets/happy.png",
                  label: 'Ask Meow',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
              ),
              Expanded(
                child: _navItem(
                  context,
                  imagePath: "assets/baby.png",
                  label: 'My Baby',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),
              ),
              Expanded(
                child: _navItem(
                  context,
                  imagePath: "assets/mic.png",
                  label: 'Learn',
                  index: 2,
                  isSelected: currentIndex == 2,
                ),
              ),
              Expanded(
                child: _navItem(
                  context,
                  imagePath: "assets/cat.png",
                  label: 'Profile',
                  index: 3,
                  isSelected: currentIndex == 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required String imagePath,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected ? Colors.pink : Colors.grey.shade600;
    final bgColor = isSelected ? Colors.pink.shade50 : Colors.transparent;

    return GestureDetector(
      onTap: () {
        widget.navigationShell.goBranch(
          index,
          // aynı tab’a tekrar basınca root’a dönmek istersen:
          initialLocation: index == widget.navigationShell.currentIndex,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 28, height: 28, color: color),
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
