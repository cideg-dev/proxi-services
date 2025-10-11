import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/notification_ui_provider.dart';

class InAppNotification extends StatelessWidget {
  const InAppNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationUIProvider>(
      builder: (context, provider, child) {
        if (provider.notification == null) {
          return const SizedBox.shrink();
        }

        final notification = provider.notification!;
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: provider.hideNotification,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(notification.icon, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            notification.message,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
