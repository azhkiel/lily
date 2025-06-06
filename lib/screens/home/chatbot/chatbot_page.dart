import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'premium_screen.dart';
import 'package:mentaly/models/chat.dart';
import '../../../db/database.dart';
import '../../../services/ai_service.dart';

class ChatbotPage extends StatefulWidget {
  final String username;
  final int userId;

  const ChatbotPage({Key? key, required this.username, required this.userId})
      : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Inisialisasi chat - load chat yang sudah ada atau tampilkan welcome message
  Future<void> _initializeChat() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Load chat yang sudah ada dari database
      await _loadExistingChats();

      // Jika tidak ada chat, tampilkan welcome message
      if (_messages.isEmpty) {
        await _sendWelcomeMessage();
      }

      // Pastikan scroll ke bawah setelah semua data loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error initializing chat: $e');
      _showErrorSnackbar('Failed to initialize chat: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Load chat yang sudah ada dari database - DIPERBAIKI
  Future<void> _loadExistingChats() async {
    try {
      // Ambil semua chat dari user ini
      final chatMaps = await DatabaseHelper.instance.getChatsByUserWithUsername(widget.userId);
      
      if (chatMaps.isEmpty) {
        print('No existing chats found for user ${widget.userId}');
        return;
      }

      print('Loading ${chatMaps.length} chat records');

      // List untuk menyimpan semua pesan dengan timestamp untuk sorting
      List<ChatMessage> tempMessages = [];

      for (var map in chatMaps) {
        final timestamp = DateTime.parse(map['timestamp'] as String);
        final chatId = map['id'] as int;

        // Tambahkan pesan user jika ada dan tidak kosong
        if (map['message_user'] != null && (map['message_user'] as String).trim().isNotEmpty) {
          tempMessages.add(
            ChatMessage(
              id: chatId,
              message: map['message_user'] as String,
              isFromUser: true,
              timestamp: timestamp,
            ),
          );
        }

        // Tambahkan pesan AI jika ada dan tidak kosong
        if (map['message_ai'] != null && (map['message_ai'] as String).trim().isNotEmpty) {
          // Untuk AI message, kita buat timestamp sedikit lebih lambat agar urutan benar
          final aiTimestamp = timestamp.add(const Duration(seconds: 1));
          tempMessages.add(
            ChatMessage(
              id: chatId,
              message: map['message_ai'] as String,
              isFromUser: false,
              timestamp: aiTimestamp,
            ),
          );
        }
      }

      // Sort messages berdasarkan timestamp
      tempMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _messages.clear();
        _messages.addAll(tempMessages);
      });

      print('Loaded ${_messages.length} messages successfully');

    } catch (e) {
      print('Error loading existing chats: $e');
      // Jangan throw error, biarkan aplikasi tetap jalan dengan chat kosong
    }
  }

  // Kirim welcome message - DIPERBAIKI
  Future<void> _sendWelcomeMessage() async {
    const welcomeText =
        'Hi! Selamat datang di Mentaly👋\n'
        'Aku di sini untuk membantu kamu menjaga kesehatan mental, '
        'menemukan ketenangan, atau sekadar menjadi teman bicara '
        'kapan pun kamu butuhkan😊';

    try {
      // Cek apakah sudah ada welcome message sebelumnya
      final existingChats = await DatabaseHelper.instance.getChatsByUser(widget.userId);
      bool hasWelcomeMessage = existingChats.any((chat) => 
          chat['message_ai'] != null && 
          (chat['message_ai'] as String).contains('Selamat datang di Mentaly'));

      if (!hasWelcomeMessage) {
        // Simpan welcome message ke database
        await DatabaseHelper.instance.insertCompleteChat(
          widget.userId,
          '', // User message kosong untuk welcome message
          welcomeText,
        );

        // Tambahkan ke UI
        setState(() {
          _messages.add(
            ChatMessage(
              message: welcomeText,
              isFromUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });

        print('Welcome message sent and saved');
      }
    } catch (e) {
      print('Error sending welcome message: $e');
      // Jika gagal simpan ke database, tetap tampilkan di UI
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(
            ChatMessage(
              message: welcomeText,
              isFromUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    setState(() {
      _isTyping = true;
      _messageController.clear();
    });

    try {
      // Tambah pesan user ke UI terlebih dahulu
      final userMessage = ChatMessage(
        message: message,
        isFromUser: true,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(userMessage);
      });
      _scrollToBottom();

      // Simpan pesan user ke database dan dapatkan chat ID
      final chatId = await DatabaseHelper.instance.insertUserMessage(
        widget.userId,
        message,
      );

      // Dapatkan response dari AI
      final aiResponse = await AIService.getAIResponse(message, widget.userId);

      // Update chat dengan response AI
      await DatabaseHelper.instance.updateWithAIResponse(chatId, aiResponse);

      // Tambah response AI ke UI
      if (mounted) {
        final aiMessage = ChatMessage(
          id: chatId,
          message: aiResponse,
          isFromUser: false,
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(aiMessage);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      
      final errorMessage = e.toString().contains('402')
          ? 'API service requires payment. Please upgrade to premium.'
          : 'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}';
      
      _showErrorSnackbar(errorMessage);

      if (e.toString().contains('402')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PremiumScreen(username: widget.username),
          ),
        );
      }
      
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }

  // Fungsi untuk memulai chat baru (clear chat history)
  Future<void> _startNewChat() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mulai Chat Baru'),
          content: const Text('Apakah Anda yakin ingin memulai chat baru? Chat sebelumnya akan dihapus.'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Ya'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAndStartNewChat();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAndStartNewChat() async {
    setState(() => _isLoading = true);
    
    try {
      // Hapus semua chat user dari database
      await DatabaseHelper.instance.deleteAllChatsByUser(widget.userId);

      // Clear UI
      setState(() {
        _messages.clear();
      });

      // Kirim welcome message baru
      await _sendWelcomeMessage();
      _scrollToBottom();

      _showErrorSnackbar('Chat baru dimulai!');
    } catch (e) {
      print('Error starting new chat: $e');
      _showErrorSnackbar('Failed to start new chat: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method untuk refresh chat history - TAMBAHAN BARU
  Future<void> _refreshChatHistory() async {
    setState(() => _isLoading = true);
    
    try {
      await _loadExistingChats();
      
      if (_messages.isEmpty) {
        await _sendWelcomeMessage();
      }
      
      _scrollToBottom();
      _showErrorSnackbar('Chat history refreshed');
    } catch (e) {
      print('Error refreshing chat: $e');
      _showErrorSnackbar('Failed to refresh chat: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3978B8),
                      ),
                    ),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada chat. Mulai percakapan!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshChatHistory,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isTyping && index == _messages.length) {
                              return _buildTypingIndicator();
                            }
                            return _buildChatBubble(_messages[index]);
                          },
                        ),
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3978B8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LilyBot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Sampaikan seluruh keluh kesahmu',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        // Tombol untuk refresh chat history - TAMBAHAN BARU
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: Colors.white),
          onPressed: _refreshChatHistory,
          tooltip: 'Refresh Chat',
        ),
        // Tombol untuk chat baru
        IconButton(
          icon: const Icon(Icons.cleaning_services_outlined, color: Colors.white),
          onPressed: _startNewChat,
          tooltip: 'Chat Baru',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PremiumScreen(username: widget.username),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Go Premium',
              style: TextStyle(
                color: Color(0xFF3978B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3978B8)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Mengetik...', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final String formattedTime = DateFormat('H:mm').format(message.timestamp);

    return Align(
      alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildBubbleContainer(
        message.message,
        message.isFromUser,
        formattedTime,
      ),
    );
  }

  Widget _buildBubbleContainer(String message, bool isFromUser, String time) {
    return Container(
      margin: EdgeInsets.only(
        left: isFromUser ? 80 : 16,
        right: isFromUser ? 16 : 80,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isFromUser ? const Color(0xFFD6E9F8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isFromUser ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 14)),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFD6E9F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                      enabled: !_isTyping,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {}, // Placeholder emoji
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3978B8),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isTyping ? null : _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}