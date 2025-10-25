import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class SystemService {
  final ApiService _apiService = ApiService();

  Future<String?> getLatestVersion() async {
    try {
      final response = await _apiService.getPublic('/api/system/version')
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['latest_version'] as String?;
      }
    } catch (e) {
      // If the request fails (timeout, no connection, etc.), just ignore it.
      // We don't want to block the user for an update check.
      print('Failed to check for updates: $e');
    }
    return null;
  }
}
