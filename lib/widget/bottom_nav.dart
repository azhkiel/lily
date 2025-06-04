import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onLogoTap;
  final Widget body;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onLogoTap,
    required this.body,
  }) : super(key: key);

  static const _iconSize = 24.0;
  static const _fabSize = 32.0;
  static const _notchMargin = 8.0;

  static const List<_NavItem> _navItems = [
    _NavItem(asset: 'assets/icons_home.png', index: 0, tooltip: 'Home'),
    _NavItem(asset: 'assets/icons_note.png', index: 1, tooltip: 'Notes'),
    _NavItem(asset: 'assets/icons_community.png', index: 3, tooltip: 'Community'),
    _NavItem(asset: 'assets/icons_profile.png', index: 4, tooltip: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: _notchMargin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ..._navItems.take(2).map(_buildNavIcon).toList(),
            const SizedBox(width: 40), // ruang FAB
            ..._navItems.skip(2).map(_buildNavIcon).toList(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: onLogoTap,
        child: Image.asset(
          'assets/logo.png',
          height: _fabSize,
          width: _fabSize,
          errorBuilder: (_, __, ___) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildNavIcon(_NavItem item) {
    final isSelected = currentIndex == item.index;
    return Expanded(
      child: Tooltip(
        message: item.tooltip,
        child: IconButton(
          onPressed: () => onTap(item.index),
          icon: Image.asset(
            item.asset,
            color: isSelected ? Colors.deepPurple : Colors.grey,
            height: _iconSize,
            errorBuilder: (_, __, ___) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String asset;
  final int index;
  final String tooltip;

  const _NavItem({
    required this.asset,
    required this.index,
    required this.tooltip,
  });
}
