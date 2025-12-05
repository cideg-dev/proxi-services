import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/api_constants.dart';

class DashboardService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getClientStats() async {
    try {
      // This endpoint needs to be implemented on the backend
      // For now, we can fetch demands and count them
      final response = await _apiService.get('${ApiConstants.demands}/client');
      if (response.statusCode == 200) {
        final List<dynamic> demands = jsonDecode(response.body);
        return {
          'demandsCount': demands.length,
          'unreadMessages': 0, // Placeholder
        };
      }
      return {'demandsCount': 0, 'unreadMessages': 0};
    } catch (e) {
      print('Error fetching client stats: $e');
      return {'demandsCount': 0, 'unreadMessages': 0};
    }
  }

  Future<Map<String, dynamic>> getArtisanStats() async {
    try {
      // Placeholder for artisan stats
      return {
        'servicesCount': 0,
        'demandsReceived': 0,
        'profileViews': 0,
      };
    } catch (e) {
      print('Error fetching artisan stats: $e');
      return {};
    }
  }
}
