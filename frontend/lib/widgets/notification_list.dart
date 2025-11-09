import 'package:flutter/material.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final NotificationService _notificationService = NotificationService();
  
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationService.getUserNotifications();
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationsCount();
      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      print('Erreur lors du chargement du nombre de notifications non lues: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      setState(() {
        // Mettre à jour la liste localement
        _notifications = _notifications.map((notification) {
          if (notification['id'] == notificationId) {
            return {...notification, 'isRead': true};
          }
          return notification;
        }).toList();
        
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      setState(() {
        // Mettre à jour la liste localement
        _notifications = _notifications.map((notification) {
          return {...notification, 'isRead': true};
        }).toList();
        
        _unreadCount = 0;
      });
    } catch (e) {
      print('Erreur lors du marquage de toutes comme lues: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout marquer comme lu'),
            ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadNotifications,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_none_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune notification',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Les notifications apparaîtront ici',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadNotifications();
                        await _loadUnreadCount();
                      },
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationItem(notification, theme);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(dynamic notification, ThemeData theme) {
    final title = notification['title'] ?? 'Notification';
    final content = notification['content'] ?? notification['message'] ?? 'Pas de contenu';
    final isRead = notification['isRead'] ?? notification['read'] ?? false;
    final type = notification['type'] ?? 'general';
    final createdAt = notification['createdAt'] != null 
        ? DateTime.parse(notification['createdAt']) 
        : DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(createdAt);
    final formattedDate = DateFormat('dd/MM/yyyy').format(createdAt);
    
    IconData icon;
    Color iconColor;
    
    switch (type.toLowerCase()) {
      case 'message':
        icon = Icons.message_outlined;
        iconColor = Colors.purple;
        break;
      case 'appointment':
        icon = Icons.event_outlined;
        iconColor = Colors.blue;
        break;
      case 'payment':
        icon = Icons.payment_outlined;
        iconColor = Colors.green;
        break;
      case 'review':
        icon = Icons.star_outlined;
        iconColor = Colors.amber;
        break;
      case 'system':
        icon = Icons.info_outlined;
        iconColor = Colors.grey;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isRead ? null : theme.cardColor.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            Text(
              formattedTime,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                color: isRead ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          _markAsRead(notification['id']);
          // Vous pouvez également naviguer vers l'écran pertinent ici
        },
      ),
    );
  }
}