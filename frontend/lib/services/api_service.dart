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
      final token = await _tokenManager.getToken();
      
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      final response = await http.get(
        url,
        headers: requestHeaders,
      ).timeout(const Duration(seconds: _defaultTimeout));

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
      final token = await _tokenManager.getToken();
      
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      final response = await http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: _defaultTimeout));

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
      final token = await _tokenManager.getToken();
      
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      final response = await http.put(
        url,
        headers: requestHeaders,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: _defaultTimeout));

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
      final token = await _tokenManager.getToken();
      
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Proxi-Services Flutter App',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?headers,
      };

      final response = await http.delete(
        url,
        headers: requestHeaders,
      ).timeout(const Duration(seconds: _defaultTimeout));

      _logApiCall('DELETE', endpoint, response.statusCode);
      return response;
    } catch (e) {
      _logError('DELETE', endpoint, e);
      rethrow;
    }
  }

  // Méthode pour construire l'URL complète
  static Uri _buildUrl(String endpoint) {
    // Si l'endpoint commence par http, c'est déjà une URL complète
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    
    // Sinon, construire l'URL à partir de la base
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