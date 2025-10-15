import 'dart:convert'; // Add import
import 'package:frontend/services/api_constants.dart'; // Add import
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add import
import 'package:frontend/services/token_manager.dart'; // Add TokenManager

class ChatService {
  SocketService? _socketService;
  final TokenManager _tokenManager = TokenManager(); // Add TokenManager

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
    final token = await _tokenManager.getToken();
    final userId = await _tokenManager.getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication token or user ID not found.');
    }

    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (beforeId != null) {
      queryParams['beforeId'] = beforeId.toString();
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/messages/$userId/$receiverId')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // NEW: Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    final token = await _tokenManager.getToken();

    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/messages/$messageId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to mark message as read';
      throw Exception(errorMessage);
    }
  }

  // NEW: Fetch all conversations for the logged-in user
  Future<List<dynamic>> getConversations() async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/conversations');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load conversations';
      throw Exception(errorMessage);
    }
  }
}
