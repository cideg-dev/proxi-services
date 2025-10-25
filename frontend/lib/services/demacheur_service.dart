import 'dart:convert';
import 'package:frontend/services/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/token_manager.dart';

class DemacheurService {
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final token = await TokenManager().getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/demacheur/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load subscription status');
    }
  }
}
