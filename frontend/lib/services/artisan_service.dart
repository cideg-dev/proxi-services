import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';
import 'dart:io';

class ArtisanService {
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getArtisans() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisans');
    }
  }

  Future<Map<String, dynamic>> getArtisanById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$id'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisan');
    }
  }

  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$artisanId/reviews'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<List<dynamic>> getArtisanPortfolio(int artisanId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$artisanId/portfolio'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load portfolio');
    }
  }

    Future<List<dynamic>> getArtisanServices(int artisanId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$artisanId/services'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  Future<void> addPortfolioItem(int artisanId, File image, String caption) async {
    final token = await _tokenManager.getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$artisanId/portfolio'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caption'] = caption;
    request.files.add(await http.MultipartFile.fromPath('portfolioImage', image.path));

    var response = await request.send();

    if (response.statusCode != 201) {
      throw Exception('Failed to add portfolio item');
    }
  }

  // NEW: Get favorite professionals for the logged-in user
  Future<List<dynamic>> getFavoriteArtisans({String? sortBy, double? latitude, double? longitude}) async {
    final token = await _tokenManager.getToken();
    final userId = await _tokenManager.getUserId(); // Assuming userId is available in TokenManager

    if (token == null || userId == null) {
      throw Exception('Authentication token or user ID not found.');
    }

    // Build query parameters
    final Map<String, String> queryParams = {};
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/artisans/$userId/favorites').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load favorite artisans');
    }
  }

  // NEW: Add a professional to favorites
  Future<void> addFavorite(int professionalId) async {
    final token = await _tokenManager.getToken();
    final userId = await _tokenManager.getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication token or user ID not found.');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$userId/favorites/$professionalId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to add favorite';
      throw Exception(errorMessage);
    }
  }

  // NEW: Remove a professional from favorites
  Future<void> removeFavorite(int professionalId) async {
    final token = await _tokenManager.getToken();
    final userId = await _tokenManager.getUserId();

    if (token == null || userId == null) {
      throw Exception('Authentication token or user ID not found.');
    }

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$userId/favorites/$professionalId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to remove favorite';
      throw Exception(errorMessage);
    }
  }
}
