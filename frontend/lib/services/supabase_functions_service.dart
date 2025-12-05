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

  // Méthode pour récupérer le profil utilisateur
  Future<http.Response> getUserProfile() async {
    final token = await _tokenManager.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/profile'); // ou un endpoint spécifique

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
    );

    return response;
  }

  // Méthode pour mettre à jour le profil utilisateur
  Future<http.Response> updateUserProfile(Map<String, dynamic> profileData) async {
    final token = await _tokenManager.getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/profile'); // ou un endpoint spécifique

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
      },
      body: jsonEncode(profileData),
    );

    return response;
  }

  // Méthode générique pour proxy vers une fonction Supabase
  Future<http.Response> proxyToFunction(String functionName, String path, String method, {Map<String, dynamic>? body}) async {
    final token = await _tokenManager.getToken();
    // Construit l'URL de la fonction. 
    // Si path est "/conversations/123", et functionName est "conversations",
    // on veut probablement appeler ".../functions/v1/conversations/123"
    // Mais attention, si path est "/conversations", on veut ".../functions/v1/conversations"
    
    // Nettoyer le path pour qu'il soit relatif à la fonction si besoin, 
    // ou simplement utiliser le nom de la fonction comme base.
    // Supposons que ApiConstants.baseUrl pointe vers ".../functions/v1"
    
    // Si le path commence par le nom de la fonction, on l'utilise tel quel après le baseUrl
    // Sinon on l'ajoute.
    
    String relativePath = path;
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }
    
    final url = Uri.parse('${ApiConstants.baseUrl}/$relativePath');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp)',
    };

    if (method == 'GET') {
      return http.get(url, headers: headers);
    } else if (method == 'POST') {
      return http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'PUT') {
      return http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'DELETE') {
      return http.delete(url, headers: headers);
    } else {
      throw Exception('Method not supported: $method');
    }
  }
}