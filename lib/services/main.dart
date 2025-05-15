import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentaly/screens/home_page.dart';
import 'package:mentaly/screens/splash_screen.dart';
import 'package:mentaly/screens/login_page.dart';
import 'package:mentaly/screens/chat_page.dart';
//import 'package:mentaly/screens/note_screen.dart';
//import 'package:mentaly/screens/community_screen.dart';
import 'package:mentaly/screens/profile_screen.dart';
import 'package:mentaly/screens/register_page.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/db/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // DEBUG: Pastikan API key terbaca
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
      "❌ GEMINI_API_KEY is not loaded. Please check .env file and pubspec.yaml.",
    );
  } else {
    print("✅ GEMINI_API_KEY loaded: $apiKey");
  }

  // Inisialisasi DB
  Future(() async {
    try {
      await DatabaseHelper.instance.database;
      print("✅ Database ready");
    } catch (e) {
      print("❌ Database init failed: $e");
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentaly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(username: ''),
        // Hapus definisi route statis untuk ChatPage karena membutuhkan parameter
        //'/note_screen': (context) => const NoteScreen(),
        //'/community_screen': (context) => const CommunityScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
      },
      // Tambahkan onGenerateRoute untuk menangani route yang membutuhkan parameter
      onGenerateRoute: (settings) {
        print('Generating route for: ${settings.name}');

        // Handle route dengan parameter
        if (settings.name == '/chat' || settings.name == '/chat_page') {
          // Ambil argumen jika ada
          final args = settings.arguments as Map<String, dynamic>?;

          // Gunakan nilai default jika tidak ada argumen
          final username = args?['username'] as String? ?? 'Guest';
          final userId = args?['userId'] as int? ?? 0;

          return MaterialPageRoute(
            builder: (context) => ChatPage(username: username, userId: userId),
          );
        }

        // Fallback untuk route yang tidak terdaftar
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: Text('Route tidak ditemukan: ${settings.name}'),
                ),
              ),
        );
      },
      // Tambahkan onUnknownRoute sebagai fallback terakhir
      onUnknownRoute: (settings) {
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }
}
