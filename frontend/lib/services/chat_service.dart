import 'dart:convert';
import 'package:frontend/services/enhanced_auth_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/token_manager.dart';

class ChatService {
  SocketService? _socketService;
  final TokenManager _tokenManager = TokenManager();
  final EnhancedApiService _apiService = EnhancedApiService();

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
    try {
      final response = await _apiService.get('/api/conversations');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load conversations';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error getting conversations: $e');
      rethrow;
    }
  }

  // NEW: Start a new conversation
  Future<Map<String, dynamic>> startConversation(int receiverId) async {
    try {
      final response = await _apiService.post('/api/conversations',
        body: {'receiverId': receiverId}
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to start conversation';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error starting conversation: $e');
      rethrow;
    }
  }

  // NEW: Send a message to a specific conversation
  Future<Map<String, dynamic>> sendMessageToConversation(int conversationId, String message) async {
    try {
      final response = await _apiService.post('/api/conversations/$conversationId/messages',
        body: {'content': message}
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to send message';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error sending message to conversation: $e');
      rethrow;
    }
  }

  // NEW: Get messages from a specific conversation
  Future<List<dynamic>> getMessagesFromConversation(int conversationId, {int? beforeId, int limit = 20}) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (beforeId != null) {
      queryParams['beforeId'] = beforeId.toString();
    }

    final uri = Uri.parse('/api/conversations/$conversationId/messages').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  // NEW: Mark all messages in a conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    final response = await _apiService.put('/api/conversations/$conversationId/mark-as-read');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to mark conversation as read';
      throw Exception(errorMessage);
    }
  }

  // NEW: Block a user
  Future<void> blockUser(int userId) async {
    final response = await _apiService.post('/api/users/$userId/block');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to block user';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get user status (online/offline)
  Future<Map<String, dynamic>> getUserStatus(int userId) async {
    final response = await _apiService.getPublic('/api/users/$userId/status');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user status: ${response.body}');
    }
  }
}
