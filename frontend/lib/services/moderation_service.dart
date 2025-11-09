import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ModerationService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Signaler un contenu inapproprié
  Future<Map<String, dynamic>> reportContent({
    required String contentType, // 'review', 'message', 'profile', 'service', etc.
    required int contentId,
    required String reason,
    String? additionalDetails,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/moderation/report',
      body: {
        'userId': userId,
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        if (additionalDetails != null) 'additionalDetails': additionalDetails,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du signalement de contenu: ${response.body}');
    }
  }

  // Obtenir les contenus signalés (pour les modérateurs/admins)
  Future<List<dynamic>> getReportedContent({
    String? status, // 'pending', 'reviewed', 'resolved', 'dismissed'
    String? contentType,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (contentType != null) queryParams['contentType'] = contentType;

    final uri = Uri.parse('/api/moderation/reported-content').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des contenus signalés: ${response.body}');
    }
  }

  // Mettre à jour le statut d'un signalement
  Future<Map<String, dynamic>> updateReportStatus({
    required int reportId,
    required String newStatus, // 'reviewed', 'resolved', 'dismissed'
    String? resolutionNotes,
  }) async {
    final response = await _apiService.put('/api/moderation/reports/$reportId/status',
      body: {
        'newStatus': newStatus,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour du statut: ${response.body}');
    }
  }

  // Obtenir les statistiques de modération
  Future<Map<String, dynamic>> getModerationStats() async {
    final response = await _apiService.get('/api/moderation/stats');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des statistiques: ${response.body}');
    }
  }

  // Bloquer un utilisateur
  Future<Map<String, dynamic>> blockUser({
    required int userIdToBlock,
    required String reason,
    Duration? duration,
  }) async {
    final currentUserId = await _tokenManager.getUserId();
    if (currentUserId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/moderation/block-user',
      body: {
        'currentUserId': currentUserId,
        'userIdToBlock': userIdToBlock,
        'reason': reason,
        if (duration != null) 'duration': duration.inDays,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du blocage de l\'utilisateur: ${response.body}');
    }
  }

  // Débloquer un utilisateur
  Future<void> unblockUser(int userId) async {
    final response = await _apiService.post('/api/moderation/unblock-user/$userId');
    
    if (response.statusCode != 200) {
      throw Exception('Échec du déblocage de l\'utilisateur: ${response.body}');
    }
  }

  // Obtenir la liste des utilisateurs bloqués
  Future<List<dynamic>> getBlockedUsers() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/moderation/blocked-users/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des utilisateurs bloqués: ${response.body}');
    }
  }

  // Obtenir les règles de modération
  Future<List<dynamic>> getModerationRules() async {
    final response = await _apiService.get('/api/moderation/rules');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des règles: ${response.body}');
    }
  }

  // Vérifier automatiquement un contenu à l'aide de l'IA
  Future<Map<String, dynamic>> verifyContentWithAI({
    required String contentType,
    required String content,
  }) async {
    final response = await _apiService.post('/api/moderation/ai-verification',
      body: {
        'contentType': contentType,
        'content': content,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification IA: ${response.body}');
    }
  }

  // Mettre en quarantaine un contenu suspect
  Future<Map<String, dynamic>> quarantineContent({
    required String contentType,
    required int contentId,
    required String reason,
  }) async {
    final response = await _apiService.post('/api/moderation/quarantine',
      body: {
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise en quarantaine: ${response.body}');
    }
  }

  // Obtenir les rapports d'activité d'un utilisateur
  Future<Map<String, dynamic>> getUserActivityReport(int userId) async {
    final response = await _apiService.get('/api/moderation/user-activity/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du rapport d\'activité: ${response.body}');
    }
  }
}