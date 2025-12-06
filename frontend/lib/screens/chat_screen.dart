import 'package:flutter/material.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int partnerId;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TokenManager _tokenManager = TokenManager();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadMessages();
    _setupMessageListener();
    
    // Marquer la conversation comme lue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markConversationAsRead(widget.conversationId);
    });
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await _tokenManager.getUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'ID utilisateur: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupMessageListener() {
    _chatService.onMessageReceived((messageData) {
      if (mounted) {
        setState(() {
          // Assuming messageData is a Map, convert to Message
          _messages.insert(0, Message.fromJson(messageData));
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessagesFromConversation(widget.conversationId);
      
      setState(() {
        _messages = messages;
        _isLoading = false;
        _hasMoreMessages = messages.length >= 20; // Supposition que 20 = page complète
      });
      
      // Défilement vers le bas après le chargement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Calculer l'ID du message le plus ancien pour la pagination
      int? beforeId;
      if (_messages.isNotEmpty) {
        beforeId = _messages.last.id;
      }
      
      final moreMessages = await _chatService.getMessagesFromConversation(
        widget.conversationId,
        beforeId: beforeId,
      );
      
      setState(() {
        _messages.addAll(moreMessages);
        _isLoadingMore = false;
        _hasMoreMessages = moreMessages.length >= 20;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des anciens messages: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    _messageController.clear();

    try {
      // Envoyer le message via le service
      final newMessage = await _chatService.sendMessageToConversation(widget.conversationId, messageContent);
      setState(() {
        _messages.insert(0, newMessage);
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Zone de messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.message_outlined, size: 60, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  'Commencez la conversation avec ${widget.partnerName}',
                                  style: theme.textTheme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Scrollbar(
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true, // Nouveaux messages en haut
                              itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length) {
                                  // Indicateur de chargement pour les anciens messages
                                  return _isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      : Container();
                                }

                                final message = _messages[index];
                                final isMe = message.senderId == _currentUserId;
                                
                                return MessageBubble(
                                  message: message.content,
                                  isMe: isMe,
                                  timestamp: message.sentAt,
                                  isRead: message.readAt != null,
                                );
                              },
                            ),
                          ),
          ),
          
          // Zone d'entrée du message
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}