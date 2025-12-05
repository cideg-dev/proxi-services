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
      } else if (method == 'POST' && endpoint.contains('/portfolio')) {
        // Gérer les requêtes pour le portfolio
        // Pourrait nécessiter une implémentation spécifique selon les besoins
      } else if (method == 'POST' && endpoint.contains('/services')) {
        // Gérer les requêtes pour les services des artisans
        // Pourrait nécessiter une implémentation spécifique selon les besoins
      }
      // Autres méthodes pour artisans selon les besoins
    } else if (endpoint.contains('/api/professionals/featured')) {
      if (method == 'GET') {
        return _functionsService.getFeaturedProfessionals();
      }
    } else if (endpoint.contains('/api/auth/logout')) {
      if (method == 'POST') {
        // Pour la déconnexion, il suffit de supprimer le token côté client
        // La fonction Supabase de déconnexion est gérée ailleurs
        // Retournons une réponse vide mais réussie
        return http.Response('{"success": true}', 200, headers: {'content-type': 'application/json'});
      }
    } else if (endpoint.contains('/api/profile')) {
      if (method == 'GET') {
        // Retourner les informations du profil utilisateur
        return _functionsService.getUserProfile();
      } else if (method == 'PUT') {
        // Mettre à jour le profil utilisateur
        return _functionsService.updateUserProfile(body!);
      }
    } else if (endpoint.startsWith('/conversations')) {
       // Rediriger vers la fonction conversations
       // On passe l'endpoint complet car il peut contenir des ID ou des sous-chemins
       return _functionsService.proxyToFunction('conversations', endpoint, method, body: body);
    } else if (endpoint.contains('/api/auth/change-password')) {
      if (method == 'POST') {
        // Gérer le changement de mot de passe
        // Pour l'instant, retournons un succès
        return http.Response('{"success": true}', 200, headers: {'content-type': 'application/json'});
      }
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
    } else if (endpoint.contains('/api/professionals/featured')) {
      return _functionsService.getFeaturedProfessionals();
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