import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ReviewService {
  final TokenManager _tokenManager = TokenManager();

  // Ajouter un avis pour un artisan
  Future<Map<String, dynamic>> addArtisanReview(int artisanId, int rating, String comment) async {
    final response = await ApiService.post('/api/artisans/$artisanId/reviews',
      {
        'rating': rating,
        'comment': comment,
      },
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec de l\'ajout de l\'avis: $errorMessage');
    }
  }

  // Ajouter un avis pour un commerçant
  Future<Map<String, dynamic>> addMerchantReview(int merchantId, int rating, String comment) async {
    final response = await ApiService.post('/api/artisans/$merchantId/reviews',
      {
        'rating': rating,
        'comment': comment,
      },
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec de l\'ajout de l\'avis: $errorMessage');
    }
  }

  // Récupérer les avis d'un artisan
  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await ApiService.getPublic('/api/artisans/$artisanId/reviews');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement des avis: $errorMessage');
    }
  }

  // Récupérer les avis d'un commerçant
  Future<List<dynamic>> getMerchantReviews(int merchantId) async {
    final response = await ApiService.getPublic('/api/artisans/$merchantId/reviews');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement des avis: $errorMessage');
    }
  }

  // Récupérer la moyenne des notes d'un artisan
  Future<double> getArtisanAverageRating(int artisanId) async {
    final response = await ApiService.getPublic('/api/artisans/$artisanId/rating');
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement de la note moyenne: $errorMessage');
    }
  }

  // Récupérer la moyenne des notes d'un commerçant
  Future<double> getMerchantAverageRating(int merchantId) async {
    final response = await ApiService.getPublic('/api/artisans/$merchantId/rating');
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = jsonDecode(response.body);
      return (data['average_rating'] as num?)?.toDouble() ?? 0.0;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement de la note moyenne: $errorMessage');
    }
  }

  // Récupérer les avis de l'utilisateur connecté
  Future<List<dynamic>> getMyReviews() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await ApiService.get('/api/users/$userId/reviews');
    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec du chargement de mes avis: $errorMessage');
    }
  }

  // Mettre à jour un avis existant
  Future<Map<String, dynamic>> updateReview(int reviewId, int rating, String comment) async {
    final response = await ApiService.put('/api/reviews/$reviewId',
      {
        'rating': rating,
        'comment': comment,
      },
    );

    if (ApiService.isSuccessful(response.statusCode)) {
      return jsonDecode(response.body);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec de la mise à jour de l\'avis: $errorMessage');
    }
  }

  // Supprimer un avis
  Future<void> deleteReview(int reviewId) async {
    final response = await ApiService.delete('/api/reviews/$reviewId');

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception('Échec de la suppression de l\'avis: $errorMessage');
    }
  }
}