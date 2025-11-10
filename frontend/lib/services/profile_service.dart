import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir le profil détaillé d'un artisan
  Future<Map<String, dynamic>> getArtisanProfile(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/profile');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du profil artisan: ${response.body}');
    }
  }

  // Obtenir le profil détaillé d'un commerçant
  Future<Map<String, dynamic>> getMerchantProfile(int merchantId) async {
    final response = await _apiService.getPublic('/api/merchants/$merchantId/profile');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du profil commerçant: ${response.body}');
    }
  }

  // Mettre à jour le profil de l'utilisateur connecté
  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> profileData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.put('/api/users/$userId/profile', body: profileData);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour du profil: ${response.body}');
    }
  }

  // Obtenir le profil détaillé de l'utilisateur connecté
  Future<Map<String, dynamic>> getMyDetailedProfile() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/users/$userId/profile');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement du profil: ${response.body}');
    }
  }

  // Ajouter ou mettre à jour les certifications
  Future<Map<String, dynamic>> updateCertifications(List<String> certifications) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.put('/api/users/$userId/certifications',
      body: {'certifications': certifications}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour des certifications: ${response.body}');
    }
  }

  // Obtenir les horaires de travail
  Future<Map<String, dynamic>> getWorkSchedule(int userId) async {
    final response = await _apiService.get('/api/users/$userId/schedule');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des horaires: ${response.body}');
    }
  }

  // Mettre à jour les horaires de travail
  Future<Map<String, dynamic>> updateWorkSchedule(Map<String, dynamic> schedule) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.put('/api/users/$userId/schedule',
      body: schedule
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour des horaires: ${response.body}');
    }
  }

  // Télécharger une image de profil
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final imageBytes = await http.MultipartFile.fromPath('image', imagePath);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/profile-image'),
    );
    
    request.files.add(imageBytes);
    final token = await _tokenManager.getToken();
    request.headers['Authorization'] = 'Bearer $token';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du téléchargement de l\'image: ${response.body}');
    }
  }

  // Télécharger une image de couverture
  Future<Map<String, dynamic>> uploadCoverImage(String imagePath) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final imageBytes = await http.MultipartFile.fromPath('image', imagePath);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/cover-image'),
    );
    
    request.files.add(imageBytes);
    final token = await _tokenManager.getToken();
    request.headers['Authorization'] = 'Bearer $token';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du téléchargement de l\'image de couverture: ${response.body}');
    }
  }

  // Obtenir les statistiques du profil
  Future<Map<String, dynamic>> getProfileStats(int userId) async {
    final response = await _apiService.get('/api/users/$userId/stats');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des statistiques: ${response.body}');
    }
  }
}