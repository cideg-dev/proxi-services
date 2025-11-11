import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ReviewService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Ajouter un avis pour un artisan
  Future<Map<String, dynamic>> addArtisanReview(int artisanId, int rating, String comment) async {
    final response = await _apiService.post('/api/artisans/$artisanId/reviews', 
      body: {
        'rating': rating,
        'comment': comment,
      },
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'ajout de l\'avis: ${response.body}');
    }
  }

  // Ajouter un avis pour un commerçant
  Future<Map<String, dynamic>> addMerchantReview(int merchantId, int rating, String comment) async {
    final response = await _apiService.post('/api/artisans/$merchantId/reviews', 
      body: {
        'rating': rating,
        'comment': comment,
      },
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'ajout de l\'avis: ${response.body}');
    }
  }

  // Récupérer les avis d'un artisan
  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/reviews');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des avis: ${response.body}');
    }
  }

  // Récupérer les avis d'un commerçant
  Future<List<dynamic>> getMerchantReviews(int merchantId) async {
    final response = await _apiService.getPublic('/api/artisans/$merchantId/reviews');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des avis: ${response.body}');
    }
  }

  // Récupérer la moyenne des notes d'un artisan
  Future<double> getArtisanAverageRating(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/rating');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Échec du chargement de la note moyenne: ${response.body}');
    }
  }

  // Récupérer la moyenne des notes d'un commerçant
  Future<double> getMerchantAverageRating(int merchantId) async {
    final response = await _apiService.getPublic('/api/artisans/$merchantId/rating');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Échec du chargement de la note moyenne: ${response.body}');
    }
  }

  // Récupérer les avis de l'utilisateur connecté
  Future<List<dynamic>> getMyReviews() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }
    
    final response = await _apiService.get('/api/users/$userId/reviews');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de mes avis: ${response.body}');
    }
  }

  // Mettre à jour un avis existant
  Future<Map<String, dynamic>> updateReview(int reviewId, int rating, String comment) async {
    final response = await _apiService.put('/api/reviews/$reviewId', 
      body: {
        'rating': rating,
        'comment': comment,
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour de l\'avis: ${response.body}');
    }
  }

  // Supprimer un avis
  Future<void> deleteReview(int reviewId) async {
    final response = await _apiService.delete('/api/reviews/$reviewId');
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Échec de la suppression de l\'avis: ${response.body}');
    }
  }
}