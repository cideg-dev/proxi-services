import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Hasher un mot de passe
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Générer un salt
  String generateSalt() {
    final randomBytes = List.generate(
      16,
      (index) => DateTime.now().millisecondsSinceEpoch % 256,
    );
    return base64Encode(randomBytes);
  }

  // Valider un token JWT
  bool isTokenValid(String token) {
    try {
      // Vérifier la structure du token
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // Décoder l'en-tête et le payload
      final header = jsonDecode(utf8.decode(base64Decode(parts[0])));
      final payload = jsonDecode(utf8.decode(base64Decode(parts[1] + '=' * (4 - parts[1].length % 4))));
      
      // Vérifier l'expiration
      final exp = payload['exp'] as int?;
      if (exp != null && DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000))) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la validation du token: $e');
      return false;
    }
  }

  // Vérifier si les données d'entrée sont valides
  bool validateInput(String input, {bool allowHtml = false, int maxLength = 1000}) {
    if (input.length > maxLength) return false;
    
    if (!allowHtml && input.contains(RegExp(r'<[^>]*>'))) {
      return false; // Contient des balises HTML
    }
    
    // Vérifier les caractères dangereux
    final dangerousChars = ['<script', 'javascript:', 'vbscript:', 'onerror', 'onload'];
    for (final char in dangerousChars) {
      if (input.toLowerCase().contains(char)) {
        return false;
      }
    }
    
    return true;
  }

  // Nettoyer les données d'entrée
  String sanitizeInput(String input) {
    // Retirer les balises HTML
    input = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Échapper les caractères spéciaux
    input = input.replaceAll('&', '&amp;')
                 .replaceAll('<', '&lt;')
                 .replaceAll('>', '&gt;')
                 .replaceAll('"', '&quot;')
                 .replaceAll("'", '&#x27;');
    
    return input;
  }

  // Vérifier les permissions
  Future<bool> hasPermission(String permission) async {
    final token = await _tokenManager.getToken();
    if (token == null) return false;
    
    // Ici, vous pouvez vérifier les permissions dans le token
    // ou faire un appel API pour vérifier les permissions
    try {
      final response = await _apiService.get('/api/users/permissions');
      if (response.statusCode == 200) {
        final permissions = jsonDecode(response.body)['permissions'] as List<dynamic>;
        return permissions.contains(permission);
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  // Vérifier le taux de requêtes (rate limiting)
  Future<bool> isRateLimited(String identifier, int maxRequests, Duration timeWindow) async {
    // Cette implémentation est simplifiée
    // En production, vous voudriez utiliser une base de données ou Redis
    // pour stocker les compteurs de requêtes
    return false; // Pour l'instant, on suppose que ce n'est pas limité
  }

  // Chiffrer des données sensibles
  String encryptData(String data) {
    // Implémentation simplifiée
    // En production, utilisez une bibliothèque de chiffrement robuste
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Méthode pour le journal des événements de sécurité
  Future<void> logSecurityEvent({
    required String eventType,
    required String userId,
    String? details,
    String? ipAddress,
  }) async {
    try {
      await _apiService.post('/api/security/log', 
        body: {
          'eventType': eventType,
          'userId': userId,
          'details': details ?? '',
          'ipAddress': ipAddress ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        }
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'événement de sécurité: $e');
    }
  }

  // Vérifier si une adresse IP est dans la liste noire
  Future<bool> isIpBlacklisted(String ipAddress) async {
    try {
      final response = await _apiService.get('/api/security/blacklist/$ipAddress');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isBlacklisted'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de la liste noire: $e');
      return false;
    }
  }
}