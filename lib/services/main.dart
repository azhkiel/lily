import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentaly/screens/splash_screen.dart';
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
      home: const SplashScreen(),
    );
  }
}
