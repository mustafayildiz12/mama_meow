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
  static const _tabs = [
    (imagePath: "assets/happy.png", label: 'Ask Meow'),
    (imagePath: "assets/baby.png", label: 'My Baby'),
    (imagePath: "assets/mic.png", label: 'Learn'),
    (imagePath: "assets/cat.png", label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService().checkAndShowUpdateIfNeeded(context);
    });
  }

  void _onTabTap(int index) {
    widget.navigationShell.goBranch(
      index,
      // Aynı sekmeye tekrar basınca sekmenin köküne dön.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell, // aktif branch burada render edilir
      // Arka plan home indicator'ın altına kadar uzanır, içerik güvenli
      // alanda kalır (iOS'ta etiketler home indicator altında kalmaz).
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
          color: Colors.white,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      imagePath: _tabs[i].imagePath,
                      label: _tabs[i].label,
                      isSelected: currentIndex == i,
                      onTap: () => _onTabTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.imagePath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.pink : Colors.grey.shade600;
    final bgColor = isSelected ? Colors.pink.shade50 : Colors.transparent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
