import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class LoyaltyService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir les points de fidélité de l'utilisateur
  Future<Map<String, dynamic>> getLoyaltyPoints() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/points/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des points de fidélité: ${response.body}');
    }
  }

  // Obtenir l'historique des points de fidélité
  Future<List<dynamic>> getLoyaltyHistory() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/history/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique: ${response.body}');
    }
  }

  // Obtenir les récompenses disponibles
  Future<List<dynamic>> getAvailableRewards() async {
    final response = await _apiService.getPublic('/api/loyalty/rewards');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des récompenses: ${response.body}');
    }
  }

  // Échanger des points contre une récompense
  Future<Map<String, dynamic>> redeemReward({
    required String rewardId,
    required int pointsRequired,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/loyalty/redeem',
      body: {
        'userId': userId,
        'rewardId': rewardId,
        'pointsRequired': pointsRequired,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'échange de récompense: ${response.body}');
    }
  }

  // Obtenir les niveaux de fidélité
  Future<List<dynamic>> getLoyaltyTiers() async {
    final response = await _apiService.getPublic('/api/loyalty/tiers');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des niveaux: ${response.body}');
    }
  }

  // Obtenir le niveau actuel de l'utilisateur
  Future<Map<String, dynamic>> getUserLoyaltyTier() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/tier/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du niveau de fidélité: ${response.body}');
    }
  }

  // Obtenir les avantages pour un niveau spécifique
  Future<List<dynamic>> getTierBenefits(String tierId) async {
    final response = await _apiService.get('/api/loyalty/tiers/$tierId/benefits');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des avantages: ${response.body}');
    }
  }

  // Vérifier si un utilisateur peut monter de niveau
  Future<Map<String, dynamic>> canUpgradeTier() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/upgrade-eligibility/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification de l\'éligibilité: ${response.body}');
    }
  }

  // Obtenir les défis de fidélité en cours
  Future<List<dynamic>> getCurrentChallenges() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/challenges/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des défis: ${response.body}');
    }
  }

  // Réclamer une récompense pour un défi terminé
  Future<Map<String, dynamic>> claimChallengeReward(String challengeId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/loyalty/challenges/$challengeId/claim',
      body: {'userId': userId}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la réclamation de la récompense: ${response.body}');
    }
  }

  // Obtenir les bonus spéciaux (événements, saisons, etc.)
  Future<List<dynamic>> getSpecialBonuses() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/loyalty/special-bonuses/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des bonus spéciaux: ${response.body}');
    }
  }
}