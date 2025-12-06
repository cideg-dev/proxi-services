import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';

class MerchantService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getMerchants() async {
    final response = await _functionsService.getArtisans(); // Assuming merchants are also artisans/professionals
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchants');
    }
  }

  Future<Map<String, dynamic>> getMerchantById(int id) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$id', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchant');
    }
  }

  Future<List<dynamic>> getMerchantProducts(int merchantId) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$merchantId/portfolio', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchant products');
    }
  }

  Future<List<dynamic>> getMerchantReviews(int merchantId) async {
    final response = await _functionsService.getArtisanReviews(merchantId);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<double> getMerchantAverageRating(int merchantId) async {
    final response = await _functionsService.proxyToFunction('artisans', '/$merchantId/rating', 'GET');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to load average rating');
    }
  }

  Future<List<dynamic>> getNearbyMerchants(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await _functionsService.proxyToFunction(
      'artisans', 
      '/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}', 
      'GET'
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load nearby merchants: ${response.body}');
    }
  }

  Future<List<dynamic>> getFeaturedMerchants() async {
    final response = await _functionsService.getFeaturedProfessionals();
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load featured merchants: ${response.body}');
    }
  }

  Future<List<dynamic>> getMerchantByCategory(String category) async {
    final response = await _functionsService.proxyToFunction('artisans', '/category/$category', 'GET');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchants by category: ${response.body}');
    }
  }
}