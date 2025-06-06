import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../db/database.dart';

class AIService {
  static String? _getApiKey() {
    return dotenv.env['GEMINI_API_KEY'];
  }
  
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // System prompt untuk AI sebagai chatbot mental health
  static const String _systemPrompt = '''
Kamu adalah LilyBot, asisten AI yang ramah dan empati untuk kesehatan mental. 
Tugasmu adalah:
1. Mendengarkan keluhan dan masalah pengguna dengan empati
2. Memberikan dukungan emosional dan motivasi positif
3. Menyarankan teknik coping yang sehat seperti breathing exercises, mindfulness, dll
4. Memberikan perspektif positif tanpa mengabaikan perasaan pengguna
5. Selalu mengingatkan untuk mencari bantuan profesional jika diperlukan

Gaya bicara:
- Gunakan bahasa Indonesia yang hangat dan supportif
- Hindari jargon medis yang rumit
- Berikan respons yang tidak terlalu panjang (maksimal 3-4 kalimat)
- Tunjukkan empati dan pengertian
- Gunakan emoji yang sesuai untuk menambah kehangatan

Jangan:
- Memberikan diagnosis medis
- Meresepkan obat atau treatment spesifik
- Mengabaikan atau meremehkan perasaan pengguna
- Memberikan saran yang berbahaya

Selalu prioritaskan keamanan dan kesejahteraan pengguna.
''';

  static Future<String> getAIResponse(String message, int userId) async {
    final apiKey = _getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not configured or missing in .env');
    }

    // Validasi input message
    if (!_isValidMessage(message)) {
      throw Exception('Pesan tidak valid atau terlalu panjang');
    }

    final cleanedMessage = _cleanMessage(message);

    try {
      // Ambil context chat sebelumnya untuk conversation continuity
      final chatHistory = await _getChatHistory(userId);
      
      // Build conversation context
      final conversationContext = await _buildConversationContext(chatHistory, cleanedMessage);
      
      final uri = Uri.parse("$_baseUrl/$_model:generateContent?key=$apiKey");

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": conversationContext,
              "systemInstruction": {
                "parts": [
                  {"text": _systemPrompt}
                ]
              },
              "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024,
                "stopSequences": []
              },
              "safetySettings": [
                {
                  "category": "HARM_CATEGORY_HARASSMENT",
                  "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                  "category": "HARM_CATEGORY_HATE_SPEECH",
                  "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                  "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                  "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                },
                {
                  "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                  "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle berbagai kemungkinan response structure
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // Check if blocked by safety filters
          if (candidate['finishReason'] == 'SAFETY') {
            return _getSafetyFallbackResponse();
          }
          
          final content = candidate['content']?['parts']?[0]?['text'];
          if (content != null && content.toString().trim().isNotEmpty) {
            return content.toString().trim();
          }
        }
        
        // Fallback jika tidak ada content yang valid
        return _getDefaultFallbackResponse();
        
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        throw Exception('Terlalu banyak permintaan. Silakan tunggu sebentar dan coba lagi.');
        
      } else if (response.statusCode == 402) {
        // Payment required (jika menggunakan paid API)
        throw Exception('402');
        
      } else {
        // Parse error response untuk info lebih detail
        String errorMessage = 'Gagal mendapatkan respons dari AI';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error']?['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (e) {
          // Jika tidak bisa parse error, gunakan status code
          errorMessage = 'Error ${response.statusCode}: ${response.reasonPhrase}';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Silakan periksa koneksi internet Anda.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else {
        rethrow;
      }
    }
  }

  // Ambil history chat untuk context - disesuaikan dengan struktur database yang ada
  static Future<List<Map<String, dynamic>>> _getChatHistory(int userId) async {
    try {
      // Ambil chat dari database menggunakan method yang sudah ada
      final allChats = await DatabaseHelper.instance.getChatsByUserWithUsername(userId);
      
      // Ambil maksimal 10 chat terakhir untuk context (tidak terlalu banyak agar tidak exceed token limit)
      final recentChats = allChats.length > 10 
          ? allChats.sublist(allChats.length - 10)
          : allChats;
      
      return recentChats;
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  // Build conversation context untuk Gemini API - disesuaikan dengan struktur database
  static Future<List<Map<String, dynamic>>> _buildConversationContext(
    List<Map<String, dynamic>> chatHistory, 
    String currentMessage
  ) async {
    List<Map<String, dynamic>> contents = [];

    // Tambahkan chat history sebagai context
    for (var chat in chatHistory) {
      // Tambahkan pesan user jika ada
      if (chat['message_user'] != null && (chat['message_user'] as String).isNotEmpty) {
        contents.add({
          "role": "user",
          "parts": [
            {"text": chat['message_user'] as String}
          ]
        });
      }

      // Tambahkan pesan AI jika ada
      if (chat['message_ai'] != null && (chat['message_ai'] as String).isNotEmpty) {
        contents.add({
          "role": "model",
          "parts": [
            {"text": chat['message_ai'] as String}
          ]
        });
      }
    }

    // Tambahkan pesan current
    contents.add({
      "role": "user",
      "parts": [
        {"text": currentMessage}
      ]
    });

    return contents;
  }

  // Response fallback untuk safety blocks
  static String _getSafetyFallbackResponse() {
    return "Maaf, saya tidak bisa merespons pesan tersebut. Mari kita bicarakan hal lain yang bisa membantu kesehatan mental kamu. Ada yang ingin kamu ceritakan tentang perasaanmu hari ini? 😊";
  }

  // Response fallback default
  static String _getDefaultFallbackResponse() {
    return "Maaf, saya mengalami sedikit kesulitan memahami pesan kamu. Bisakah kamu coba ulangi dengan kata-kata yang berbeda? Saya di sini untuk mendengarkan dan membantu kamu 💙";
  }

  // Fungsi untuk mengecek kesehatan API
  static Future<bool> checkAPIHealth() async {
    try {
      final response = await getAIResponse("Hello", 0);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Fungsi untuk mendapatkan saran coping mechanism
  static Future<String> getCopingAdvice(String emotion, int userId) async {
    final message = "Saya sedang merasa $emotion. Bisakah kamu berikan saran untuk mengatasinya?";
    return await getAIResponse(message, userId);
  }

  // Fungsi untuk mindfulness reminder
  static Future<String> getMindfulnessReminder(int userId) async {
    final message = "Bisakah kamu berikan teknik mindfulness singkat untuk membantu saya rileks?";
    return await getAIResponse(message, userId);
  }

  // Fungsi untuk breathing exercise
  static Future<String> getBreathingExercise(int userId) async {
    final message = "Saya butuh teknik pernapasan untuk menenangkan diri. Bisakah kamu pandu saya?";
    return await getAIResponse(message, userId);
  }

  // Fungsi untuk motivational support
  static Future<String> getMotivationalSupport(int userId) async {
    final message = "Saya sedang merasa down dan butuh motivasi. Bisakah kamu memberikan semangat?";
    return await getAIResponse(message, userId);
  }

  // Fungsi untuk emergency support
  static String getEmergencySupport() {
    return '''
Jika kamu sedang dalam krisis atau memiliki pikiran untuk menyakiti diri sendiri:

🆘 Hubungi segera:
• Hotline Kesehatan Mental: 119 ext 8
• Halo Kemkes: 1500-567
• Sejiwa: 119 ext 8 atau WhatsApp ke 0813-1000-1947

💙 Ingat: Kamu tidak sendirian. Ada bantuan yang tersedia 24/7.

Jika ini bukan keadaan darurat, mari kita bicarakan perasaan kamu dengan tenang.
''';
  }

  // Fungsi untuk validasi input pesan
  static bool _isValidMessage(String message) {
    return message.trim().isNotEmpty && message.length <= 2000;
  }

  // Fungsi untuk clean input message
  static String _cleanMessage(String message) {
    return message.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Fungsi helper untuk mendapatkan jumlah chat hari ini
  static Future<int> getTodayChatCount(int userId) async {
    try {
      final chats = await DatabaseHelper.instance.getChatsByUser(userId);
      final today = DateTime.now();
      
      int count = 0;
      for (var chat in chats) {
        final chatDate = DateTime.parse(chat['timestamp'] as String);
        if (chatDate.year == today.year && 
            chatDate.month == today.month && 
            chatDate.day == today.day) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('Error getting today chat count: $e');
      return 0;
    }
  }

  // Fungsi untuk mendapatkan insights berdasarkan pola chat
  static Future<String> getChatInsights(int userId) async {
    try {
      final chatCount = await DatabaseHelper.instance.getChatCountByUser(userId);
      final todayCount = await getTodayChatCount(userId);
      
      if (chatCount == 0) {
        return "Ini adalah awal perjalanan kamu dengan LilyBot! Mari mulai dengan menceritakan bagaimana perasaan kamu hari ini 😊";
      } else if (todayCount > 5) {
        return "Terima kasih sudah sering berinteraksi hari ini! Ingat untuk juga beristirahat dan melakukan aktivitas lain yang menyenangkan ya 💙";
      } else if (chatCount > 50) {
        return "Wah, kamu sudah cukup sering chat dengan saya! Semoga percakapan kita selama ini membantu kamu merasa lebih baik 🌟";
      } else {
        return "Senang bisa terus menemani perjalanan kamu. Ada yang ingin kamu ceritakan hari ini? 😊";
      }
    } catch (e) {
      return "Mari kita lanjutkan percakapan kita! Ada yang bisa saya bantu hari ini? 😊";
    }
  }
}