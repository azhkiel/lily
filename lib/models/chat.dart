class ChatMessage {
  final int? id;
  final String message;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isFromUser': isFromUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toInt(),
      message: map['message'] ?? '',
      isFromUser: (map['isFromUser'] ?? 0) == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}