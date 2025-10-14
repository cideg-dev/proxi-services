import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class SystemService {
  Future<String?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/system/version'),
      ).timeout(const Duration(seconds: 5));

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
