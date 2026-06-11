import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:localmind_ai/core/widgets/floating_bottom_nav.dart';

class DashboardShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: const [
          FloatingBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
          FloatingBottomNavItem(icon: Icons.explore_outlined, label: 'Market'),
          FloatingBottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chats'),
          FloatingBottomNavItem(icon: Icons.book_outlined, label: 'Knowledge'),
          FloatingBottomNavItem(icon: Icons.download_outlined, label: 'Downloads'),
          FloatingBottomNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}
