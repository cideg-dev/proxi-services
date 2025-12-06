import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/conversation_model.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partner = conversation.otherParticipant;
    final lastMessage = conversation.lastMessage;
    final partnerName = partner?.name ?? partner?.email ?? 'Utilisateur';
    final messageContent = lastMessage?.content ?? '';
    final timestamp = conversation.updatedAt;
    final formattedTime = DateFormat('HH:mm').format(timestamp);
    final unreadCount = conversation.unreadCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          backgroundImage: partner?.avatarUrl != null ? NetworkImage(partner!.avatarUrl!) : null,
          child: partner?.avatarUrl == null 
              ? Icon(Icons.person, color: theme.colorScheme.primary) 
              : null,
        ),
        title: Row(
          children: [
            Text(
              partnerName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            // Online status check would need to be added to Conversation model or fetched separately
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              messageContent.length > 50 
                  ? '${messageContent.substring(0, 50)}...' 
                  : messageContent,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              formattedTime,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}