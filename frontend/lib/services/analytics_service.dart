import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir les statistiques principales
  Future<Map<String, dynamic>> getMainStats() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await ApiService.get('/api/analytics/main-stats/$userId');

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement des statistiques: $errorMessage');
    }
  }

  // Obtenir les données pour le graphique de revenus
  Future<List<dynamic>> getRevenueData({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'daily', // 'daily', 'weekly', 'monthly'
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get(
      '/api/analytics/revenue/$userId?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}&period=$period'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des données de revenus: ${response.body}');
    }
  }

  // Obtenir les données pour le graphique des rendez-vous
  Future<List<dynamic>> getAppointmentData({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'daily',
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get(
      '/api/analytics/appointments/$userId?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}&period=$period'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des données de rendez-vous: ${response.body}');
    }
  }

  // Obtenir les données pour le graphique des évaluations
  Future<List<dynamic>> getReviewData({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'daily',
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get(
      '/api/analytics/reviews/$userId?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}&period=$period'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des données d\'évaluations: ${response.body}');
    }
  }

  // Obtenir les statistiques comparatives
  Future<Map<String, dynamic>> getComparisonStats({
    required DateTime currentPeriodStart,
    required DateTime currentPeriodEnd,
    required DateTime previousPeriodStart,
    required DateTime previousPeriodEnd,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/analytics/comparison/$userId',
      body: {
        'currentPeriod': {
          'start': currentPeriodStart.toIso8601String(),
          'end': currentPeriodEnd.toIso8601String(),
        },
        'previousPeriod': {
          'start': previousPeriodStart.toIso8601String(),
          'end': previousPeriodEnd.toIso8601String(),
        },
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des statistiques comparatives: ${response.body}');
    }
  }

  // Obtenir les tendances des services les plus demandés
  Future<List<dynamic>> getTopServicesData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get(
      '/api/analytics/top-services/$userId?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des tendances de services: ${response.body}');
    }
  }

  // Obtenir les données géographiques (pour la visualisation des zones actives)
  Future<List<dynamic>> getLocationData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get(
      '/api/analytics/location/$userId?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des données géographiques: ${response.body}');
    }
  }

  // Obtenir les préférences des clients
  Future<Map<String, dynamic>> getClientPreferences() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/analytics/client-preferences/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des préférences clients: ${response.body}');
    }
  }

  // Obtenir les rapports personnalisés
  Future<Map<String, dynamic>> getCustomReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? additionalParams,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final body = {
      'reportType': reportType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (additionalParams != null) ...additionalParams,
    };

    final response = await _apiService.post('/api/analytics/custom-report/$userId', body: body);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du rapport personnalisé: ${response.body}');
    }
  }
}