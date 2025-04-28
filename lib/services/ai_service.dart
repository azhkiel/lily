import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  static const String _model = 'gemini-pro';

  static Future<String> getAIResponse(String message, int userId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Gemini API key not configured properly');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': message}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
        },
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get Gemini AI response: ${response.statusCode}');
    }
  }
}