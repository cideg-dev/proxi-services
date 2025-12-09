// frontend/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/token_manager.dart';

class ApiService {
  static final TokenManager _tokenManager = TokenManager();
  static const int _defaultTimeout = 30; // 30 secondes

  // Constructeur pour permettre l'instanciation dans les services
  ApiService();

  // Méthodes statiques pour maintenir la compatibilité
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._get(endpoint, headers: headers);
  }

  static Future<http.Response> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._post(endpoint, data, headers: headers);
  }

  static Future<http.Response> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._put(endpoint, data, headers: headers);
  }

  static Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._delete(endpoint, headers: headers);
  }

  static Future<http.Response> getPublic(String endpoint, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._getPublic(endpoint, headers: headers);
  }

  static Future<http.Response> postPublic(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._postPublic(endpoint, data, headers: headers);
  }

  static Future<http.Response> putPublic(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._putPublic(endpoint, data, headers: headers);
  }

  static Future<http.Response> deletePublic(String endpoint, {Map<String, String>? headers}) async {
    final instance = ApiService();
    return await instance._deletePublic(endpoint, headers: headers);
  }

  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static String extractErrorMessage(http.Response response) {
    try {
      final body = safeJsonDecode(response.body);
      return body['message'] ?? body['error'] ?? 'Erreur inconnue';
    } catch (e) {
      return 'Erreur de réseau ou de format de réponse';
    }
  }

  static Map<String, dynamic> safeJsonDecode(String responseBody) {
    try {
      // Vérifier si la réponse est vide
      if (responseBody.isEmpty) {
        return {
          'error': 'Empty response',
        };
      }

      final decoded = jsonDecode(responseBody);

      // Vérifier si le résultat est déjà un Map<String, dynamic>
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      // Si c'est une liste, envelopper dans un objet avec une clé de données
      else if (decoded is List) {
        return {
          'data': decoded,
        };
      }
      // Si c'est une valeur primitive, la convertir en objet
      else {
        return {
          'result': decoded,
        };
      }
    } catch (e) {
      // Si le décodage échoue, retourner un objet avec un message d'erreur
      return {
        'error': 'Invalid JSON response: ${e.toString()}',
        'raw_response': responseBody,
      };
    }
  }

  // Méthodes d'instance privées pour les services qui instancient ApiService
  Future<http.Response> _get(String endpoint, {Map<String, String>? headers}) async {
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

  Future<http.Response> _post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
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

  Future<http.Response> _put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
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

  Future<http.Response> _delete(String endpoint, {Map<String, String>? headers}) async {
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

  Future<http.Response> _getPublic(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        ...?headers,
      };

      final response = await http.get(url, headers: requestHeaders)
          .timeout(const Duration(seconds: _defaultTimeout));

      _logApiCall('GET_PUBLIC', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('GET_PUBLIC', endpoint, e);
      rethrow;
    }
  }

  Future<http.Response> _postPublic(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        ...?headers,
      };

      final response = await http.post(url, headers: requestHeaders, body: jsonEncode(data))
          .timeout(const Duration(seconds: _defaultTimeout));

      _logApiCall('POST_PUBLIC', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('POST_PUBLIC', endpoint, e);
      rethrow;
    }
  }

  Future<http.Response> _putPublic(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        ...?headers,
      };

      final response = await http.put(url, headers: requestHeaders, body: jsonEncode(data))
          .timeout(const Duration(seconds: _defaultTimeout));

      _logApiCall('PUT_PUBLIC', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('PUT_PUBLIC', endpoint, e);
      rethrow;
    }
  }

  Future<http.Response> _deletePublic(String endpoint, {Map<String, String>? headers}) async {
    try {
      final url = _buildUrl(endpoint);
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        ...?headers,
      };

      final response = await http.delete(url, headers: requestHeaders)
          .timeout(const Duration(seconds: _defaultTimeout));

      _logApiCall('DELETE_PUBLIC', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('DELETE_PUBLIC', endpoint, e);
      rethrow;
    }
  }

  // Méthode d'instance pour les services qui l'instancient
  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) {
    return _get(endpoint, headers: headers);
  }

  Future<http.Response> post(String endpoint, dynamic data, {Map<String, String>? headers}) {
    return _post(endpoint, data, headers: headers);
  }

  Future<http.Response> put(String endpoint, dynamic data, {Map<String, String>? headers}) {
    return _put(endpoint, data, headers: headers);
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? headers}) {
    return _delete(endpoint, headers: headers);
  }

  Future<http.Response> getPublic(String endpoint, {Map<String, String>? headers}) {
    return _getPublic(endpoint, headers: headers);
  }

  Future<http.Response> postPublic(String endpoint, dynamic data, {Map<String, String>? headers}) {
    return _postPublic(endpoint, data, headers: headers);
  }

  Future<http.Response> putPublic(String endpoint, dynamic data, {Map<String, String>? headers}) {
    return _putPublic(endpoint, data, headers: headers);
  }

  Future<http.Response> deletePublic(String endpoint, {Map<String, String>? headers}) {
    return _deletePublic(endpoint, headers: headers);
  }

  // Méthode privée pour effectuer la requête avec gestion du token
  Future<http.Response> _makeRequest(
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

    http.Response response;

    // Faire la requête initiale selon la méthode
    switch(method) {
      case 'GET':
        response = await http.get(url, headers: requestHeaders).timeout(const Duration(seconds: _defaultTimeout));
        break;
      case 'POST':
        response = await http.post(url, headers: requestHeaders, body: body).timeout(const Duration(seconds: _defaultTimeout));
        break;
      case 'PUT':
        response = await http.put(url, headers: requestHeaders, body: body).timeout(const Duration(seconds: _defaultTimeout));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: requestHeaders).timeout(const Duration(seconds: _defaultTimeout));
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }

    // Vérifier si la requête a échoué à cause d'un token expiré (401 Unauthorized)
    if (response.statusCode == 401) {
      final responseBody = safeJsonDecode(response.body);
      final errorMessage = responseBody['message'] ?? responseBody['error'] ?? '';

      // Si c'est une erreur de token expiré, essayer de le rafraîchir
      if (errorMessage.contains('expired') || errorMessage.contains('invalid') || errorMessage.contains('unable to parse')) {
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

          switch(method) {
            case 'GET':
              response = await http.get(url, headers: newRequestHeaders).timeout(const Duration(seconds: _defaultTimeout));
              break;
            case 'POST':
              response = await http.post(url, headers: newRequestHeaders, body: body).timeout(const Duration(seconds: _defaultTimeout));
              break;
            case 'PUT':
              response = await http.put(url, headers: newRequestHeaders, body: body).timeout(const Duration(seconds: _defaultTimeout));
              break;
            case 'DELETE':
              response = await http.delete(url, headers: newRequestHeaders).timeout(const Duration(seconds: _defaultTimeout));
              break;
            default:
              throw Exception('Méthode HTTP non supportée: $method');
          }
        }
      }
    }

    return response;
  }

  // Méthode pour rafraîchir le token
  Future<bool> _refreshToken() async {
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
  Future<bool> _refreshTokenWithLocalBackend(String refreshToken) async {
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
  Future<bool> _refreshTokenWithSupabase(String refreshToken) async {
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
  Uri _buildUrl(String endpoint) {
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

  // Méthode de journalisation des appels API
  void _logApiCall(String method, String endpoint, int statusCode) {
    // En production, on pourrait envoyer ces logs à un service d'analyse
    print('[API] $method $endpoint -> $statusCode');
  }

  // Méthode de journalisation des erreurs
  void _logError(String method, String endpoint, dynamic error) {
    print('[API-ERROR] $method $endpoint -> $error');
  }
}