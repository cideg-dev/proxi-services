import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/user_model.dart';

class Conversation {
  final int id;
  final DateTime updatedAt;
  final User? otherParticipant;
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.updatedAt,
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] ?? json['last_message_time'] ?? DateTime.now().toIso8601String()),
      otherParticipant: json['other_participant'] != null 
          ? User.fromJson(json['other_participant']) 
          : (json['name'] != null ? User(id: 0, email: '', name: json['name'], avatarUrl: json['avatar_url']) : null),
      lastMessage: json['last_message'] != null 
          ? (json['last_message'] is Map ? Message.fromJson(json['last_message']) : null) // Handle simple string last_message if needed
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
