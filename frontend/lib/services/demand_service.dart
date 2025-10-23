import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';

class DemandService {
  final TokenManager _tokenManager = TokenManager();

  // Fetch all demands for the currently logged-in client
  Future<List<dynamic>> getClientDemands() async {
    final token = await _tokenManager.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/client/demandes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load client demands');
    }
  }

  // Cancel a specific demand
  Future<void> cancelDemand(int demandId) async {
    final token = await _tokenManager.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/demandes/$demandId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      // Try to parse the error message from the server
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to cancel demand';
      throw Exception(errorMessage);
    }
  }

  // Get details for a specific demand
  Future<Map<String, dynamic>> getDemandById(int demandId) async {
    final token = await _tokenManager.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/demandes/$demandId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load demand details');
    }
    return jsonDecode(response.body);
  }

  // Fetch all demands for the currently logged-in professional (artisan or commercant)
  Future<List<dynamic>> getProfessionalDemands() async {
    final token = await _tokenManager.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/professional/demandes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load professional demands');
    }
  }

  // Update the status of a demand
  Future<void> updateDemandStatus(int demandId, String status) async {
    final token = await _tokenManager.getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/demandes/$demandId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{'status': status}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update demand status';
      throw Exception(errorMessage);
    }
  }
}
