import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class QAService {
  Future<List<dynamic>> getQuestions(int artisanId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/artisans/$artisanId/questions'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> askQuestion(int artisanId, String questionText) async {
    // This is a placeholder. You need to implement the actual API call.
    print('Asking question: $questionText to artisan $artisanId');
    await Future.delayed(const Duration(seconds: 1));
  }
}
