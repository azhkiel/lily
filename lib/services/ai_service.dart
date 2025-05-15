import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Ubah ke metode yang diakses saat runtime, bukan saat kompilasi
  static String? _getApiKey() {
    return dotenv.env['GEMINI_API_KEY'];
  }

  static const String _model = 'gemini-2.0-flash'; // sesuai dari Google
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static Future<String> getAIResponse(String message, int userId) async {
    final apiKey = _getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not configured or missing in .env');
    }

    final uri = Uri.parse("$_baseUrl/$_model:generateContent?key=$apiKey");

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": message},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Menangani response Gemini
      final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (content != null) {
        return content;
      } else {
        throw Exception("Response OK tapi tidak berisi teks jawaban.");
      }
    } else {
      throw Exception(
        'Gagal mendapatkan respons dari Gemini: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
