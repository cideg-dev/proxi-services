// frontend/lib/services/supabase_functions_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/token_manager.dart';

class SupabaseFunctionsService {
  final TokenManager _tokenManager = TokenManager();

  // Méthode pour l'inscription
  Future<http.Response> signup({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  }) async {
    final url = Uri.parse(ApiConstants.signupUrl);
    
    final body = jsonEncode({
      'email': email,
      'password': password,
      'role': role,
      'profileData': profileData ?? {},
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response;
  }

  // Méthode pour la connexion
  Future<http.Response> signin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.signinUrl);
    
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response;
  }

  // Méthode pour récupérer les artisans
  Future<http.Response> getArtisans() async {
    final url = Uri.parse(ApiConstants.artisansUrl);
    
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  // Méthode pour ajouter un avis
  Future<http.Response> addReview({
    required int artisanId,
    required int rating,
    required String comment,
  }) async {
    final token = await _tokenManager.getToken();
    
    final url = Uri.parse(ApiConstants.reviewsUrl);
    
    final body = jsonEncode({
      'artisanId': artisanId,
      'rating': rating,
      'comment': comment,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    return response;
  }

  // Méthode pour récupérer les avis d'un artisan
  Future<http.Response> getArtisanReviews(int artisanId) async {
    final url = Uri.parse('${ApiConstants.reviewsUrl}?artisan_id=$artisanId');
    
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }
}