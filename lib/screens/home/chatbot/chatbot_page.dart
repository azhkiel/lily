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

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _loadExistingChats();

      if (_messages.isEmpty) {
        await _sendWelcomeMessage();
      }

      _fadeController.forward();
      _slideController.forward();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      _showErrorSnackbar('Failed to initialize chat');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExistingChats() async {
    try {
      final chatMaps = await DatabaseHelper.instance.getChatsByUserWithUsername(widget.userId);
      
      if (chatMaps.isEmpty) {
        debugPrint('No existing chats found for user ${widget.userId}');
        return;
      }

      debugPrint('Loading ${chatMaps.length} chat records');

      List<ChatMessage> tempMessages = [];

      for (var map in chatMaps) {
        final timestamp = DateTime.parse(map['timestamp'] as String);
        final chatId = map['id'] as int;

        // Add user message if exists and not empty
        final userMessage = map['message_user'] as String?;
        if (userMessage != null && userMessage.trim().isNotEmpty) {
          tempMessages.add(
            ChatMessage(
              id: chatId,
              message: userMessage,
              isFromUser: true,
              timestamp: timestamp,
            ),
          );
        }

        // Add AI message if exists and not empty
        final aiMessage = map['message_ai'] as String?;
        if (aiMessage != null && aiMessage.trim().isNotEmpty) {
          final aiTimestamp = timestamp.add(const Duration(seconds: 1));
          tempMessages.add(
            ChatMessage(
              id: chatId,
              message: aiMessage,
              isFromUser: false,
              timestamp: aiTimestamp,
            ),
          );
        }
      }

      // Sort messages by timestamp
      tempMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(tempMessages);
        });
      }

      debugPrint('Loaded ${_messages.length} messages successfully');

    } catch (e) {
      debugPrint('Error loading existing chats: $e');
      // Don't throw error, let app continue with empty chat
    }
  }

  Future<void> _sendWelcomeMessage() async {
    const welcomeText =
        'Hi! Selamat datang di Mentaly👋\n'
        'Aku di sini untuk membantu kamu menjaga kesehatan mental, '
        'menemukan ketenangan, atau sekadar menjadi teman bicara '
        'kapan pun kamu butuhkan😊';

    try {
      final existingChats = await DatabaseHelper.instance.getChatsByUser(widget.userId);
      bool hasWelcomeMessage = existingChats.any((chat) => 
          chat['message_ai'] != null && 
          (chat['message_ai'] as String).contains('Selamat datang di Mentaly'));

      if (!hasWelcomeMessage) {
        await DatabaseHelper.instance.insertCompleteChat(
          widget.userId,
          '',
          welcomeText,
        );

        if (mounted) {
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

        debugPrint('Welcome message sent and saved');
      }
    } catch (e) {
      debugPrint('Error sending welcome message: $e');
      // If failed to save to database, still show in UI
      if (_messages.isEmpty && mounted) {
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF3978B8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
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
      // Add user message to UI first
      final userMessage = ChatMessage(
        message: message,
        isFromUser: true,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(userMessage);
      });
      _scrollToBottom();

      // Save user message to database and get chat ID
      final chatId = await DatabaseHelper.instance.insertUserMessage(
        widget.userId,
        message,
      );

      // Get AI response
      final aiResponse = await AIService.getAIResponse(message, widget.userId);

      // Update chat with AI response
      await DatabaseHelper.instance.updateWithAIResponse(chatId, aiResponse);

      // Add AI response to UI
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
      debugPrint('Error sending message: $e');
      
      final errorMessage = e.toString().contains('402')
          ? 'API service requires payment. Please upgrade to premium.'
          : 'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}';
      
      _showErrorSnackbar(errorMessage);

      if (e.toString().contains('402') && mounted) {
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

  Future<void> _startNewChat() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3978B8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF3978B8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mulai Chat Baru',
                style: TextStyle(
                  color: Color(0xFF3978B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin memulai chat baru? Chat sebelumnya akan dihapus.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3978B8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ya',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
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
      await DatabaseHelper.instance.deleteAllChatsByUser(widget.userId);

      setState(() {
        _messages.clear();
      });

      _fadeController.reset();
      _slideController.reset();

      await _sendWelcomeMessage();
      
      _fadeController.forward();
      _slideController.forward();
      
      _scrollToBottom();

      _showErrorSnackbar('Chat baru dimulai!');
    } catch (e) {
      debugPrint('Error starting new chat: $e');
      _showErrorSnackbar('Failed to start new chat');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
      debugPrint('Error refreshing chat: $e');
      _showErrorSnackbar('Failed to refresh chat');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildChatArea(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_isLoading && _messages.isEmpty) {
      return _buildLoadingState();
    }
    
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshChatHistory,
          color: const Color(0xFF3978B8),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == _messages.length) {
                return _buildTypingIndicator();
              }
              return _buildChatBubble(_messages[index], index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3978B8).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3978B8)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Memuat percakapan...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Color(0xFF3978B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tidak ada chat. Mulai percakapan!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3978B8),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3978B8), Color(0xFF2E5C8A)],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: Colors.white, size: 22),
          onPressed: _refreshChatHistory,
          tooltip: 'Refresh Chat',
        ),
        IconButton(
          icon: const Icon(Icons.cleaning_services_outlined, color: Colors.white, size: 22),
          onPressed: _startNewChat,
          tooltip: 'Chat Baru',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F8FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PremiumScreen(username: widget.username),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.diamond,
                    color: Color(0xFF3978B8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Go Premium',
                    style: TextStyle(
                      color: Color(0xFF3978B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDotAnimation(0),
                    const SizedBox(width: 4),
                    _buildDotAnimation(1),
                    const SizedBox(width: 4),
                    _buildDotAnimation(2),
                    const SizedBox(width: 16),
                    Text(
                      'Mengetik...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDotAnimation(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF3978B8).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message, int index) {
    final String formattedTime = DateFormat('HH:mm').format(message.timestamp);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
              child: _buildBubbleContainer(
                message.message,
                message.isFromUser,
                formattedTime,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubbleContainer(String message, bool isFromUser, String time) {
    return Container(
      margin: EdgeInsets.only(
        left: isFromUser ? 64 : 16,
        right: isFromUser ? 16 : 64,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isFromUser
            ? const LinearGradient(
                colors: [Color(0xFFD6E9F8), Color(0xFFE8F4FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFromUser ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isFromUser ? 20 : 6),
          bottomRight: Radius.circular(isFromUser ? 6 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isFromUser ? const Color(0xFF2E5C8A) : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMessageInput() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      child: Row(
        children: [
          // Emoji button
          IconButton(
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.grey.shade600,
              size: 24,
            ),
            onPressed: () {}, // Placeholder for emoji functionality
          ),
          // Text input container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255), // Warna biru muda
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '  Ketik pesan...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(fontSize: 15),
                onSubmitted: (_) => _handleSendMessage(),
                enabled: !_isTyping,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          // Send button
          IconButton(
            icon: Icon(
              _isTyping ? Icons.hourglass_empty : Icons.send,
              color: _isTyping ? Colors.grey.shade600 : const Color(0xFF3978B8),
              size: 24,
            ),
            onPressed: _isTyping ? null : _handleSendMessage,
          ),
        ],
      ),
    ),
  );
}

}