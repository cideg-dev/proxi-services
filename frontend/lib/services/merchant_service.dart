import 'dart:convert';
import 'package:frontend/services/redirect_api_service.dart';
import 'package:frontend/services/token_manager.dart';

class MerchantService {
  final RedirectApiService _apiService = RedirectApiService();
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getMerchants() async {
    final response = await _apiService.getPublic('/api/artisans');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchants');
    }
  }

  Future<Map<String, dynamic>> getMerchantById(int id) async {
    final response = await _apiService.getPublic('/api/artisans/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchant');
    }
  }

  Future<List<dynamic>> getMerchantProducts(int merchantId) async {
    final response = await _apiService.getPublic('/api/artisans/$merchantId/portfolio');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchant products');
    }
  }

  Future<List<dynamic>> getMerchantReviews(int merchantId) async {
    final response = await _apiService.getPublic('/api/artisans/$merchantId/reviews');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  // NEW: Get average rating for a merchant
  Future<double> getMerchantAverageRating(int merchantId) async {
    final response = await _apiService.getPublic('/api/artisans/$merchantId/rating');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to load average rating');
    }
  }

  Future<List<dynamic>> getNearbyMerchants(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await _apiService.getPublic(
      '/api/artisans/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}'
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load nearby merchants: ${response.body}');
    }
  }

  Future<List<dynamic>> getFeaturedMerchants() async {
    final response = await _apiService.getPublic('/api/professionals/featured');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load featured merchants: ${response.body}');
    }
  }

  Future<List<dynamic>> getMerchantByCategory(String category) async {
    final response = await _apiService.getPublic('/api/artisans/category/$category');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load merchants by category: ${response.body}');
    }
  }
}