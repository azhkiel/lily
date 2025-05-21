import 'package:flutter/material.dart';
import 'chatbot_page.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/widget/bottom_nav.dart';
import 'package:mentaly/db/database.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedMood = 'happy';
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
      name: 'Dr. Ravelya Fenwick',
      role: 'Dokter Psikolog',
      rating: 95,
      imageUrl: 'assets/doctor3.png',
    ),
  ];

  // Article data
  final List<Article> articles = [
    Article(
      title: 'Capek Itu Pilihan, Tapi Bunuh Diri Itu Bukan Pilihan',
      imageUrl: 'assets/article1.png',
      description:
          'Capek adalah pilihan yang bisa kadaluwarsa dengan istirahat, tapi bunuh diri itu tidak, yang menutup semua kemungkinan...',
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
        Navigator.pushNamed(context, '/note_page');
        break;
      case 2:
        // Center button - handled by FAB
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
          padding: EdgeInsets.zero,
          children: [
            // Header with User Name and Notification
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hai, Selamat Pagi!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
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
                        width: 46,
                        height: 46,
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF2C5D7C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Apa yang Anda cari?',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mood Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  // Mood selection with emojis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        moods.map((mood) {
                          final isSelected = selectedMood == mood['label'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMood = mood['label']!;
                                mentalHealthPercentage =
                                    (mood['percentage'] * 100).toInt();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        )
                                        : null,
                              ),
                              child: Image.asset(
                                mood['assets'],
                                width: 46,
                                height: 46,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
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
                      const SizedBox(height: 5),
                      // Progress bar for mental health percentage
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 8,
                            width:
                                MediaQuery.of(context).size.width *
                                (mentalHealthPercentage / 100) *
                                0.7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C5D7C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Percentage text
                      Text(
                        '$mentalHealthPercentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C5D7C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Selesaikan quest ini untuk kami tahu terkait mentalmu',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showQuestDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5D7C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Selesaikan',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Doctor Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dokter Terbaik',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5D7C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
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
            ),

            const SizedBox(height: 20),

            // Artikel dan Informasi Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Artikel dan Informasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5D7C),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C5D7C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Article card
            ArticleCard(article: articles[0]),

            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 2 ? 0 : _selectedIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2C5D7C),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Note'),
          BottomNavigationBarItem(
            icon: SizedBox(width: 24), // Empty space for FAB
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),

      // Floating action button in middle of bottom nav
      floatingActionButton: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          elevation: 0,
          onPressed: () {
            try {
              Navigator.pushNamed(context, '/chatbot_page');
            } catch (e) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            }
          },
          child: Image.asset(
            'assets/logo.png',
            width: 30,
            height: 30,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.chat, color: Colors.white);
            },
          ),
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
      margin: const EdgeInsets.only(right: 10),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            child: Stack(
              children: [
                Image.asset(
                  doctor.imageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 110,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
                // Warning banner at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: const Text(
                      'BOTTOM OVERFLOWED BY 4.0 PIXELS',
                      style: TextStyle(fontSize: 8, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Doctor information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              width: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.article,
                    size: 40,
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
                    'Capek adalah pilihan yang bisa kadaluwarsa dengan istirahat, tapi bunuh diri itu tidak, yang menutup semua kemungkinan...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Read more link
                  Text(
                    'Lihat selengkapnya',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
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
