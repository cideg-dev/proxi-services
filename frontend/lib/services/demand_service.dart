import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class DemandService {
  final ApiService _apiService = ApiService();

  // Fetch all demands for the currently logged-in client
  Future<List<dynamic>> getClientDemands() async {
    final response = await _apiService.get('/api/client/demandes');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load client demands');
    }
  }

  // Cancel a specific demand
  Future<void> cancelDemand(int demandId) async {
    final response = await _apiService.delete('/api/demandes/$demandId');
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to cancel demand';
      throw Exception(errorMessage);
    }
  }

  // Get details for a specific demand
  Future<Map<String, dynamic>> getDemandById(int demandId) async {
    final response = await _apiService.get('/api/demandes/$demandId');
    if (response.statusCode != 200) {
      throw Exception('Failed to load demand details');
    }
    return jsonDecode(response.body);
  }

  // Fetch all demands for the currently logged-in professional (artisan or commercant)
  Future<List<dynamic>> getProfessionalDemands() async {
    final response = await _apiService.get('/api/professional/demandes');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load professional demands');
    }
  }

  // Update the status of a demand
  Future<void> updateDemandStatus(int demandId, String status) async {
    final response = await _apiService.put(
      '/api/demandes/$demandId/status',
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update demand status';
      throw Exception(errorMessage);
    }
  }
}
