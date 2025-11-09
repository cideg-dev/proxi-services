import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class BadgeService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir tous les badges disponibles
  Future<List<dynamic>> getAllBadges() async {
    final response = await _apiService.getPublic('/api/badges');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des badges: ${response.body}');
    }
  }

  // Obtenir les badges d'un utilisateur
  Future<List<dynamic>> getUserBadges(int userId) async {
    final response = await _apiService.get('/api/badges/user/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des badges de l\'utilisateur: ${response.body}');
    }
  }

  // Obtenir les badges de l'utilisateur connecté
  Future<List<dynamic>> getMyBadges() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    return await getUserBadges(userId);
  }

  // Attribuer un badge à un utilisateur (fonctionnalité admin/modérateur)
  Future<Map<String, dynamic>> awardBadge({
    required int userId,
    required String badgeId,
    String? reason,
  }) async {
    final response = await _apiService.post('/api/badges/award',
      body: {
        'userId': userId,
        'badgeId': badgeId,
        if (reason != null) 'reason': reason,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'attribution du badge: ${response.body}');
    }
  }

  // Obtenir les critères pour un badge spécifique
  Future<Map<String, dynamic>> getBadgeCriteria(String badgeId) async {
    final response = await _apiService.get('/api/badges/$badgeId/criteria');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des critères du badge: ${response.body}');
    }
  }

  // Vérifier si un utilisateur mérite un badge
  Future<Map<String, dynamic>> checkBadgeEligibility({
    required int userId,
    required String badgeId,
  }) async {
    final response = await _apiService.post('/api/badges/check-eligibility',
      body: {
        'userId': userId,
        'badgeId': badgeId,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification d\'éligibilité: ${response.body}');
    }
  }

  // Obtenir les badges récemment décernés
  Future<List<dynamic>> getRecentAwards() async {
    final response = await _apiService.get('/api/badges/recent-awards');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des récents décernés: ${response.body}');
    }
  }

  // Créer un nouveau badge (fonctionnalité admin)
  Future<Map<String, dynamic>> createBadge({
    required String name,
    required String description,
    required String icon,
    required int points,
    required Map<String, dynamic> criteria,
    bool active = true,
  }) async {
    final response = await _apiService.post('/api/badges',
      body: {
        'name': name,
        'description': description,
        'icon': icon,
        'points': points,
        'criteria': criteria,
        'active': active,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création du badge: ${response.body}');
    }
  }

  // Mettre à jour un badge existant (fonctionnalité admin)
  Future<Map<String, dynamic>> updateBadge({
    required String badgeId,
    String? name,
    String? description,
    String? icon,
    int? points,
    Map<String, dynamic>? criteria,
    bool? active,
  }) async {
    final response = await _apiService.put('/api/badges/$badgeId',
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (points != null) 'points': points,
        if (criteria != null) 'criteria': criteria,
        if (active != null) 'active': active,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour du badge: ${response.body}');
    }
  }

  // Déduire un badge (fonctionnalité admin/modérateur)
  Future<void> revokeBadge({
    required int userId,
    required String badgeId,
    String? reason,
  }) async {
    final response = await _apiService.post('/api/badges/revoke',
      body: {
        'userId': userId,
        'badgeId': badgeId,
        if (reason != null) 'reason': reason,
      }
    );
    
    if (response.statusCode != 200) {
      throw Exception('Échec du retrait du badge: ${response.body}');
    }
  }
}