import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_page.dart';
import 'db/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi kritis saja di sini
  await dotenv.load(fileName: ".env").catchError((e) {
    print("Error loading .env: $e");
  });

  // Jalankan app tanpa blocking
  runApp(const MyApp());

  // Inisialisasi database di background
  Future(() async {
    try {
      await DatabaseHelper.instance.database;
      print("Database ready");
    } catch (e) {
      print("Database init failed: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}