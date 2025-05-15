import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../db/database.dart';
import '../services/ai_service.dart';
import 'home_page.dart';

class ChatPage extends StatefulWidget {
  final String username;
  final int userId;

  // Ubah konstruktor untuk membuat parameter opsional dengan nilai default
  const ChatPage({Key? key, this.username = 'username', this.userId = 0})
    : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Controller untuk mengelola input text
  final _messageController = TextEditingController();

  // Controller untuk mengelola scroll behavior
  final _scrollController = ScrollController();

  // Focus node untuk mengelola keyboard focus
  final _focusNode = FocusNode();

  // Daftar pesan dalam chat
  final List<Chat> _messages = [];

  // ID khusus untuk AI
  final int _aiUserId = 0;

  // State untuk loading indicator
  bool _isLoading = false;

  // State untuk indikator AI sedang memproses
  bool _isAiThinking = false;

  @override
  void initState() {
    super.initState();
    _loadChats(); // Memuat pesan saat inisialisasi
  }

  @override
  void dispose() {
    // Membersihkan controller dan focus node saat widget dihapus
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Memuat pesan dari database
  Future<void> _loadChats() async {
    if (_isLoading) return; // Hindari multiple calls

    setState(() => _isLoading = true);
    try {
      final chats = await DatabaseHelper.instance.getChats(
        widget.userId,
        _aiUserId,
      );
      setState(
        () =>
            _messages
              ..clear()
              ..addAll(chats),
      );
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Failed to load messages: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mengirim pesan baru
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isAiThinking) return;

    setState(() {
      _isAiThinking = true;
      _messageController.clear();
    });

    try {
      // 1. Simpan pesan pengguna ke database
      final userChat = Chat(
        senderId: widget.userId,
        receiverId: _aiUserId,
        message: message,
        timestamp: DateTime.now(),
        isAI: false,
      );
      await DatabaseHelper.instance.insertChat(userChat);
      _addMessageToUI(userChat);

      // 2. Dapatkan respons dari AI
      final aiResponse = await AIService.getAIResponse(message, widget.userId);

      // 3. Simpan respons AI ke database
      final aiChat = Chat(
        senderId: _aiUserId,
        receiverId: widget.userId,
        message: aiResponse,
        timestamp: DateTime.now(),
        isAI: true,
      );
      await DatabaseHelper.instance.insertChat(aiChat);
      _addMessageToUI(aiChat);
    } on Exception catch (e) {
      // Handle error khusus untuk status 402 (Payment Required)
      final errorMessage =
          e.toString().contains('402')
              ? 'API service requires payment. Please check your subscription.'
              : 'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}';

      _showErrorSnackbar(errorMessage);
      _messageController.text = message; // Kembalikan pesan jika gagal
    } finally {
      setState(() => _isAiThinking = false);
    }
  }

  // Menambahkan pesan ke UI dan auto-scroll
  void _addMessageToUI(Chat chat) {
    setState(() {
      _messages.add(chat);
      _scrollToBottom();
    });
  }

  // Auto-scroll ke bagian bawah chat
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

  // Menampilkan error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // Logout dan kembali ke halaman login
  void _logoutAndGoToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage(username: '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with AI - ${widget.username}',
        ), // Tampilkan username di appbar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _logoutAndGoToLogin,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChats),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length + (_isAiThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isAiThinking && index == _messages.length) {
                          return _buildAIThinkingIndicator();
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

  // Widget untuk indikator AI sedang berpikir
  Widget _buildAIThinkingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('AI is thinking...'),
          ],
        ),
      ),
    );
  }

  // Widget untuk bubble chat
  Widget _buildChatBubble(Chat message) {
    final isMe = message.senderId == widget.userId;
    final time = message.timestamp;
    final senderName =
        isMe ? widget.username : 'AI Assistant'; // Tentukan nama pengirim

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMe
                  ? Theme.of(context).primaryColor
                  : (message.isAI ? Colors.green[100] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tampilkan nama pengirim
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isMe
                          ? Colors.white70
                          : (message.isAI ? Colors.green[800] : Colors.black87),
                ),
              ),
            ),
            // Konten pesan dan waktu dalam satu baris
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    message.message,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk input pesan
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: const OutlineInputBorder(),
                suffixIcon:
                    _isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : null,
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading && !_isAiThinking,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: (_isLoading || _isAiThinking) ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
