import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/service/app_update_service.dart';

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  // Sıra ve etiketler router branch'leri ve entegrasyon testiyle eşleşir.
  static const _tabs = [
    (
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      label: 'Ask Meow',
    ),
    (
      icon: Icons.child_care_outlined,
      selectedIcon: Icons.child_care,
      label: 'My Baby',
    ),
    (
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      label: 'Learn',
    ),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
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
          color: AppColors.cottonWhite,
          border: Border(top: BorderSide(color: AppColors.hairline)),
          boxShadow: AppColors.floatShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].icon,
                      selectedIcon: _tabs[i].selectedIcon,
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

/// Alt menü öğesi: seçiliyken pembe hap içinde berry ikon + etiket.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected
        ? AppColors.activeBerry
        : AppColors.charcoalSoft;
    final labelColor = isSelected ? AppColors.berryInk : AppColors.charcoalSoft;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // heightFactor: 1 → yalnızca içerik kadar yükseklik; aksi halde Scaffold
        // alt menüye tüm ekranı verir ve sekme içerikleri görünmez olur.
        child: Center(
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            // 360 px genişlikte de "Ask Meow" sığsın diye yatayda 14 px.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              color: isSelected ? AppColors.pinkTint : Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: iconColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: labelColor,
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
