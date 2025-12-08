import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class MerchantService {
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getMerchants() async {
    final response = await ApiService.get('/artisans'); // Assuming merchants are also artisans/professionals
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load merchants: $errorMessage');
    }
  }

  Future<Map<String, dynamic>> getMerchantById(int id) async {
    final response = await ApiService.get('/artisans/$id');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load merchant: $errorMessage');
    }
  }

  Future<List<dynamic>> getMerchantProducts(int merchantId) async {
    final response = await ApiService.get('/artisans/$merchantId/portfolio');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load merchant products: $errorMessage');
    }
  }

  Future<List<dynamic>> getMerchantReviews(int merchantId) async {
    final response = await ApiService.get('/reviews?artisanId=$merchantId');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load reviews: $errorMessage');
    }
  }

  Future<double> getMerchantAverageRating(int merchantId) async {
    final response = await ApiService.get('/artisans/$merchantId/rating');
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load average rating: $errorMessage');
    }
  }

  Future<List<dynamic>> getNearbyMerchants(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await ApiService.get('/artisans/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load nearby merchants: $errorMessage');
    }
  }

  Future<List<dynamic>> getFeaturedMerchants() async {
    final response = await ApiService.getPublic('/artisans/featured');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load featured merchants: $errorMessage');
    }
  }

  Future<List<dynamic>> getMerchantByCategory(String category) async {
    final response = await ApiService.get('/artisans/category/$category');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Failed to load merchants by category: $errorMessage');
    }
  }
}