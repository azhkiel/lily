import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentaly/screens/home_page.dart';
import 'package:mentaly/screens/note_page.dart';
import 'package:mentaly/screens/splash_screen.dart';
import 'package:mentaly/screens/login_page.dart';
import 'package:mentaly/screens/chatbot_page.dart';
//import 'package:mentaly/screens/community_screen.dart';
import 'package:mentaly/screens/profile_screen.dart';
import 'package:mentaly/screens/register_page.dart';
import 'package:mentaly/screens/premium_screen.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/db/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
      "GEMINI_API_KEY is not loaded. Please check .env file and pubspec.yaml.",
    );
  } else {
    print("GEMINI_API_KEY loaded: $apiKey");
  }

  final midtransClientKey = dotenv.env['MIDTRANS_CLIENT_KEY'];
  if (midtransClientKey == null || midtransClientKey.isEmpty) {
    print("MIDTRANS_CLIENT_KEY is not loaded. Please check .env file.");
  } else {
    print("MIDTRANS_CLIENT_KEY loaded");
  }

  Future(() async {
    try {
      await DatabaseHelper.instance.database;
      print("Database ready");
    } catch (e) {
      print("Database init failed: $e");
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
        '/premium': (context) => const PremiumScreen(username: ''),
        '/note_page': (context) => const NotePage(), // ✅ Ini sudah benar
        //'/community_screen': (context) => const CommunityScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        print('Generating route for: ${settings.name}');

        if (settings.name == '/chat' || settings.name == '/chatbot_page') {
          final args = settings.arguments as Map<String, dynamic>?;
          final username = args?['username'] as String?;
          final userId = args?['userId'] as int? ?? 0;

          return MaterialPageRoute(builder: (context) => ChatbotPage());
        }

        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: Text('Route tidak ditemukan: ${settings.name}'),
                ),
              ),
        );
      },
      onUnknownRoute: (settings) {
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const SplashScreen());
      },
    );
  }
}
