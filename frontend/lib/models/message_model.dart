class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      conversationId: json['conversation_id'] is int ? json['conversation_id'] : int.tryParse(json['conversation_id'].toString()) ?? 0,
      senderId: json['sender_id'] is int ? json['sender_id'] : int.tryParse(json['sender_id'].toString()) ?? 0,
      content: json['content'] ?? '',
      sentAt: DateTime.parse(json['sent_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }
}
