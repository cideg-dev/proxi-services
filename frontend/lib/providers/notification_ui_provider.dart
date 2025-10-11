import 'package:flutter/material.dart';
import 'dart:async';

class NotificationData {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  NotificationData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class NotificationUIProvider with ChangeNotifier {
  NotificationData? _notification;
  NotificationData? get notification => _notification;
  Timer? _timer;

  void showNotification(NotificationData data) {
    _notification = data;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      _notification = null;
      notifyListeners();
    });
  }

  void hideNotification() {
    _notification = null;
    _timer?.cancel();
    notifyListeners();
  }
}
