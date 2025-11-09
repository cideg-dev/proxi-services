import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ReferralService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir le code de parrainage de l'utilisateur
  Future<Map<String, dynamic>> getReferralCode() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/code/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du code de parrainage: ${response.body}');
    }
  }

  // Obtenir les statistiques de parrainage
  Future<Map<String, dynamic>> getReferralStats() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/stats/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des statistiques de parrainage: ${response.body}');
    }
  }

  // Obtenir l'historique des parrainages
  Future<List<dynamic>> getReferralHistory() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/history/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique de parrainage: ${response.body}');
    }
  }

  // Vérifier si un code de parrainage est valide
  Future<bool> validateReferralCode(String code) async {
    final response = await _apiService.post('/api/referrals/validate',
      body: {'referralCode': code}
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['valid'] ?? false;
    } else {
      return false;
    }
  }

  // Appliquer un code de parrainage lors de l'inscription
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/referrals/apply',
      body: {
        'userId': userId,
        'referralCode': code,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'application du code de parrainage: ${response.body}');
    }
  }

  // Obtenir les récompenses de parrainage disponibles
  Future<List<dynamic>> getReferralRewards() async {
    final response = await _apiService.getPublic('/api/referrals/rewards');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des récompenses de parrainage: ${response.body}');
    }
  }

  // Partager le code de parrainage
  Future<Map<String, dynamic>> generateShareableReferralLink() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/shareable-link/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la génération du lien de parrainage: ${response.body}');
    }
  }

  // Obtenir les utilisateurs parrainés
  Future<List<dynamic>> getReferredUsers() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/referred-users/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des utilisateurs parrainés: ${response.body}');
    }
  }

  // Obtenir les conditions du programme de parrainage
  Future<Map<String, dynamic>> getReferralTerms() async {
    final response = await _apiService.getPublic('/api/referrals/terms');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des conditions: ${response.body}');
    }
  }

  // Créer un nouveau code de parrainage (pour les utilisateurs éligibles)
  Future<Map<String, dynamic>> createCustomReferralCode({
    required String customCode,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/referrals/custom-code',
      body: {
        'userId': userId,
        'customCode': customCode,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création du code personnalisé: ${response.body}');
    }
  }

  // Vérifier l'éligibilité à des récompenses spéciales de parrainage
  Future<Map<String, dynamic>> checkSpecialEligibility() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/referrals/special-eligibility/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification de l\'éligibilité: ${response.body}');
    }
  }
}