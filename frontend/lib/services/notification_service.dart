import 'package:flutter/material.dart';

class NotificationItem {
  final int id;
  final String title;
  final String content;
  final String time;
  final String type;
  final bool isRead;
  final IconData icon;
  final Color iconColor;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    this.isRead = false,
    required this.icon,
    required this.iconColor,
  });
}

class NotificationService {
  static List<NotificationItem> _notifications = [
    NotificationItem(
      id: 1,
      title: "Nouvelle demande de service",
      content: "Un client a posté une nouvelle demande dans votre zone",
      time: "Il y a 5 min",
      type: "demande",
      icon: Icons.assignment_outlined,
      iconColor: Colors.blue,
    ),
    NotificationItem(
      id: 2,
      title: "Demande acceptée",
      content: "Votre demande a été acceptée par un artisan",
      time: "Il y a 25 min",
      type: "acceptation",
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    ),
    NotificationItem(
      id: 3,
      title: "Nouveau message",
      content: "Un artisan vous a envoyé un message concernant votre demande",
      time: "Il y a 1h",
      type: "message",
      icon: Icons.message_outlined,
      iconColor: Colors.purple,
    ),
    NotificationItem(
      id: 4,
      title: "Profil mis à jour",
      content: "Votre profil artisan a été mis à jour avec succès",
      time: "Hier",
      type: "profil",
      icon: Icons.person_outline,
      iconColor: Colors.orange,
    ),
    NotificationItem(
      id: 5,
      title: "Nouvelle évaluation",
      content: "Un client a laissé une évaluation pour votre service",
      time: "2 jours ago",
      type: "evaluation",
      icon: Icons.star_border_outlined,
      iconColor: Colors.amber,
    ),
  ];

  static List<NotificationItem> getNotifications() {
    return _notifications;
  }

  static List<NotificationItem> getUnreadNotifications() {
    return _notifications.where((notification) => !notification.isRead).toList();
  }

  static void markAsRead(int id) {
    final index = _notifications.indexWhere((notification) => notification.id == id);
    if (index != -1) {
      _notifications[index] = NotificationItem(
        id: _notifications[index].id,
        title: _notifications[index].title,
        content: _notifications[index].content,
        time: _notifications[index].time,
        type: _notifications[index].type,
        isRead: true,
        icon: _notifications[index].icon,
        iconColor: _notifications[index].iconColor,
      );
    }
  }

  static void markAllAsRead() {
    _notifications = _notifications.map((notification) => NotificationItem(
      id: notification.id,
      title: notification.title,
      content: notification.content,
      time: notification.time,
      type: notification.type,
      isRead: true,
      icon: notification.icon,
      iconColor: notification.iconColor,
    )).toList();
  }

  static int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }
}