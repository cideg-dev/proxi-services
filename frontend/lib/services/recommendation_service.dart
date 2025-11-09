import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class RecommendationService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir des recommandations personnalisées pour l'utilisateur
  Future<List<dynamic>> getPersonalizedRecommendations({
    int limit = 10,
    String? category,
    double? minRating,
    double? maxDistance,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final queryParams = <String, String>{
      'userId': userId.toString(),
      'limit': limit.toString(),
    };
    
    if (category != null) queryParams['category'] = category;
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance.toString();

    final uri = Uri.parse('/api/recommendations/personalized').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations: ${response.body}');
    }
  }

  // Obtenir des recommandations basées sur l'historique
  Future<List<dynamic>> getHistoryBasedRecommendations() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/recommendations/history-based/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations basées sur l\'historique: ${response.body}');
    }
  }

  // Obtenir des recommandations basées sur la localisation
  Future<List<dynamic>> getLocationBasedRecommendations({
    required double latitude,
    required double longitude,
    int radius = 10, // en km
    int limit = 10,
  }) async {
    final response = await _apiService.get(
      '/api/recommendations/location-based?lat=$latitude&lng=$longitude&radius=$radius&limit=$limit'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations basées sur la localisation: ${response.body}');
    }
  }

  // Obtenir des recommandations de services similaires
  Future<List<dynamic>> getSimilarServices(int serviceId, {int limit = 5}) async {
    final response = await _apiService.get('/api/recommendations/similar/$serviceId?limit=$limit');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des services similaires: ${response.body}');
    }
  }

  // Obtenir des recommandations basées sur les tendances
  Future<List<dynamic>> getTrendingRecommendations({
    String? category,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('/api/recommendations/trending').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des tendances: ${response.body}');
    }
  }

  // Obtenir des recommandations saisonnières
  Future<List<dynamic>> getSeasonalRecommendations() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/recommendations/seasonal/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations saisonnières: ${response.body}');
    }
  }

  // Obtenir des recommandations basées sur le budget
  Future<List<dynamic>> getBudgetBasedRecommendations({
    required double maxBudget,
    String? category,
    int limit = 10,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final queryParams = <String, String>{
      'userId': userId.toString(),
      'maxBudget': maxBudget.toString(),
      'limit': limit.toString(),
    };
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('/api/recommendations/budget-based').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations basées sur le budget: ${response.body}');
    }
  }

  // Obtenir des recommandations de professionnels hautement notés
  Future<List<dynamic>> getHighRatedRecommendations({
    String? category,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('/api/recommendations/high-rated').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations hautement notées: ${response.body}');
    }
  }

  // Obtenir des recommandations exclusives (utilisateurs premium)
  Future<List<dynamic>> getExclusiveRecommendations() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/recommendations/exclusive/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations exclusives: ${response.body}');
    }
  }

  // Enregistrer l'interaction de l'utilisateur avec une recommandation
  Future<void> registerRecommendationInteraction({
    required String recommendationId,
    required String interactionType, // 'view', 'click', 'book', 'contact', etc.
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/recommendations/interaction',
      body: {
        'userId': userId,
        'recommendationId': recommendationId,
        'interactionType': interactionType,
      }
    );
    
    if (response.statusCode != 200) {
      throw Exception('Échec de l\'enregistrement de l\'interaction: ${response.body}');
    }
  }
}