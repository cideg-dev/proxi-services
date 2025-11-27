import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineModeService {
  static final OfflineModeService _instance = OfflineModeService._internal();
  factory OfflineModeService() => _instance;
  OfflineModeService._internal();

  static const String _offlineDataKey = 'offline_data';
  static const String _offlineModeKey = 'offline_mode';

  late SharedPreferences _prefs;
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  bool _isInitialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // Méthode pour s'assurer que le service est initialisé avant utilisation
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // Activer/désactiver le mode hors-ligne
  Future<void> setOfflineMode(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_offlineModeKey, enabled);
  }

  // Vérifier si le mode hors-ligne est activé
  bool isOfflineMode() {
    _ensureInitialized();
    return _prefs.getBool(_offlineModeKey) ?? false;
  }

  // Enregistrer des données pour le mode hors-ligne
  Future<void> cacheData(String key, dynamic data) async {
    await _ensureInitialized();
    await _prefs.setString(key, jsonEncode(data));
  }

  // Récupérer des données du mode hors-ligne
  T? getCachedData<T>(String key, T Function(dynamic) parser) {
    _ensureInitialized();
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      final jsonData = jsonDecode(jsonString);
      return parser(jsonData);
    }
    return null;
  }

  // Enregistrer les informations de profil pour le mode hors-ligne
  Future<void> cacheProfileData(Map<String, dynamic> profile) async {
    await cacheData('user_profile', profile);
  }

  // Obtenir les informations de profil en mode hors-ligne
  Map<String, dynamic>? getCachedProfileData() {
    return getCachedData<Map<String, dynamic>>('user_profile', (data) => Map<String, dynamic>.from(data));
  }

  // Enregistrer les artisans récents pour le mode hors-ligne
  Future<void> cacheRecentArtisans(List<dynamic> artisans) async {
    await cacheData('recent_artisans', artisans);
  }

  // Obtenir les artisans récents en mode hors-ligne
  List<dynamic>? getCachedRecentArtisans() {
    return getCachedData<List<dynamic>>('recent_artisans', (data) => List<dynamic>.from(data));
  }

  // Mettre en file d'attente une action à effectuer en ligne
  Future<void> queueOfflineAction(String action, Map<String, dynamic> params) async {
    await _ensureInitialized();
    final queue = _prefs.getStringList('offline_queue') ?? <String>[];
    final actionData = {
      'action': action,
      'params': params,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    queue.add(jsonEncode(actionData));
    await _prefs.setStringList('offline_queue', queue);
  }

  // Obtenir la file d'attente des actions hors-ligne
  List<Map<String, dynamic>> getOfflineQueue() {
    _ensureInitialized();
    final queue = _prefs.getStringList('offline_queue') ?? <String>[];
    return queue.map((item) {
      final data = jsonDecode(item);
      return {
        'action': data['action'],
        'params': Map<String, dynamic>.from(data['params']),
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  // Traiter la file d'attente des actions hors-ligne
  Future<void> processOfflineQueue() async {
    final queue = getOfflineQueue();
    for (final actionData in queue) {
      try {
        await _executeAction(actionData['action'], actionData['params']);
        // Retirer l'action de la file après exécution réussie
        removeFromQueue(actionData);
      } catch (e) {
        // Garder l'action dans la file en cas d'échec
        print('Échec de l\'exécution de l\'action hors-ligne: $e');
      }
    }
  }

  // Retirer une action de la file
  Future<void> removeFromQueue(Map<String, dynamic> actionData) async {
    await _ensureInitialized();
    final queue = _prefs.getStringList('offline_queue') ?? <String>[];
    final actionString = jsonEncode({
      'action': actionData['action'],
      'params': actionData['params'],
      'timestamp': actionData['timestamp'],
    });
    queue.remove(actionString);
    await _prefs.setStringList('offline_queue', queue);
  }

  // Exécuter une action spécifique
  Future<void> _executeAction(String action, Map<String, dynamic> params) async {
    switch (action) {
      case 'book_appointment':
        await _bookAppointmentOffline(params);
        break;
      case 'send_review':
        await _sendReviewOffline(params);
        break;
      case 'send_message':
        await _sendMessageOffline(params);
        break;
      case 'make_payment':
        await _makePaymentOffline(params);
        break;
      default:
        throw Exception('Action non supportée: $action');
    }
  }

  // Méthodes pour chaque type d'action hors-ligne
  Future<void> _bookAppointmentOffline(Map<String, dynamic> params) async {
    // Exécuter l'action de réservation de rendez-vous
    // Cette méthode devra être adaptée en fonction de votre service de rendez-vous
  }

  Future<void> _sendReviewOffline(Map<String, dynamic> params) async {
    // Exécuter l'action d'envoi d'avis
    // Cette méthode devra être adaptée en fonction de votre service d'avis
  }

  Future<void> _sendMessageOffline(Map<String, dynamic> params) async {
    // Exécuter l'action d'envoi de message
    // Cette méthode devra être adaptée en fonction de votre service de messagerie
  }

  Future<void> _makePaymentOffline(Map<String, dynamic> params) async {
    // Exécuter l'action de paiement
    // Cette méthode devra être adaptée en fonction de votre service de paiement
  }

  // Vérifier la connectivité
  Future<bool> isConnected() async {
    try {
      final result = await _apiService.getPublic('/api/ping');
      return result.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Synchroniser les données en mode hors-ligne
  Future<void> syncOfflineData() async {
    if (await isConnected()) {
      await processOfflineQueue();
      
      // Synchroniser les données de profil
      try {
        final profile = await _apiService.get('/api/users/profile');
        await cacheProfileData(jsonDecode(profile.body));
      } catch (e) {
        // Gérer l'erreur de synchronisation
      }
      
      // Synchroniser d'autres données selon les besoins
    }
  }

  // Nettoyer la file d'attente
  Future<void> clearOfflineQueue() async {
    await _ensureInitialized();
    await _prefs.setStringList('offline_queue', <String>[]);
  }

  // Obtenir le nombre d'actions en attente
  int getOfflineQueueCount() {
    _ensureInitialized();
    final queue = _prefs.getStringList('offline_queue') ?? <String>[];
    return queue.length;
  }
}