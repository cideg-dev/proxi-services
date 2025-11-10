import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class NotificationItem {
  final int id;
  final String title;
  final String content;
  final String time;
  final String type;
  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final DateTime? createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    this.isRead = false,
    required this.icon,
    required this.iconColor,
    this.createdAt,
  });
}

class NotificationService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();
  
  // Nouvelle partie: Fonctionnalités côté serveur
  // Obtenir les notifications de l'utilisateur
  Future<List<dynamic>> getUserNotifications() async {
    final response = await _apiService.get('/api/notifications');

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Échec du chargement des notifications: ${response.body}');
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await _apiService.put('/api/notifications/$notificationId/read');

    if (response.statusCode != 200) {
      throw Exception('Échec du marquage comme lu: ${response.body}');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllNotificationsAsRead() async {
    final response = await _apiService.put('/api/notifications/mark-all-read');

    if (response.statusCode != 200) {
      throw Exception('Échec du marquage de toutes comme lues: ${response.body}');
    }
  }

  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadNotificationsCount() async {
    final response = await _apiService.get('/api/notifications/unread-count');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Échec du chargement du nombre de notifications: ${response.body}');
    }
  }

  // S'abonner aux notifications push
  Future<void> subscribeToPushNotifications(String token) async {
    final response = await _apiService.post('/api/notifications/subscribe',
      body: {'pushToken': token}
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de l\'abonnement aux notifications: ${response.body}');
    }
  }

  // Se désabonner des notifications push
  Future<void> unsubscribeFromPushNotifications(String token) async {
    final response = await _apiService.post('/api/notifications/unsubscribe',
      body: {'pushToken': token}
    );

    if (response.statusCode != 200) {
      throw Exception('Échec du désabonnement des notifications: ${response.body}');
    }
  }

  // Obtenir les préférences de notification de l'utilisateur
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _apiService.get('/api/notifications/preferences');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des préférences: ${response.body}');
    }
  }

  // Mettre à jour les préférences de notification
  Future<void> updateNotificationPreferences({
    bool? enableAppNotifications,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableSmsNotifications,
  }) async {
    final response = await _apiService.put('/api/notifications/preferences',
      body: {
        if (enableAppNotifications != null) 'app': enableAppNotifications,
        if (enablePushNotifications != null) 'push': enablePushNotifications,
        if (enableEmailNotifications != null) 'email': enableEmailNotifications,
        if (enableSmsNotifications != null) 'sms': enableSmsNotifications,
      }
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour des préférences: ${response.body}');
    }
  }

  // Créer une notification personnalisée (pour les administrateurs ou fonctionnalités spécifiques)
  Future<void> createCustomNotification({
    required String title,
    required String body,
    String? type,
    int? targetUserId,
    Map<String, dynamic>? data,
  }) async {
    final response = await _apiService.post('/api/notifications/custom',
      body: {
        'title': title,
        'body': body,
        if (type != null) 'type': type,
        if (targetUserId != null) 'targetUserId': targetUserId,
        if (data != null) 'data': data,
      }
    );

    if (response.statusCode != 201) {
      throw Exception('Échec de la création de la notification: ${response.body}');
    }
  }

  // Ancienne partie: Méthodes statiques pour la compatibilité
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