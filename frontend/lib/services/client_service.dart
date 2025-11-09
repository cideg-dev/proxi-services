import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ClientService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getClients() async {
    final response = await _apiService.getPublic('/api/clients');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load clients');
    }
  }

  Future<Map<String, dynamic>> getClientById(int id) async {
    final response = await _apiService.getPublic('/api/clients/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load client');
    }
  }

  Future<List<dynamic>> getClientDemands(int clientId) async {
    final response = await _apiService.get('/api/clients/$clientId/demands');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load client demands');
    }
  }

  Future<List<dynamic>> getNearbyClients(double latitude, double longitude, {double radius = 10.0}) async {
    final response = await _apiService.getPublic(
      '/api/clients/nearby?lat=$latitude&lng=$longitude&radius=${radius.toString()}'
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load nearby clients: ${response.body}');
    }
  }

  // Méthodes pour les clients authentifiés
  Future<Map<String, dynamic>> getMyProfile() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final response = await _apiService.get('/api/clients/$userId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateMyProfile(Map<String, dynamic> profileData) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    final response = await _apiService.put('/api/clients/$userId', body: profileData);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }
}