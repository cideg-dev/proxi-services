import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> initiateKkiapayPayment({required double amount, required String reason}) async {
    final response = await _apiService.post(
      '/api/payments/kkiapay/initiate',
      body: {
        'amount': amount,
        'reason': reason,
      },
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
    final response = await _apiService.get('/api/payments/kkiapay/verify/$ourTransactionId');

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
    final response = await _apiService.get('/api/subscriptions');

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
    final response = await _apiService.post(
      '/api/subscriptions/cancel',
      body: {'subscriptionId': subscriptionId},
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to cancel subscription';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get user's invoices (payment history)
  Future<Map<String, dynamic>> getInvoices() async {
    final response = await _apiService.get('/api/invoices');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to load invoices';
      throw Exception(errorMessage);
    }
  }
}
