import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class AdvancedSearchService {
  final ApiService _apiService = ApiService();

  // Recherche avancée pour les artisans
  Future<List<dynamic>> searchArtisans({
    String? query,
    String? specialty,
    double? minRating,
    double? maxRating,
    double? minDistance,
    double? maxDistance,
    String? sortBy = 'rating',
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{};

    if (query != null) queryParams['q'] = query;
    if (specialty != null) queryParams['specialty'] = specialty;
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (maxRating != null) queryParams['maxRating'] = maxRating.toString();
    if (minDistance != null) queryParams['minDistance'] = minDistance.toString();
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('/api/artisans/search').replace(queryParameters: queryParams);
    final response = await _apiService.getPublic(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la recherche d\'artisans: ${response.body}');
    }
  }

  // Recherche avancée pour les commerçants
  Future<List<dynamic>> searchMerchants({
    String? query,
    String? category,
    double? minRating,
    double? maxRating,
    double? minDistance,
    double? maxDistance,
    String? sortBy = 'rating',
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{};

    if (query != null) queryParams['q'] = query;
    if (category != null) queryParams['category'] = category;
    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (maxRating != null) queryParams['maxRating'] = maxRating.toString();
    if (minDistance != null) queryParams['minDistance'] = minDistance.toString();
    if (maxDistance != null) queryParams['maxDistance'] = maxDistance.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('/api/merchants/search').replace(queryParameters: queryParams);
    final response = await _apiService.getPublic(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la recherche de commerçants: ${response.body}');
    }
  }

  // Recherche globale pour les professionnels
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    double? minRating,
    String? category,
    String? location,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (minRating != null) queryParams['minRating'] = minRating.toString();
    if (category != null) queryParams['category'] = category;
    if (location != null) queryParams['location'] = location;

    final uri = Uri.parse('/api/search/professionals').replace(queryParameters: queryParams);
    final response = await _apiService.getPublic(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la recherche globale: ${response.body}');
    }
  }

  // Obtenir les suggestions de recherche
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse('/api/search/suggestions').replace(queryParameters: {'q': query});
    final response = await _apiService.getPublic(uri.toString());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['suggestions'] as List).cast<String>();
    } else {
      throw Exception('Échec du chargement des suggestions: ${response.body}');
    }
  }

  // Obtenir les filtres populaires/catégories
  Future<Map<String, dynamic>> getSearchFilters() async {
    final response = await _apiService.getPublic('/api/search/filters');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des filtres: ${response.body}');
    }
  }
}