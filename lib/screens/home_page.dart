import 'package:flutter/material.dart';
import 'package:mentaly/screens/chat_screen.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/widget/bottom_nav.dart';
import 'package:mentaly/db/database.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedMood = 'happy';
  String moodText = 'Mood kamu stabil';
  int mentalHealthPercentage = 45; // Mental health percentage

  final List<Map<String, dynamic>> moods = [
    {
      'label': 'angry',
      'assets': 'assets/angry.png',
      'desc': 'Kamu sangat marah!',
      'percentage': 0.3,
    },
    {
      'label': 'happy',
      'assets': 'assets/happy.png',
      'desc': 'Kamu sangat bahagia!',
      'percentage': 0.9,
    },
    {
      'label': 'sad',
      'assets': 'assets/sad.png',
      'desc': 'Kamu sedang sedih',
      'percentage': 0.5,
    },
    {
      'label': 'cry',
      'assets': 'assets/cry.png',
      'desc': 'Kamu sedang menangis!',
      'percentage': 0.2,
    },
  ];

  double _getPercentage() {
    return mentalHealthPercentage / 100;
  }

  // Doctor data
  final List<Doctor> doctors = [
    Doctor(
      name: 'Dr. Nagita Slavina',
      role: 'Dokter Psikolog',
      rating: 98,
      imageUrl: 'assets/doctor1.png',
    ),
    Doctor(
      name: 'Dr. Najwa Sihab',
      role: 'Dokter Psikolog',
      rating: 98,
      imageUrl: 'assets/doctor2.png',
    ),
    Doctor(
      name: 'Dr. Rizal Fauzi',
      role: 'Dokter Psikolog',
      rating: 95,
      imageUrl: 'assets/doctor3.png',
    ),
  ];

  // Article data
  final List<Article> articles = [
    Article(
      title: 'Capek Itu Pilihan, Tapi Sakit Itu Bukan Pilihan',
      imageUrl: 'assets/article1.png',
      description: 'Artikel mengenai kesehatan mental dan pentingnya istirahat',
    ),
  ];

  int _selectedIndex = 0; // Set to 0 (Home)

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on HomePage
        break;
      case 1:
        Navigator.pushNamed(context, '/note_screen');
        break;
      case 2:
        Navigator.pushNamed(context, '/chat_page');
        break;
      case 3:
        Navigator.pushNamed(context, '/community_screen');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile_screen');
        break;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Bar (time) is handled by the system

            // Header with User Name and Notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hai, Selamat Pagi!',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5D7C),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9EFFC),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF2C5D7C),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search Bar
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Apa yang Anda cari?',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mood Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFADE2F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagaimana suasana hatimu saat ini?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Ubah bagian ini di dalam Row untuk mood selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        moods.map((mood) {
                          final isSelected = selectedMood == mood['label'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMood = mood['label']!;
                                moodText = mood['desc']!;
                                mentalHealthPercentage =
                                    (mood['percentage'] * 100).toInt();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        )
                                        : null,
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.amber.shade100,
                              ),
                              // Ubah bagian ini dari mood['emoji']! menjadi Image.asset
                              child: Image.asset(
                                mood['asset'],
                                width: 40,
                                height: 40,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Persentase mental sehat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Container(
                            height: 10,
                            width:
                                MediaQuery.of(context).size.width *
                                _getPercentage() *
                                0.83,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selesaikan quest ini untuk kami tahu terkait mentalmu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showQuestDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'Selesaikan',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Doctor Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dokter Terbaik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5D7C),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      return DoctorCard(doctor: doctors[index]);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Artikel dan Informasi Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Artikel dan Informasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5D7C),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all articles screen
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Article card
            ArticleCard(article: articles[0]),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Note'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),

      // Floating action button in middle of bottom nav
      floatingActionButton: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/chat_page');
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Model untuk data dokter
class Doctor {
  final String name;
  final String role;
  final int rating;
  final String imageUrl;

  Doctor({
    required this.name,
    required this.role,
    required this.rating,
    required this.imageUrl,
  });
}

// Model untuk data artikel
class Article {
  final String title;
  final String imageUrl;
  final String description;

  Article({
    required this.title,
    required this.imageUrl,
    required this.description,
  });
}

// Widget untuk card dokter
class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(
              doctor.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              // Fallback jika gambar tidak ditemukan
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          // Doctor information
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5D7C),
                  ),
                ),
                Text(
                  doctor.role,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                // Rating indicator
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up,
                      color: Color(0xFF2C5D7C),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${doctor.rating}%",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5D7C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk card artikel
class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Article image (left)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.asset(
              article.imageUrl,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 120,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.article,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          // Article info (right)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5D7C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Chat assistant image
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/cry.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
