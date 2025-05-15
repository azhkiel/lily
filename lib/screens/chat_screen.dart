import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/widget/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'message': 'Hi there! How can I help you today?',
      'isUser': false,
      'timestamp': '10:30 AM',
    },
    {
      'message': 'I\'m feeling a bit anxious today',
      'isUser': true,
      'timestamp': '10:31 AM',
    },
    {
      'message':
          'I\'m sorry to hear that. Can you tell me more about what\'s making you feel anxious?',
      'isUser': false,
      'timestamp': '10:31 AM',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = {
      'message': _messageController.text,
      'isUser': true,
      'timestamp': _getCurrentTime(),
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Simulate bot response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final botResponse = {
        'message':
            'Thank you for sharing. Let\'s explore some techniques that might help with your anxiety.',
        'isUser': false,
        'timestamp': _getCurrentTime(),
      };

      setState(() {
        _messages.add(botResponse);
      });
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentaly Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(
                  message: message['message'],
                  isUser: message['isUser'],
                  timestamp: message['timestamp'],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.gray)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
