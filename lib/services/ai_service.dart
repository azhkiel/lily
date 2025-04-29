import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static final String? _apiKey = dotenv.env['DEEPSEEK_API_KEY'];
  static const String _model = 'deepseek-chat';

  static Future<String> getAIResponse(String message, int userId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('DeepSeek API key not configured properly');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': message,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get DeepSeek AI response: ${response.statusCode} - ${response.body}');
    }
  }
}