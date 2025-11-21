// frontend/lib/services/compatibility_api_service.dart
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;

class CompatibilityApiService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  // Méthode pour gérer les requêtes authentifiées
  Future<http.Response> _handleRequest(Future<http.Response> Function(Map<String, String> headers) request) async {
    final token = await _tokenManager.getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // Note: Avec Supabase Functions, l'authentification se fait différemment
    // Nous devons adapter cela à la solution de correspondance
    final response = await request(headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      _handleAuthError();
      throw Exception('Authentication Error');
    }
    return response;
  }

  // Méthodes pour remplacer les anciennes méthodes d'ApiService
  Future<http.Response> get(String endpoint) async {
    // Convertir les anciens endpoints vers les nouvelles fonctions Supabase
    if (endpoint.startsWith('/api/artisans')) {
      // Pour /api/artisans ou /api/artisans/:id ou /api/artisans/:id/reviews
      if (endpoint.contains('/reviews')) {
        // Pour les avis, extraire l'ID de l'artisan
        final regex = RegExp(r'/api/artisans/(\d+)/reviews');
        final match = regex.firstMatch(endpoint);
        if (match != null) {
          final artisanId = int.parse(match.group(1)!);
          return _functionsService.getArtisanReviews(artisanId);
        }
      } else if (endpoint.contains(RegExp(r'/api/artisans/\d+'))) {
        // Pour un artisan spécifique
        // Cette opération nécessite une logique spécifique
        final response = await _functionsService.getArtisans();
        // Traitement pour retourner l'artisan spécifique
        return response;
      } else {
        // Pour /api/artisans - liste des artisans
        return _functionsService.getArtisans();
      }
    }
    
    // Pour d'autres endpoints, il faudra implémenter les conversions spécifiques
    throw Exception('Endpoint not yet implemented: $endpoint');
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    if (endpoint.startsWith('/api/auth/login')) {
      // Convertir l'appel de connexion
      final Map<String, dynamic> bodyData = body as Map<String, dynamic>;
      final response = await _functionsService.signin(
        email: bodyData['email'] as String,
        password: bodyData['password'] as String,
      );
      return response;
    } else if (endpoint.startsWith('/api/auth/register')) {
      // Convertir l'appel d'inscription
      final Map<String, dynamic> bodyData = body as Map<String, dynamic>;
      final response = await _functionsService.signup(
        email: bodyData['email'] as String,
        password: bodyData['password'] as String,
        role: bodyData['role'] as String,
        profileData: bodyData['profileData'] as Map<String, dynamic>?,
      );
      return response;
    }
    
    throw Exception('Endpoint not yet implemented: $endpoint');
  }

  Future<http.Response> put(String endpoint, {Object? body}) async {
    throw Exception('PUT endpoint not yet implemented: $endpoint');
  }

  Future<http.Response> delete(String endpoint) async {
    throw Exception('DELETE endpoint not yet implemented: $endpoint');
  }

  // Méthodes non authentifiées
  Future<http.Response> getPublic(String endpoint) async {
    return get(endpoint);
  }

  Future<http.Response> postPublic(String endpoint, {Object? body}) async {
    return post(endpoint, body: body);
  }

  void _handleAuthError() async {
    await _tokenManager.clearToken();
    // Gérer la redirection vers l'écran de connexion
  }

  // Méthode pour les requêtes multipart
  Future<http.StreamedResponse> multipartRequest(String method, String endpoint, {Map<String, String>? fields, List<http.MultipartFile>? files}) async {
    throw Exception('Multipart requests not yet implemented for Supabase functions');
  }
}