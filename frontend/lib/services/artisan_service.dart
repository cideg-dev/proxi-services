import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/models/artisan_model.dart';

class ArtisanService {
  final TokenManager _tokenManager = TokenManager();

  Future<List<Artisan>> getArtisans() async {
    final response = await ApiService.get('/artisans');
    if (ApiService.isSuccessful(response.statusCode)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load artisans: $errorMessage');
    }
  }

  Future<Artisan> getArtisanById(int id) async {
    final response = await ApiService.get('/artisans/$id');
    if (ApiService.isSuccessful(response.statusCode)) {
      return Artisan.fromJson(jsonDecode(response.body));
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load artisan: $errorMessage');
    }
  }

  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await ApiService.get('/reviews?artisanId=$artisanId');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load reviews: $errorMessage');
    }
  }

  Future<double> getArtisanAverageRating(int artisanId) async {
    final response = await ApiService.get('/artisans/$artisanId/rating');
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load average rating: $errorMessage');
    }
  }

  Future<List<dynamic>> getArtisanPortfolio(int artisanId) async {
    final response = await ApiService.get('/artisans/$artisanId/portfolio');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load portfolio: $errorMessage');
    }
  }

  Future<List<dynamic>> getArtisanServices(int artisanId) async {
    final response = await ApiService.get('/artisans/$artisanId/services');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load services: $errorMessage');
    }
  }

  Future<void> addPortfolioItem(int artisanId, dynamic image, String name, String description, String? price) async {
    final token = await _tokenManager.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/artisans/$artisanId/portfolio');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;
    if (price != null && price.isNotEmpty) {
      request.fields['price'] = price;
    }

    final imageBytes = await image.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'portfolioImage',
      imageBytes,
      filename: image.name,
    );
    request.files.add(multipartFile);

    final response = await request.send();

    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to add portfolio item: $responseBody');
    }
  }

  Future<List<dynamic>> getRecentPortfolioItems() async {
    final response = await ApiService.get('/artisans/portfolio/recent');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load recent portfolio items: $errorMessage');
    }
  }

  Future<List<Artisan>> getFavoriteArtisans({String? sortBy, double? latitude, double? longitude}) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final Map<String, String> queryParams = {};
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();

    String queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    String path = '/$userId/favorites';
    if (queryString.isNotEmpty) {
      path += '?$queryString';
    }

    final response = await ApiService.get('/artisans$path');

    if (ApiService.isSuccessful(response.statusCode)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load favorite artisans: $errorMessage');
    }
  }

  Future<void> addFavorite(int professionalId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final response = await ApiService.post('/artisans/$userId/favorites/$professionalId', {});
    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to add favorite: $errorMessage');
    }
  }

  Future<void> removeFavorite(int professionalId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final response = await ApiService.delete('/artisans/$userId/favorites/$professionalId');
    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to remove favorite: $errorMessage');
    }
  }

  Future<List<Artisan>> getFeaturedProfessionals() async {
    final response = await ApiService.getPublic('/artisans/featured');
    if (ApiService.isSuccessful(response.statusCode)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load featured professionals: $errorMessage');
    }
  }

  Future<List<Artisan>> getArtisansWithLocation() async {
    final response = await ApiService.get('/artisans/with-location');
    if (ApiService.isSuccessful(response.statusCode)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load artisans with location: $errorMessage');
    }
  }

  Future<List<Artisan>> getArtisansByCoordinates(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await ApiService.get('/artisans/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}');
    if (ApiService.isSuccessful(response.statusCode)) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load artisans by coordinates: $errorMessage');
    }
  }

  Future<List<Artisan>> getAllArtisansWithPortfolio() async {
    try {
      final artisans = await getArtisans();
      List<Artisan> result = [];
      for (var artisan in artisans) {
        try {
          // Keep existing logic but adapted.
          // Ideally we should update backend to include portfolio.
          result.add(artisan);
        } catch (e) {
          result.add(artisan);
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to load artisans with portfolio: $e');
    }
  }

  Future<List<dynamic>> getPopularServices() async {
    final response = await ApiService.getPublic('/services/popular');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load popular services: $errorMessage');
    }
  }

  Future<List<dynamic>> getMyArtisanServices() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return getArtisanServices(userId);
  }

  Future<dynamic> addArtisanService(Map<String, dynamic> serviceData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await ApiService.post('/artisans/$userId/services', serviceData);

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to add service: $errorMessage');
    }
  }

  Future<dynamic> updateArtisanService(int serviceId, Map<String, dynamic> serviceData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await ApiService.put('/artisans/$userId/services/$serviceId', serviceData);

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to update service: $errorMessage');
    }
  }

  Future<void> deleteArtisanService(int serviceId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await ApiService.delete('/artisans/$userId/services/$serviceId');

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to delete service: $errorMessage');
    }
  }

  Future<void> generateAIPortfolio(String description) async {
    final response = await ApiService.post('/ai/generate-portfolio', {'description': description});

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to generate AI portfolio: $errorMessage');
    }
  }
}