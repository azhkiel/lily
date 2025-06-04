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
    final map = <String, dynamic>{
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_ai': isAI ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      senderId: map['sender_id'] is int ? map['sender_id'] as int : int.parse('${map['sender_id']}'),
      receiverId: map['receiver_id'] is int ? map['receiver_id'] as int : int.parse('${map['receiver_id']}'),
      message: map['message'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isAI: (map['is_ai'] == 1 || map['is_ai'] == true),
    );
  }
}
