import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class QAService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getQuestions(int artisanId) async {
    final response = await _apiService.getPublic('/api/artisans/$artisanId/questions');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> askQuestion(int artisanId, String questionText) async {
    final response = await _apiService.post(
      '/api/artisans/$artisanId/questions',
      body: {'question': questionText},
    );
    if (response.statusCode != 201) { // Assuming 201 Created
      throw Exception('Failed to ask question');
    }
  }
}
