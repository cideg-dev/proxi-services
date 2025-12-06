import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/demand_model.dart';

class DemandService {
  final ApiService _apiService = ApiService();

  // Fetch all demands for the currently logged-in client
  Future<List<Demand>> getClientDemands() async {
    final response = await _apiService.get('/demands/client');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Demand.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load client demands');
    }
  }

  // Cancel a specific demand
  Future<void> cancelDemand(int demandId) async {
    final response = await _apiService.delete('/demands/$demandId');
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to cancel demand';
      throw Exception(errorMessage);
    }
  }

  // Get details for a specific demand
  Future<Demand> getDemandById(int demandId) async {
    final response = await _apiService.get('/demands/$demandId');
    if (response.statusCode == 200) {
      return Demand.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load demand details');
    }
  }

  // Fetch all demands for the currently logged-in professional (artisan or commercant)
  Future<List<Demand>> getProfessionalDemands() async {
    final response = await _apiService.get('/demands/professional');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Demand.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load professional demands');
    }
  }

  // Update the status of a demand
  Future<void> updateDemandStatus(int demandId, String status) async {
    final response = await _apiService.put(
      '/demands/$demandId/status',
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update demand status';
      throw Exception(errorMessage);
    }
  }
}
