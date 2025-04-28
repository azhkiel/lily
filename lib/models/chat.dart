class Chat {
  final int? id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime timestamp;
  final bool isAI;

  Chat({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isAI = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_ai': isAI ? 1 : 0,  // Konversi bool ke integer
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      isAI: map['is_ai'] == 1,  // Konversi integer ke bool
    );
  }
}