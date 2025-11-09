import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class SocialSharingService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Générer un lien de partage pour un service/artisan
  Future<Map<String, dynamic>> generateShareableLink({
    required String contentType, // 'service', 'artisan', 'merchant', 'review', etc.
    required int contentId,
    String? customMessage,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/shareable-link',
      body: {
        'userId': userId,
        'contentType': contentType,
        'contentId': contentId,
        if (customMessage != null) 'customMessage': customMessage,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la génération du lien de partage: ${response.body}');
    }
  }

  // Partager du contenu sur un réseau social spécifique
  Future<Map<String, dynamic>> shareToSocialPlatform({
    required String platform, // 'facebook', 'twitter', 'instagram', 'whatsapp', etc.
    required String link,
    String? message,
    String? imageUrl,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/share',
      body: {
        'userId': userId,
        'platform': platform,
        'link': link,
        if (message != null) 'message': message,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du partage sur le réseau social: ${response.body}');
    }
  }

  // Obtenir les options de partage disponibles
  Future<List<dynamic>> getAvailableSharingOptions() async {
    final response = await _apiService.get('/api/social/sharing-options');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des options de partage: ${response.body}');
    }
  }

  // Enregistrer une action de partage
  Future<void> recordShareAction({
    required String platform,
    required String contentType,
    required int contentId,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/record-share',
      body: {
        'userId': userId,
        'platform': platform,
        'contentType': contentType,
        'contentId': contentId,
      }
    );
    
    if (response.statusCode != 200) {
      throw Exception('Échec de l\'enregistrement de l\'action de partage: ${response.body}');
    }
  }

  // Obtenir les contenus partagés par l'utilisateur
  Future<List<dynamic>> getSharedContent() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/social/shared-content/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des contenus partagés: ${response.body}');
    }
  }

  // Obtenir les contenus populaires sur les réseaux sociaux
  Future<List<dynamic>> getSociallyPopularContent({
    String? category,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('/api/social/popular-content').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des contenus populaires: ${response.body}');
    }
  }

  // Vérifier les connexions aux réseaux sociaux de l'utilisateur
  Future<Map<String, dynamic>> getSocialConnections() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/social/connections/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des connexions sociales: ${response.body}');
    }
  }

  // Lier un compte de réseau social
  Future<Map<String, dynamic>> linkSocialAccount({
    required String platform,
    required String accessToken,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/link-account',
      body: {
        'userId': userId,
        'platform': platform,
        'accessToken': accessToken,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la liaison du compte social: ${response.body}');
    }
  }

  // Délier un compte de réseau social
  Future<void> unlinkSocialAccount(String platform) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/unlink-account',
      body: {
        'userId': userId,
        'platform': platform,
      }
    );
    
    if (response.statusCode != 200) {
      throw Exception('Échec du déliement du compte social: ${response.body}');
    }
  }

  // Obtenir des suggestions de contenus à partager
  Future<List<dynamic>> getShareSuggestions() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/social/share-suggestions/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des suggestions de partage: ${response.body}');
    }
  }

  // Créer un post sponsorisé
  Future<Map<String, dynamic>> createSponsoredPost({
    required String platform,
    required String content,
    String? imageUrl,
    DateTime? scheduledTime,
    int? budget,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/social/sponsored-post',
      body: {
        'userId': userId,
        'platform': platform,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (scheduledTime != null) 'scheduledTime': scheduledTime.toIso8601String(),
        if (budget != null) 'budget': budget,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création du post sponsorisé: ${response.body}');
    }
  }
}