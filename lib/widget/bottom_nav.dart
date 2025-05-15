import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onLogoTap;

  const BottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onLogoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Content Goes Here')),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => onTap(0),
              icon: Image.asset(
                'assets/icons_home.png',
                color: currentIndex == 0 ? Colors.deepPurple : Colors.grey,
                height: 24,
              ),
            ),
            IconButton(
              onPressed: () => onTap(1),
              icon: Image.asset(
                'assets/icons_note.png',
                color: currentIndex == 1 ? Colors.deepPurple : Colors.grey,
                height: 24,
              ),
            ),
            const SizedBox(width: 40), // Space for center FAB
            IconButton(
              onPressed: () => onTap(3),
              icon: Image.asset(
                'assets/icons_community.png',
                color: currentIndex == 3 ? Colors.deepPurple : Colors.grey,
                height: 24,
              ),
            ),
            IconButton(
              onPressed: () => onTap(4),
              icon: Image.asset(
                'assets/icons_profile.png',
                color: currentIndex == 4 ? Colors.deepPurple : Colors.grey,
                height: 24,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        elevation: 4,
        onPressed: onLogoTap,
        child: Image.asset(
          'assets/logo.png', // Logo Mentaly dari assets
          height: 32,
          width: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
