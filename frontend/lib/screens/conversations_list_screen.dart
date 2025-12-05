import 'package:flutter/material.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/widgets/conversation_item.dart';
import 'package:frontend/screens/chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadConversations();
  }

  Future<void> _checkAuthAndLoadConversations() async {
    final tokenManager = TokenManager();
    final token = await tokenManager.getToken();
    
    if (token == null || token.isEmpty) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isAuthenticated = true;
    });
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _chatService.getConversations();
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Unauthorized')) {
           // Token invalide ou expiré, redirection vers la connexion
           Navigator.of(context).pushReplacementNamed('/login');
           return;
        }
        setState(() {
          _errorMessage = 'Erreur lors du chargement des conversations: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthenticated
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Vous devez être connecté pour voir vos conversations',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                )
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
                        onPressed: _loadConversations,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.message_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune conversation pour le moment',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Commencez une nouvelle conversation avec un artisan ou un commerçant',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return ConversationItem(
                            conversation: conversation,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    conversationId: conversation['id'],
                                    partnerId: conversation['partner']['id'],
                                    partnerName: conversation['partner']['name'] ?? conversation['partner']['email'],
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showConversationOptions(conversation);
                            },
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ouvrir l'écran de recherche pour démarrer une nouvelle conversation
          _showStartNewConversationDialog();
        },
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  void _showStartNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: const Text('Recherchez un artisan ou un commerçant pour commencer une conversation.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ici, vous pouvez naviguer vers un écran de recherche d'utilisateurs
            },
            child: const Text('Rechercher'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(Map<String, dynamic> conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer la conversation'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(conversation['id']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquer ce contact'),
              onTap: () {
                Navigator.of(context).pop();
                _showBlockConfirmation(conversation['partner']['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ici, vous pouvez implémenter la suppression de la conversation
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmation(int userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer ce contact'),
        content: const Text('Êtes-vous sûr de vouloir bloquer ce contact ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _chatService.blockUser(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact bloqué avec succès')),
                );
                // Actualiser la liste
                _loadConversations();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors du blocage: $e')),
                );
              }
            },
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
  }
}