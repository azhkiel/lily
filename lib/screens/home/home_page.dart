import 'package:flutter/material.dart';
import 'package:mentaly/screens/home/note/note_page.dart';
import 'package:mentaly/screens/home/profile/profile_page.dart';
import 'chatbot/chatbot_page.dart';
import 'package:mentaly/widget/bottomNavBar.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;

  const HomePage({Key? key, required this.username, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedMood = 'happy';
  int mentalHealthPercentage = 45;

  final List<Map<String, dynamic>> moods = [
    {'label': 'angry', 'assets': 'assets/angry.png', 'percentage': 0.3},
    {'label': 'happy', 'assets': 'assets/happy.png', 'percentage': 0.9},
    {'label': 'sad', 'assets': 'assets/sad.png', 'percentage': 0.5},
    {'label': 'cry', 'assets': 'assets/cry.png', 'percentage': 0.2},
  ];

  int _selectedIndex = 0;

  void _showQuestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quest Harian'),
          content: const Text(
            'Terima kasih telah melengkapi quest harian! Persentase mental sehat Anda telah ditingkatkan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotepadListScreen(userId: widget.userId), // Pass userId to NotepadListScreen
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotepadListScreen(userId: widget.userId), // Pass userId to NotepadListScreen
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(), // Navigate to ProfileScreen
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header with User Name and Notification
            _buildHeader(),
            const SizedBox(height: 12),
            // Mood Section
            _buildMoodSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onBottomNavTapped,
        userId: widget.userId, // Pass userId to BottomNavBar
      ),
      // Floating action button in the middle of bottom nav
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatbotPage(
              username: widget.username, // Pass username
              userId: widget.userId,     // Pass userId - FIXED!
            ),
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        child: Image.asset('assets/logo.png', width: 30, height: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4.0),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hai, Selamat Pagi!', style: TextStyle(fontSize: 14)),
              Text(
                widget.username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C5D7C)),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFD9EFFC), borderRadius: BorderRadius.circular(25)),
            width: 46,
            height: 46,
            child: const Icon(Icons.notifications_outlined, color: Color(0xFF2C5D7C)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFADE2F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bagaimana suasana hatimu saat ini?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              final isSelected = selectedMood == mood['label'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMood = mood['label']!;
                    mentalHealthPercentage = (mood['percentage'] * 100).toInt();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                  ),
                  child: Image.asset(mood['assets'], width: 46, height: 46),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildMentalHealthProgress(),
        ],
      ),
    );
  }

  Widget _buildMentalHealthProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Persentase mental sehat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            Container(
              height: 8,
              width: MediaQuery.of(context).size.width * (mentalHealthPercentage / 100) * 0.7,
              decoration: BoxDecoration(color: const Color(0xFF2C5D7C), borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text('$mentalHealthPercentage%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C5D7C))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Selesaikan quest ini untuk kami tahu terkait mentalmu', style: TextStyle(fontSize: 12))),
            ElevatedButton(
              onPressed: _showQuestDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C5D7C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Selesaikan', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}