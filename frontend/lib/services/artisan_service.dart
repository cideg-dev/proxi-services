import 'dart:convert';
import 'package:frontend/services/compatibility_api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;

class ArtisanService {
  final CompatibilityApiService _apiService = CompatibilityApiService();
  final TokenManager _tokenManager = TokenManager();

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

  // NEW: Get average rating for an artisan
  Future<double> getArtisanAverageRating(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/rating');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to load average rating');
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

  // Re-updated to be simpler and more robustly cross-platform.
  Future<void> addPortfolioItem(int artisanId, dynamic image, String name, String description, String? price) async {
    final fields = {
      'name': name,
      'description': description,
    };
    if (price != null && price.isNotEmpty) {
      fields['price'] = price;
    }

    // Universal method: Read image as bytes and use MultipartFile.fromBytes.
    // This works on both web and native platforms without conditional logic.
    final imageBytes = await image.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'portfolioImage', // Must match backend field name
      imageBytes,
      filename: image.name, // Pass the original filename
    );

    final response = await _apiService.multipartRequest(
      'POST',
      '/api/artisans/$artisanId/portfolio',
      fields: fields,
      files: [multipartFile], // Pass as a list of MultipartFile
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

  // NEW: Method to get artisans with location data
  Future<List<dynamic>> getArtisansWithLocation() async {
    final response = await _apiService.getPublic('/api/artisans/with-location');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisans with location: ${response.body}');
    }
  }

  // NEW: Method to get artisans by coordinates
  Future<List<dynamic>> getArtisansByCoordinates(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await _apiService.getPublic(
      '/api/artisans/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}'
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisans by coordinates: ${response.body}');
    }
  }

  // NEW: Method to get all artisans and merchants with their portfolios
  Future<List<dynamic>> getAllArtisansWithPortfolio() async {
    try {
      final artisans = await getArtisans();
      final List<dynamic> result = [];
      
      for (var artisan in artisans) {
        final portfolio = await getArtisanPortfolio(artisan['id']);
        artisan['portfolio'] = portfolio;
        result.add(artisan);
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to load artisans with portfolio: $e');
    }
  }

  // NEW: Method to get popular services
  Future<List<dynamic>> getPopularServices() async {
    final response = await _apiService.getPublic('/api/services/popular');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load popular services: ${response.body}');
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
