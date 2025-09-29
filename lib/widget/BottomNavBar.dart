import 'package:flutter/material.dart';
import 'package:mentaly/screens/home/home_page.dart';
import 'package:mentaly/screens/home/note/note_page.dart';
import 'package:mentaly/screens/home/profile/profile_page.dart';
import 'package:mentaly/screens/home/chatbot/chatbot_page.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final int userId;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2C5D7C),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.note_rounded), label: 'Note'),
        BottomNavigationBarItem(icon: SizedBox(width: 24), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
