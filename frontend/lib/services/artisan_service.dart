import 'dart:convert';
import 'dart:io';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart'; // Still needed for getUserId

class ArtisanService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager(); // Keep for getUserId

  Future<List<dynamic>> getArtisans() async {
    final response = await _apiService.getPublic('/api/artisans');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisans');
    }
  }

  Future<Map<String, dynamic>> getArtisanById(int id) async {
    final response = await _apiService.getPublic('/api/artisans/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisan');
    }
  }

  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/reviews');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<List<dynamic>> getArtisanPortfolio(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/portfolio');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load portfolio');
    }
  }

  Future<List<dynamic>> getArtisanServices(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/services');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<void> addPortfolioItem(int artisanId, File image, String name, String description, String? price) async {
    final fields = {
      'name': name,
      'description': description,
    };
    if (price != null && price.isNotEmpty) {
      fields['price'] = price;
    }

    final response = await _apiService.multipartRequest(
      'POST',
      '/api/artisans/$artisanId/portfolio',
      fields: fields,
      files: {'portfolioImage': image},
    );

    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to add portfolio item: $responseBody');
    }
  }

  Future<List<dynamic>> getRecentPortfolioItems() async {
    final response = await _apiService.getPublic('/api/artisans/portfolio/recent');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recent portfolio items');
    }
  }

  Future<List<dynamic>> getFavoriteArtisans({String? sortBy, double? latitude, double? longitude}) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final Map<String, String> queryParams = {};
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();

    final uri = Uri.parse('/api/artisans/$userId/favorites').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load favorite artisans: ${response.body}');
    }
  }

  Future<void> addFavorite(int professionalId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final response = await _apiService.post('/api/artisans/$userId/favorites/$professionalId');
    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to add favorite';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to add favorite: ${response.body}');
      }
    }
  }

  Future<void> removeFavorite(int professionalId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final response = await _apiService.delete('/api/artisans/$userId/favorites/$professionalId');
    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to remove favorite';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to remove favorite: ${response.body}');
      }
    }
  }

  Future<List<dynamic>> getFeaturedProfessionals() async {
    final response = await _apiService.getPublic('/api/professionals/featured');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load featured professionals: ${response.body}');
    }
  }

  // --- Service Management ---

  Future<List<dynamic>> getMyArtisanServices() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    // Re-use getArtisanServices, but with the logged-in user's ID
    return getArtisanServices(userId);
  }

  Future<dynamic> addArtisanService(Map<String, dynamic> serviceData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _apiService.post(
      '/api/artisans/$userId/services',
      body: serviceData,
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add service: ${response.body}');
    }
  }

  Future<dynamic> updateArtisanService(int serviceId, Map<String, dynamic> serviceData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _apiService.put(
      '/api/artisans/$userId/services/$serviceId',
      body: serviceData,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update service: ${response.body}');
    }
  }

  Future<void> deleteArtisanService(int serviceId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _apiService.delete('/api/artisans/$userId/services/$serviceId');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }
}
