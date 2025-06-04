import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'premium_screen.dart';
import '../../../models/chat.dart';
import '../../../db/database.dart';
import '../../../services/ai_service.dart';

class ChatbotPage extends StatefulWidget {
  final String username;
  final int userId;

  const ChatbotPage({
    Key? key,
    this.username = 'User',
    this.userId = 0,
  }) : super(key: key);

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Chat> _messages = [];
  final int _aiUserId = 0; // ID khusus untuk AI
  bool _isTyping = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Memuat pesan dari database menggunakan join untuk dapatkan username pengirim dan penerima
  Future<void> _loadChats() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Gunakan method getChatsWithUsernames yang baru
      final chatMaps = await DatabaseHelper.instance.getChatsWithUsernames(widget.userId, _aiUserId);

      setState(() {
        _messages.clear();
        if (chatMaps.isEmpty) {
          final welcomeMessage = Chat(
            senderId: _aiUserId,
            receiverId: widget.userId,
            message:
                'Hi! Selamat datang di Mentaly👋\nAku di sini untuk membantu kamu menjaga kesehatan mental, menemukan ketenangan, atau sekadar menjadi teman bicara kapan pun kamu butuhkan😊',
            timestamp: DateTime.now(),
            isAI: true,
          );
          DatabaseHelper.instance.insertChat(welcomeMessage);
          _messages.add(welcomeMessage);
        } else {
          // Parsing Map ke Chat, field 'timestamp' berupa string dari DB harus di-parse ke DateTime
          for (var map in chatMaps) {
            _messages.add(Chat(
              id: map['id'] as int?,
              senderId: map['sender_id'] as int,
              receiverId: map['receiver_id'] as int,
              message: map['message'] as String,
              timestamp: DateTime.parse(map['timestamp'] as String),
              isAI: (map['is_ai'] as int) == 1,
            ));
          }
        }
      });
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Failed to load messages: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    setState(() {
      _isTyping = true;
      _messageController.clear();
    });

    try {
      final userChat = Chat(
        senderId: widget.userId,
        receiverId: _aiUserId,
        message: message,
        timestamp: DateTime.now(),
        isAI: false,
      );
      await DatabaseHelper.instance.insertChat(userChat);
      setState(() => _messages.add(userChat));
      _scrollToBottom();

      final aiResponse = await AIService.getAIResponse(message, widget.userId);

      final aiChat = Chat(
        senderId: _aiUserId,
        receiverId: widget.userId,
        message: aiResponse,
        timestamp: DateTime.now(),
        isAI: true,
      );
      await DatabaseHelper.instance.insertChat(aiChat);

      if (mounted) {
        setState(() {
          _messages.add(aiChat);
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMessage = e.toString().contains('402')
          ? 'API service requires payment. Please upgrade to premium.'
          : 'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}';
      _showErrorSnackbar(errorMessage);
      if (e.toString().contains('402')) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PremiumScreen(username: widget.username)),
        );
      }
      setState(() => _isTyping = false);
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3978B8)),
                    ),
                  )
                : ListView.builder(
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            'Sampaikan seluruh keluh kesahmu',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PremiumScreen(username: widget.username)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              'Go Premium',
              style: TextStyle(color: Color(0xFF3978B8), fontWeight: FontWeight.bold),
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

  Widget _buildChatBubble(Chat message) {
    final bool isUser = message.senderId == widget.userId && !message.isAI;
    final String formattedTime = DateFormat('H:mm').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildBubbleContainer(message.message, isUser, formattedTime),
    );
  }

  Widget _buildBubbleContainer(String message, bool isUser, String time) {
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 80 : 16,
        right: isUser ? 16 : 80,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFD6E9F8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isUser ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 14)),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
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
