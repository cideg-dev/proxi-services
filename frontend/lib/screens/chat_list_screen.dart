
import 'package:flutter/material.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final TokenManager _tokenManager = TokenManager();
  late Future<List<dynamic>> _conversationsFuture;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    _currentUserId = await _tokenManager.getUserId();
    setState(() {
      _conversationsFuture = _chatService.getConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Conversations'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement des conversations: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune conversation pour le moment.'));
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final partner = conversation['partner'];
              final lastMessage = conversation['lastMessage'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: partner['imageUrl'] != null
                        ? NetworkImage(partner['imageUrl'])
                        : null,
                    child: partner['imageUrl'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(partner['nom'] ?? 'Utilisateur inconnu'),
                  subtitle: Text(lastMessage['content'] ?? 'Pas de message'),
                  trailing: Text(
                    lastMessage != null
                        ? DateTime.parse(lastMessage['timestamp']).toLocal().toString().substring(11, 16)
                        : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          conversationId: conversation['id'],
                          partnerId: partner['id'],
                          partnerName: partner['nom'] ?? 'Utilisateur inconnu',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
