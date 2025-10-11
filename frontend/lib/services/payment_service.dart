import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';

class PaymentService {
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, dynamic>> initiateKkiapayPayment({required double amount, required String reason}) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/payments/kkiapay/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to initiate Kkiapay payment';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> verifyKkiapayPayment({required String ourTransactionId}) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/payments/kkiapay/verify/$ourTransactionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to verify Kkiapay payment';
      throw Exception(errorMessage);
    }
  }

  // Get user's subscriptions
  Future<Map<String, dynamic>> getSubscriptions() async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/subscriptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load subscriptions';
      throw Exception(errorMessage);
    }
  }

  // Cancel a subscription
  Future<void> cancelSubscription(int subscriptionId) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/subscriptions/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'subscriptionId': subscriptionId}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to cancel subscription';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get user's invoices (payment history)
  Future<Map<String, dynamic>> getInvoices() async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/invoices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load invoices';
      throw Exception(errorMessage);
    }
  }
}
