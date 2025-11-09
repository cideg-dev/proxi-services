import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class PredictiveAnalysisService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir les prédictions de demande pour une période spécifique
  Future<Map<String, dynamic>> getDemandPredictions({
    required DateTime startDate,
    required DateTime endDate,
    String? serviceCategory,
    String? location,
  }) async {
    final queryParams = <String, String>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    
    if (serviceCategory != null) queryParams['serviceCategory'] = serviceCategory;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/predictions/demand').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des prédictions de demande: ${response.body}');
    }
  }

  // Obtenir les tendances de réservation
  Future<Map<String, dynamic>> getBookingTrends({
    String? serviceCategory,
    String? location,
  }) async {
    final queryParams = <String, String>{};
    if (serviceCategory != null) queryParams['serviceCategory'] = serviceCategory;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/predictions/booking-trends').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des tendances de réservation: ${response.body}');
    }
  }

  // Obtenir les périodes de forte demande prévues
  Future<List<dynamic>> getPeakDemandPeriods({
    required int daysAhead,
    String? serviceCategory,
    String? location,
  }) async {
    final queryParams = <String, String>{
      'daysAhead': daysAhead.toString(),
    };
    if (serviceCategory != null) queryParams['serviceCategory'] = serviceCategory;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/predictions/peak-periods').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des périodes de forte demande: ${response.body}');
    }
  }

  // Obtenir les services les plus demandés pour une période future
  Future<List<dynamic>> getTopServicesPrediction({
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    final queryParams = <String, String>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/predictions/top-services').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des services les plus demandés: ${response.body}');
    }
  }

  // Obtenir les horaires de pointe prévus
  Future<Map<String, dynamic>> getPeakHoursPrediction({
    required DateTime date,
    String? serviceCategory,
    String? location,
  }) async {
    final response = await _apiService.get(
      '/api/predictions/peak-hours?date=${date.toIso8601String()}'
      '&${serviceCategory != null ? 'serviceCategory=$serviceCategory&' : ''}'
      '${location != null ? 'location=$location' : ''}'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des horaires de pointe: ${response.body}');
    }
  }

  // Obtenir les suggestions de disponibilité prédictive
  Future<List<dynamic>> getPredictiveAvailability({
    required int artisanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiService.get(
      '/api/predictions/availability/$artisanId'
      '?startDate=${startDate.toIso8601String()}'
      '&endDate=${endDate.toIso8601String()}'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des suggestions de disponibilité: ${response.body}');
    }
  }

  // Obtenir les alertes de demande prédictive
  Future<List<dynamic>> getPredictiveDemandAlerts() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/predictions/alerts/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des alertes de demande: ${response.body}');
    }
  }

  // Obtenir les prédictions personnalisées pour un artisan/commerçant
  Future<Map<String, dynamic>> getPersonalizedPredictions() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/predictions/personalized/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des prédictions personnalisées: ${response.body}');
    }
  }

  // Obtenir les prédictions de croissance
  Future<Map<String, dynamic>> getGrowthPredictions({
    String? serviceCategory,
    String? location,
  }) async {
    final queryParams = <String, String>{};
    if (serviceCategory != null) queryParams['serviceCategory'] = serviceCategory;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/predictions/growth').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des prédictions de croissance: ${response.body}');
    }
  }

  // Calculer la probabilité de réservation
  Future<Map<String, dynamic>> calculateBookingProbability({
    required int artisanId,
    required DateTime dateTime,
    String? serviceType,
  }) async {
    final response = await _apiService.post('/api/predictions/booking-probability',
      body: {
        'artisanId': artisanId,
        'dateTime': dateTime.toIso8601String(),
        if (serviceType != null) 'serviceType': serviceType,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du calcul de la probabilité de réservation: ${response.body}');
    }
  }
}