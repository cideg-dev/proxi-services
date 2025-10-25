import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class DemacheurService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _apiService.get('/api/demacheur/status');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // The ApiService will handle auth errors and throw an exception.
      // We can throw a more specific error here if needed.
      throw Exception('Failed to load subscription status');
    }
  }
}
