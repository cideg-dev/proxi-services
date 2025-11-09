import 'package:flutter/material.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.getNotifications();
    
    return Container(
      width: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (NotificationService.getUnreadCount() > 0)
                  TextButton(
                    onPressed: () {
                      NotificationService.markAllAsRead();
                      setState(() {});
                    },
                    child: const Text('Tout marquer comme lu'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text('Aucune notification'),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationCard(
                        title: notification.title,
                        content: notification.content,
                        time: notification.time,
                        icon: notification.icon,
                        iconColor: notification.iconColor,
                        isUnread: !notification.isRead,
                        onTap: () {
                          NotificationService.markAsRead(notification.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}