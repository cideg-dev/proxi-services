import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/conversation_model.dart';

class ChatService {
  SocketService? _socketService;
  final TokenManager _tokenManager = TokenManager();
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();

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

    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (beforeId != null) {
      queryParams['beforeId'] = beforeId.toString();
    }
    
    final uri = Uri.parse('/messages/$userId/$receiverId').replace(queryParameters: queryParams);
    final response = await _functionsService.proxyToFunction('messages', uri.toString(), 'GET');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Message>((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // NEW: Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    final response = await _functionsService.proxyToFunction('messages', '/$messageId/read', 'PUT');

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to mark message as read';
      throw Exception(errorMessage);
    }
  }

  // NEW: Fetch all conversations for the logged-in user
  Future<List<Conversation>> getConversations() async {
    try {
      // Use proxy to 'conversations' function, root path
      final response = await _functionsService.proxyToFunction('conversations', '', 'GET');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded.map<Conversation>((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
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
  Future<Conversation> startConversation(int receiverId) async {
    try {
      final response = await _functionsService.proxyToFunction(
        'conversations', 
        '', 
        'POST',
        body: {'receiverId': receiverId}
      );

      if (response.statusCode == 201) {
        return Conversation.fromJson(jsonDecode(response.body));
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
  Future<Message> sendMessageToConversation(int conversationId, String message) async {
    try {
      final response = await _functionsService.proxyToFunction(
        'conversations', 
        '/$conversationId/messages', 
        'POST',
        body: {'content': message}
      );

      if (response.statusCode == 201) {
        return Message.fromJson(jsonDecode(response.body));
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
  Future<List<Message>> getMessagesFromConversation(int conversationId, {int? beforeId, int limit = 20}) async {
    final Map<String, String> queryParams = {
      'limit': limit.toString(),
    };
    if (beforeId != null) {
      queryParams['beforeId'] = beforeId.toString();
    }

    // Construct URI with query params
    String path = '/$conversationId/messages';
    String queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    if (queryString.isNotEmpty) {
      path += '?$queryString';
    }

    final response = await _functionsService.proxyToFunction('conversations', path, 'GET');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.map<Message>((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  // NEW: Mark all messages in a conversation as read
  Future<void> markConversationAsRead(int conversationId) async {
    final response = await _functionsService.proxyToFunction(
      'conversations', 
      '/$conversationId/mark-as-read', 
      'PUT'
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to mark conversation as read';
      throw Exception(errorMessage);
    }
  }

  // NEW: Block a user
  Future<void> blockUser(int userId) async {
    final response = await _functionsService.proxyToFunction(
      'users', 
      '/$userId/block', 
      'POST'
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to block user';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get user status (online/offline)
  Future<Map<String, dynamic>> getUserStatus(int userId) async {
    final response = await _functionsService.proxyToFunction(
      'users', 
      '/$userId/status', 
      'GET'
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user status: ${response.body}');
    }
  }
}
