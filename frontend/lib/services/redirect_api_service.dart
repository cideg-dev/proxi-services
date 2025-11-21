// frontend/lib/services/redirect_api_service.dart
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;

class RedirectApiService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  // Méthode pour gérer les requêtes authentifiées
  Future<http.Response> _handleRequest(String endpoint, Map<String, dynamic>? body, String method) async {
    final token = await _tokenManager.getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    // Ici, nous redirigeons vers les fonctions Supabase appropriées
    // selon l'endpoint demandé
    if (endpoint.startsWith('/api/artisans')) {
      if (method == 'GET') {
        // Convertir /api/artisans vers la fonction artisans
        return _functionsService.getArtisans();
      }
      // Autres méthodes pour artisans selon les besoins
    }
    
    // Pour les autres endpoints, il faudra ajouter des redirections spécifiques
    throw Exception('Endpoint non pris en charge: $endpoint');
  }

  Future<http.Response> get(String endpoint) {
    return _handleRequest(endpoint, null, 'GET');
  }

  Future<http.Response> post(String endpoint, {Object? body}) {
    return _handleRequest(endpoint, body as Map<String, dynamic>?, 'POST');
  }

  Future<http.Response> put(String endpoint, {Object? body}) {
    return _handleRequest(endpoint, body as Map<String, dynamic>?, 'PUT');
  }

  Future<http.Response> delete(String endpoint) {
    return _handleRequest(endpoint, null, 'DELETE');
  }

  // Méthodes pour les requêtes non authentifiées
  Future<http.Response> getPublic(String endpoint) async {
    // Gestion spécifique pour les endpoints publics
    if (endpoint.contains('/api/artisans')) {
      if (endpoint == '/api/artisans') {
        return _functionsService.getArtisans();
      }
      // Traitement pour les sous-endpoints artisans
    } else if (endpoint.contains('/api/auth/login')) {
      // Cette requête ne devrait pas être public
      throw Exception('La connexion requiert une authentification');
    } else if (endpoint.contains('/api/auth/register')) {
      // Cette requête ne devrait pas non plus être publique
      throw Exception('L\'inscription requiert une authentification spécifique');
    }
    
    throw Exception('Endpoint public non géré: $endpoint');
  }

  Future<http.Response> postPublic(String endpoint, {Object? body}) async {
    // Gestion spécifique pour les endpoints publics POST
    if (endpoint.contains('/api/auth/register')) {
      final Map<String, dynamic> bodyData = body as Map<String, dynamic>;
      return _functionsService.signup(
        email: bodyData['email'] as String,
        password: bodyData['password'] as String,
        role: bodyData['role'] as String,
        profileData: bodyData['profileData'] as Map<String, dynamic>?,
      );
    } else if (endpoint.contains('/api/auth/login')) {
      final Map<String, dynamic> bodyData = body as Map<String, dynamic>;
      return _functionsService.signin(
        email: bodyData['email'] as String,
        password: bodyData['password'] as String,
      );
    }
    
    throw Exception('Endpoint public POST non géré: $endpoint');
  }

  // Méthode pour les requêtes multipart
  Future<http.StreamedResponse> multipartRequest(String method, String endpoint, {Map<String, String>? fields, List<http.MultipartFile>? files}) {
    throw Exception('Multipart requests not implemented yet');
  }
}