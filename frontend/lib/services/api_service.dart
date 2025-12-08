// frontend/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/token_manager.dart';

class ApiService {
  static final TokenManager _tokenManager = TokenManager();
  static const int _defaultTimeout = 30; // 30 secondes

  // Méthode GET
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _makeRequest('GET', url, headers: headers);
      _logApiCall('GET', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('GET', endpoint, e);
      rethrow;
    }
  }

  // Méthode POST
  static Future<http.Response> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _makeRequest('POST', url, body: jsonEncode(data), headers: headers);
      _logApiCall('POST', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('POST', endpoint, e);
      rethrow;
    }
  }

  // Méthode PUT
  static Future<http.Response> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _makeRequest('PUT', url, body: jsonEncode(data), headers: headers);
      _logApiCall('PUT', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('PUT', endpoint, e);
      rethrow;
    }
  }

  // Méthode DELETE
  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _makeRequest('DELETE', url, headers: headers);
      _logApiCall('DELETE', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('DELETE', endpoint, e);
      rethrow;
    }
  }

  // Méthode privée pour effectuer la requête avec gestion du token
  static Future<http.Response> _makeRequest(
    String method,
    Uri url, {
    String? body,
    Map<String, String>? headers,
  }) async {
    // Obtenir le token et les headers
    final token = await _tokenManager.getToken();
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Proxi-Services Flutter App',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    // Faire la requête initiale
    http.Response response = await http.Request(method, url)
      .send(
        headers: requestHeaders,
        body: body,
      )
      .timeout(const Duration(seconds: _defaultTimeout))
      .then((streamedResponse) => http.Response.fromStream(streamedResponse));

    // Vérifier si la requête a échoué à cause d'un token expiré (401 Unauthorized)
    if (response.statusCode == 401) {
      final responseBody = safeJsonDecode(response.body);
      final errorMessage = responseBody['message'] ?? responseBody['error'] ?? '';

      // Si c'est une erreur de token expiré, essayer de le rafraîchir
      if (errorMessage.contains('expired') || errorMessage.contains('invalid') || errorMessage.contains('unable to parse') || response.statusCode == 401) {
        bool tokenRefreshed = await _refreshToken();
        if (tokenRefreshed) {
          // Réessayer la requête avec le nouveau token
          final newToken = await _tokenManager.getToken();
          final newRequestHeaders = <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'Proxi-Services Flutter App',
            if (newToken != null) 'Authorization': 'Bearer $newToken',
            ...?headers,
          };

          response = await http.Request(method, url)
            .send(
              headers: newRequestHeaders,
              body: body,
            )
            .timeout(const Duration(seconds: _defaultTimeout))
            .then((streamedResponse) => http.Response.fromStream(streamedResponse));
        }
      }
    }

    return response;
  }

  // Méthode pour rafraîchir le token
  static Future<bool> _refreshToken() async {
    try {
      // Récupérer le refresh token
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        // Si pas de refresh token, la session est complètement expirée
        return false;
      }

      // Déterminer si on utilise le backend local ou Supabase
      if (ApiConstants.useLocalBackend) {
        // Backend local - utiliser l'endpoint standard
        return await _refreshTokenWithLocalBackend(refreshToken);
      } else {
        // Supabase Functions - utiliser une fonction similaire
        return await _refreshTokenWithSupabase(refreshToken);
      }
    } catch (e) {
      _logError('_refreshToken', '/auth/refresh', e);
      return false;
    }
  }

  // Méthode pour rafraîchir le token avec le backend local
  static Future<bool> _refreshTokenWithLocalBackend(String refreshToken) async {
    try {
      final refreshTokenUrl = Uri.parse(ApiConstants.baseUrl + '/api/auth/refresh');
      final response = await http.post(
        refreshTokenUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(const Duration(seconds: _defaultTimeout));

      if (isSuccessful(response.statusCode)) {
        final data = safeJsonDecode(response.body);
        final newAccessToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null) {
          await _tokenManager.setToken(newAccessToken);
          if (newRefreshToken != null) {
            await _tokenManager.setRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
      
      // Si le rafraîchissement a échoué, déconnecter l'utilisateur
      await _tokenManager.clearToken();
      return false;
    } catch (e) {
      _logError('_refreshTokenWithLocalBackend', '/api/auth/refresh', e);
      return false;
    }
  }

  // Méthode pour rafraîchir le token avec Supabase Functions
  static Future<bool> _refreshTokenWithSupabase(String refreshToken) async {
    try {
      // Pour Supabase, nous pourrions avoir une fonction spécifique ou 
      // utiliser le service d'authentification Supabase directement
      // Pour l'instant, nous utiliserons une approche similaire
      final refreshTokenUrl = Uri.parse('${ApiConstants.supabaseBaseUrl}/refresh-token');
      
      final response = await http.post(
        refreshTokenUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(const Duration(seconds: _defaultTimeout));

      if (isSuccessful(response.statusCode)) {
        final data = safeJsonDecode(response.body);
        final newAccessToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null) {
          await _tokenManager.setToken(newAccessToken);
          if (newRefreshToken != null) {
            await _tokenManager.setRefreshToken(newRefreshToken);
          }
          return true;
        }
      }
      
      // Si le rafraîchissement a échoué, déconnecter l'utilisateur
      await _tokenManager.clearToken();
      return false;
    } catch (e) {
      _logError('_refreshTokenWithSupabase', '/refresh-token', e);
      return false;
    }
  }

  // Méthode pour construire l'URL complète
  static Uri _buildUrl(String endpoint) {
    // Si l'endpoint commence par http, c'est déjà une URL complète
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    
    // Pour les appels à des endpoints spécifiques à l'authentification
    // déterminer la bonne base URL
    String baseUrl = ApiConstants.baseUrl;
    
    // S'assurer que l'endpoint commence par / si ce n'est pas déjà le cas
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    
    return Uri.parse('$baseUrl$endpoint');
  }

  // Méthode pour extraire le corps JSON de manière sécurisée
  static Map<String, dynamic> safeJsonDecode(String responseBody) {
    try {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      // Si le décodage échoue, retourner un objet vide avec un message d'erreur
      return {
        'error': 'Invalid JSON response',
        'raw_response': responseBody,
      };
    }
  }

  // Méthode pour vérifier si la réponse est une erreur
  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  // Méthode pour extraire le message d'erreur d'une réponse
  static String extractErrorMessage(http.Response response) {
    try {
      final body = safeJsonDecode(response.body);
      return body['message'] ?? body['error'] ?? 'Erreur inconnue';
    } catch (e) {
      return 'Erreur de réseau ou de format de réponse';
    }
  }

  // Méthode de journalisation des appels API
  static void _logApiCall(String method, String endpoint, int statusCode) {
    // En production, on pourrait envoyer ces logs à un service d'analyse
    print('[API] $method $endpoint -> $statusCode');
  }

  // Méthode de journalisation des erreurs
  static void _logError(String method, String endpoint, dynamic error) {
    print('[API-ERROR] $method $endpoint -> $error');
  }
}