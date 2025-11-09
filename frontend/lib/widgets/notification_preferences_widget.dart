import 'package:flutter/material.dart';
import 'package:frontend/services/notification_service.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  State<NotificationPreferencesWidget> createState() => _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState extends State<NotificationPreferencesWidget> {
  final NotificationService _notificationService = NotificationService();
  
  bool _isLoading = true;
  bool _appNotifications = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _notificationService.getNotificationPreferences();
      
      setState(() {
        _appNotifications = preferences['app'] ?? true;
        _pushNotifications = preferences['push'] ?? true;
        _emailNotifications = preferences['email'] ?? false;
        _smsNotifications = preferences['sms'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des préférences: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.updateNotificationPreferences(
        enableAppNotifications: _appNotifications,
        enablePushNotifications: _pushNotifications,
        enableEmailNotifications: _emailNotifications,
        enableSmsNotifications: _smsNotifications,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences mises à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _errorMessage.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
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
                onPressed: _loadPreferences,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Préférences de Notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Notifications dans l'application
          SwitchListTile(
            title: const Text('Notifications dans l\'application'),
            subtitle: const Text('Afficher les notifications dans l\'application'),
            value: _appNotifications,
            onChanged: (value) {
              setState(() {
                _appNotifications = value;
              });
              _updatePreferences();
            },
          ),
          
          // Notifications push
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir des notifications même lorsque l\'application est fermée'),
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
              _updatePreferences();
            },
          ),
          
          // Notifications par email
          SwitchListTile(
            title: const Text('Notifications par email'),
            subtitle: const Text('Recevoir des notifications par email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
              _updatePreferences();
            },
          ),
          
          // Notifications par SMS
          SwitchListTile(
            title: const Text('Notifications par SMS'),
            subtitle: const Text('Recevoir des notifications importantes par SMS'),
            value: _smsNotifications,
            onChanged: (value) {
              setState(() {
                _smsNotifications = value;
              });
              _updatePreferences();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Légende
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos des notifications',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Les notifications dans l\'application s\'affichent dans l\'onglet Notifications',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Les notifications push s\'affichent même quand l\'application est fermée',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Les notifications par email/SMS sont réservées aux événements importants',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}