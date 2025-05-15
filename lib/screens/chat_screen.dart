import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/widget/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String username;

  const ChatScreen({
    Key? key,
    this.username = 'User', // Default username if none provided
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add initial AI message
    _addMessage("Hello there! How can I help you today?", false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: isUser, username: widget.username),
      );
    });

    // Scroll to bottom after adding message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final messageText = _messageController.text;
      _messageController.clear();

      // Add user message
      _addMessage(messageText, true);

      // Simulate AI response
      Future.delayed(const Duration(seconds: 1), () {
        _addMessage(
          "Thanks for your message! I'm processing your request.",
          false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat with AI - ${widget.username}',
          style: TextStyle(
            color: Color(0xFF2C5D7C),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF2C5D7C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear chat history except the first welcome message
              setState(() {
                _messages.clear();
                _addMessage("Hello there! How can I help you today?", false);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              color: const Color(0xFFE6F4FB), // Light blue background
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
          ),

          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: Colors.white,
            child: Row(
              children: [
                // Add attachment button
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  color: Colors.grey,
                  onPressed: () {
                    // Handle attachment
                  },
                ),

                // Text input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  color: const Color(0xFF2C5D7C),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String username;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    this.username = 'User',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar for non-user messages
            CircleAvatar(
              backgroundColor: const Color(0xFF2C5D7C),
              child: Image.asset(
                'assets/logo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.smart_toy, color: Colors.white);
                },
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? const Color(0xFF3498DB) // Blue for user messages
                        : Colors.white, // White for AI messages
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
