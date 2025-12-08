import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/conversation_model.dart';

class ChatService {
  SocketService? _socketService;
  final TokenManager _tokenManager = TokenManager();

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() {
    return _instance;
  }
  ChatService._internal();

  void init(BuildContext context) {
    _socketService = Provider.of<SocketService>(context, listen: false);
  }

  void connect() {
    _socketService?.connect();
  }

  void disconnect() {
    _socketService?.disconnect();
  }

  void sendMessage(String message, int receiverId, int senderId) {
    _socketService?.socket?.emit('chat message', {
      'content': message,
      'receiverId': receiverId,
      'senderId': senderId,
    });
  }

  void onMessageReceived(Function(Map<String, dynamic>) handler) {
    _socketService?.socket?.on('chat message', (data) {
      handler(data);
    });
  }

  void onNotification(Function(Map<String, dynamic>) handler) {
    _socketService?.socket?.on('new-message-notification', (data) {
      handler(data);
    });
  }

  // NEW: Fetch historical messages with pagination
  Future<List<Message>> getMessages(int receiverId, {int? beforeId, int limit = 20}) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) throw Exception('User ID not found.');

    String endpoint = '/messages/$userId/$receiverId';
    if (beforeId != null || limit != 20) {
      final queryParams = <String, String>{};
      if (beforeId != null) queryParams['beforeId'] = beforeId.toString();
      if (limit != 20) queryParams['limit'] = limit.toString();

      endpoint += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Message>((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    final response = await ApiService.put('/messages/$messageId/read', {});

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Fetch all conversations for the logged-in user
  Future<List<Conversation>> getConversations() async {
    final response = await ApiService.get('/conversations');

    if (ApiService.isSuccessful(response.statusCode)) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Conversation>((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid token');
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Start a new conversation
  Future<Conversation> startConversation(int receiverId) async {
    final response = await ApiService.post('/conversations', {
      'receiverId': receiverId
    });

    if (ApiService.isSuccessful(response.statusCode)) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Send a message to a specific conversation
  Future<Message> sendMessageToConversation(int conversationId, String message) async {
    final response = await ApiService.post('/conversations/$conversationId/messages', {
      'content': message
    });

    if (ApiService.isSuccessful(response.statusCode)) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Get messages from a specific conversation
  Future<List<Message>> getMessagesFromConversation(int conversationId, {int? beforeId, int limit = 20}) async {
    String endpoint = '/conversations/$conversationId/messages';
    if (beforeId != null || limit != 20) {
      final queryParams = <String, String>{};
      if (beforeId != null) queryParams['beforeId'] = beforeId.toString();
      if (limit != 20) queryParams['limit'] = limit.toString();

      endpoint += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await ApiService.get(endpoint);

    if (ApiService.isSuccessful(response.statusCode)) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Message>((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Mark all messages in a conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    final response = await ApiService.put('/conversations/$conversationId/mark-as-read', {});

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Block a user
  Future<void> blockUser(int userId) async {
    final response = await ApiService.post('/users/$userId/block', {});

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // NEW: Get user status (online/offline)
  Future<Map<String, dynamic>> getUserStatus(int userId) async {
    final response = await ApiService.get('/users/$userId/status');

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }
}
