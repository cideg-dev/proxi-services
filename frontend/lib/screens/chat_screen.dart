import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/socket_service.dart'; // New import
import 'package:frontend/services/token_manager.dart';
import 'package:provider/provider.dart'; // New import

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final TokenManager _tokenManager = TokenManager();
  final ScrollController _scrollController = ScrollController(); // For pagination
  List<Map<String, dynamic>> _messages = [];
  int? _senderId;
  bool _isLoadingMessages = false;
  bool _hasMoreMessages = true;
  StreamSubscription? _messageStatusUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadSenderId();
    _chatService.init(context); // Initialize ChatService with context
    _chatService.onMessageReceived(_handleMessage);
    _loadMessages(isInitialLoad: true); // Load initial messages

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMoreMessages && !_isLoadingMessages) {
        _loadMessages(isInitialLoad: false); // Load more messages
      }
    });

    // Set up listener for message status updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = context.read<SocketService>();
      _messageStatusUpdateSubscription = socketService.messageStatusUpdates.listen((updatedMessage) {
        if (!mounted) return;
        _handleMessageStatusUpdate(updatedMessage);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageStatusUpdateSubscription?.cancel();
    super.dispose();
  }

  void _loadSenderId() async {
    _senderId = await _tokenManager.getUserId();
    // After senderId is loaded, mark messages as read
    if (_senderId != null) {
      _markAllMessagesAsRead();
    }
  }

  Future<void> _loadMessages({bool isInitialLoad = true}) async {
    if (_isLoadingMessages || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final int? beforeId = _messages.isNotEmpty && !isInitialLoad ? _messages.first['id'] : null;
      final rawMessages = await _chatService.getMessages(widget.receiverId, beforeId: beforeId);

      if (!mounted) return;

      // Ensure we have a strongly typed list of Map<String, dynamic>
      final List<Map<String, dynamic>> newMessages = rawMessages
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _messages.insertAll(0, newMessages.reversed.toList()); // Prepend new messages
        _hasMoreMessages = newMessages.length == 20; // Assuming limit is 20
        _isLoadingMessages = false;
      });

      if (isInitialLoad) {
        // Scroll to bottom for initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des messages: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
    // Scroll to bottom when a new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    // If the message is from the other user, mark it as read
    if (message['sender_id'] == widget.receiverId) {
      _chatService.markMessageAsRead(message['id']);
    }
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> updatedMessage) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((msg) => msg['id'] == updatedMessage['id']);
      if (index != -1) {
        _messages[index]['status'] = updatedMessage['status'];
      }
    });
  }

  void _markAllMessagesAsRead() async {
    if (_senderId == null) return;
    for (var message in _messages) {
      if (message['sender_id'] == widget.receiverId && message['status'] != 'read') {
        await _chatService.markMessageAsRead(message['id']);
      }
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _senderId != null) {
      _chatService.sendMessage(
        _controller.text,
        widget.receiverId,
        _senderId!,
      );
      _controller.clear();
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      print('Error parsing timestamp: $e');
      return '';
    }
  }

  Icon _getMessageStatusIcon(String status, bool isMe) {
    switch (status) {
      case 'sent':
        return Icon(Icons.done, size: 16, color: isMe ? Colors.white70 : Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: isMe ? Colors.white70 : Colors.grey);
      case 'read':
        return Icon(Icons.done_all, size: 16, color: isMe ? Colors.blueAccent : Colors.blue);
      default:
        return const Icon(Icons.hourglass_empty, size: 16, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Show latest messages at bottom
              itemCount: _messages.length + (_hasMoreMessages ? 1 : 0), // Add 1 for loading indicator
              itemBuilder: (context, index) {
                if (index == _messages.length && _hasMoreMessages) {
                  return const Center(child: CircularProgressIndicator()); // Loading indicator
                }
                final message = _messages[index];
                final bool isMe = message['sender_id'] == _senderId;
                final String status = message['status'] ?? 'sent'; // Default status

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).primaryColor : Colors.grey[700],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['content'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message['timestamp'] as String?),
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _getMessageStatusIcon(status, isMe),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}