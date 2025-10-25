import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/token_manager.dart';

class ChatService {
  SocketService? _socketService;
  final TokenManager _tokenManager = TokenManager();
  final ApiService _apiService = ApiService();

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
  Future<List<Map<String, dynamic>>> getMessages(int receiverId, {int? beforeId, int limit = 20}) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (beforeId != null) {
      queryParams['beforeId'] = beforeId.toString();
    }

    final uri = Uri.parse('/api/messages/$userId/$receiverId').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // NEW: Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    final response = await _apiService.put('/api/messages/$messageId/read');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to mark message as read';
      throw Exception(errorMessage);
    }
  }

  // NEW: Fetch all conversations for the logged-in user
  Future<List<dynamic>> getConversations() async {
    final response = await _apiService.get('/api/conversations');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load conversations';
      throw Exception(errorMessage);
    }
  }
}
