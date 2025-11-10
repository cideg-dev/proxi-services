import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:http/http.dart' as http;

class IdentityVerificationService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Démarrer le processus de vérification
  Future<Map<String, dynamic>> startVerification({
    required String verificationType, // 'document', 'phone', 'email', 'business'
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/verifications/start',
      body: {
        'userId': userId,
        'verificationType': verificationType,
      }
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du démarrage de la vérification: ${response.body}');
    }
  }

  // Envoyer les documents pour la vérification
  Future<Map<String, dynamic>> submitDocuments({
    required int verificationRequestId,
    required String documentType, // 'id_card', 'passport', 'business_license', etc.
    required String frontImagePath,
    String? backImagePath,
    String? selfieImagePath,
  }) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/api/verifications/$verificationRequestId/documents'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    
    // Ajouter les fichiers
    request.files.add(
      await http.MultipartFile.fromPath('front', frontImagePath),
    );
    
    if (backImagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('back', backImagePath),
      );
    }
    
    if (selfieImagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('selfie', selfieImagePath),
      );
    }
    
    // Ajouter les métadonnées
    request.fields['documentType'] = documentType;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'envoi des documents: ${response.body}');
    }
  }

  // Obtenir le statut de vérification de l'utilisateur
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/verifications/status/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du statut de vérification: ${response.body}');
    }
  }

  // Obtenir les demandes de vérification en attente (pour les modérateurs/admins)
  Future<List<dynamic>> getPendingVerifications() async {
    final response = await _apiService.get('/api/verifications/pending');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des vérifications en attente: ${response.body}');
    }
  }

  // Vérifier un document (pour les modérateurs/admins)
  Future<Map<String, dynamic>> reviewVerification({
    required int verificationId,
    required bool approved,
    String? rejectionReason,
  }) async {
    final response = await _apiService.put('/api/verifications/$verificationId/review',
      body: {
        'approved': approved,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification du document: ${response.body}');
    }
  }

  // Obtenir l'historique des vérifications
  Future<List<dynamic>> getVerificationHistory() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/verifications/history/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique: ${response.body}');
    }
  }

  // Télécharger un justificatif de vérification
  Future<String> downloadVerificationDocument(int verificationId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // Cette fonctionnalité dépendra de l'implémentation côté serveur
    // Pour l'instant, nous retournons une URL de téléchargement
    return '${ApiConstants.baseUrl}/api/verifications/$verificationId/document';
  }

  // Vérification de numéro de téléphone
  Future<Map<String, dynamic>> requestPhoneVerification(String phoneNumber) async {
    final response = await _apiService.post('/api/verifications/phone/request',
      body: {'phoneNumber': phoneNumber}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la demande de vérification téléphonique: ${response.body}');
    }
  }

  // Vérification de numéro de téléphone avec code
  Future<Map<String, dynamic>> verifyPhoneCode(String phoneNumber, String code) async {
    final response = await _apiService.post('/api/verifications/phone/verify',
      body: {
        'phoneNumber': phoneNumber,
        'code': code,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la vérification du code téléphonique: ${response.body}');
    }
  }
}