import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/models/artisan_model.dart';

class ArtisanService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  Future<List<Artisan>> getArtisans() async {
    final response = await _functionsService.getArtisans();
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load artisans');
    }
  }

  Future<Artisan> getArtisanById(int id) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$id', 'GET');
    if (response.statusCode == 200) {
      return Artisan.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load artisan');
    }
  }

  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await _functionsService.getArtisanReviews(artisanId);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<double> getArtisanAverageRating(int artisanId) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$artisanId/rating', 'GET');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to load average rating');
    }
  }

  Future<List<dynamic>> getArtisanPortfolio(int artisanId) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$artisanId/portfolio', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load portfolio');
    }
  }

  Future<List<dynamic>> getArtisanServices(int artisanId) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$artisanId/services', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
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
    final response = await _functionsService.proxyToFunction('artisans', '/portfolio/recent', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recent portfolio items');
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

    // Construct query string manually or use Uri
    String queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    String path = '/$userId/favorites';
    if (queryString.isNotEmpty) {
      path += '?$queryString';
    }

    final response = await _functionsService.proxyToFunction('artisans', path, 'GET');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorite artisans: ${response.body}');
    }
  }

  Future<void> addFavorite(int professionalId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User ID not found.');
    }

    final response = await _functionsService.proxyToFunction('artisans', '/$userId/favorites/$professionalId', 'POST');
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

    final response = await _functionsService.proxyToFunction('artisans', '/$userId/favorites/$professionalId', 'DELETE');
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

  Future<List<Artisan>> getFeaturedProfessionals() async {
    final response = await _functionsService.getFeaturedProfessionals();
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load featured professionals: ${response.body}');
    }
  }

  Future<List<Artisan>> getArtisansWithLocation() async {
    final response = await _functionsService.proxyToFunction('artisans', '/with-location', 'GET');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load artisans with location: ${response.body}');
    }
  }

  Future<List<Artisan>> getArtisansByCoordinates(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await _functionsService.proxyToFunction(
      'artisans', 
      '/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}', 
      'GET'
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Artisan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load artisans by coordinates: ${response.body}');
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
    final response = await _functionsService.proxyToFunction('services', '/popular', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load popular services: ${response.body}');
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

    final response = await _functionsService.proxyToFunction(
      'artisans', 
      '/$userId/services', 
      'POST',
      body: serviceData
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

    final response = await _functionsService.proxyToFunction(
      'artisans', 
      '/$userId/services/$serviceId', 
      'PUT',
      body: serviceData
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

    final response = await _functionsService.proxyToFunction(
      'artisans', 
      '/$userId/services/$serviceId', 
      'DELETE'
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete service: ${response.body}');
    }
  }

  Future<void> generateAIPortfolio(String description) async {
    final response = await _functionsService.proxyToFunction(
      'ai', 
      '/generate-portfolio', 
      'POST',
      body: {'description': description}
    );

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Failed to generate AI portfolio';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to generate AI portfolio: ${response.body}');
      }
    }
  }
}
