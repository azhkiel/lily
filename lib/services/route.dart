import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentaly/screens/home/home_page.dart';
import 'package:mentaly/screens/home/note/note_page.dart';
import 'package:mentaly/screens/splash_screen.dart';
import 'package:mentaly/screens/auth/login_page.dart';
import 'package:mentaly/screens/home/chatbot/chatbot_page.dart';
import 'package:mentaly/screens/home/profile/profile_page.dart';
import 'package:mentaly/screens/auth/register_page.dart';
import 'package:mentaly/screens/home/chatbot/premium_screen.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/db/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Validasi dan print kunci API dari env
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print("GEMINI_API_KEY is not loaded. Please check .env file and pubspec.yaml.");
  } else {
    print("GEMINI_API_KEY loaded successfully.");
  }

  final midtransClientKey = dotenv.env['MIDTRANS_CLIENT_KEY'];
  if (midtransClientKey == null || midtransClientKey.isEmpty) {
    print("MIDTRANS_CLIENT_KEY is not loaded. Please check .env file.");
  } else {
    print("MIDTRANS_CLIENT_KEY loaded successfully.");
  }

  // Inisialisasi database sebelum runApp
  try {
    await DatabaseHelper.instance.database;
    print("Database initialized successfully.");
  } catch (e) {
    print("Database initialization failed: $e");
  }

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
        // Menambahkan username dan userId ke HomePage
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final username = args?['username'] as String? ?? '';
          final userId = args?['userId'] as int? ?? 0;
          return HomePage(username: username, userId: userId);
        },
        '/premium': (context) => const PremiumScreen(username: ''),
      },
      onGenerateRoute: (settings) {
        print('Generating route for: ${settings.name}');

        switch (settings.name) {
          case '/note_page':
            {
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              final userId = args['userId'] as int? ?? 0;
              return MaterialPageRoute(
                builder: (_) => NotepadListScreen(userId: userId),
              );
            }
          case '/chatbot_page':
            {
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              final username = args['username'] as String? ?? '';
              final userId = args['userId'] as int? ?? 0;
              return MaterialPageRoute(
                builder: (_) => ChatbotPage(
                  username: username,
                  userId: userId,
                ),
              );
            }
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Route tidak ditemukan: ${settings.name}'),
                ),
              ),
            );
        }
      },
      onUnknownRoute: (settings) {
        print('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      },
    );
  }
}
