// frontend/lib/services/supabase_functions_service.dart (mis à jour avec gestion CORS)
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

    // Pour les requêtes depuis GitHub Pages, nous devons gérer CORS différemment
    // En attendant que les fonctions soient correctement configurées pour CORS
    // Utilisons une requête avec tous les headers nécessaires
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
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
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
      body: body,
    );

    return response;
  }

  // Méthode pour récupérer les artisans
  Future<http.Response> getArtisans() async {
    final url = Uri.parse(ApiConstants.artisansUrl);
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
    );

    return response;
  }

  // Méthode pour les professionnels mis en avant
  Future<http.Response> getFeaturedProfessionals() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/professionals');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
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
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
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
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
    );

    return response;
  }
}