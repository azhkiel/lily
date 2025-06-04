import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentaly/screens/splash_screen.dart';
import 'package:mentaly/screens/onboarding_screen.dart';
import 'package:mentaly/screens/auth/login_page.dart';
import 'package:mentaly/screens/home/home_page.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize database
  try {
    await DatabaseHelper.instance.database;
    print("Database initialized successfully.");
  } catch (e) {
    print("Database initialization failed: $e");
  }

  // Check login status and navigate accordingly
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('username');
  final userId = prefs.getInt('userId');

  // Wait for the app initialization and decide the next screen
  runApp(MyApp(username: username, userId: userId));
}

class MyApp extends StatelessWidget {
  final String? username;
  final int? userId;

  const MyApp({super.key, this.username, this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentaly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(),
    );
  }

  // Check if the user is logged in or not, and navigate accordingly
  Widget _getInitialScreen() {
    // If the user is logged in, navigate to HomePage, else navigate to SplashScreen
    if (username != null && userId != null) {
      return HomePage(username: username!, userId: userId!);
    } else {
      return const SplashScreen();
    }
  }
}
