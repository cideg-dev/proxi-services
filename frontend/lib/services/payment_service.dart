import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class PaymentService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

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

  // NEW: Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency = 'XOF', // Devise locale
    required String description,
    String? paymentMethod,
    int? artisanId,
    int? merchantId,
  }) async {
    final response = await _apiService.post('/api/payments/intent', 
      body: {
        'amount': (amount * 100).toInt(), // Convertir en centimes
        'currency': currency,
        'description': description,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (artisanId != null) 'artisanId': artisanId,
        if (merchantId != null) 'merchantId': merchantId,
      }
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création de l\'intention de paiement: ${response.body}');
    }
  }

  // NEW: Confirm a payment
  Future<Map<String, dynamic>> confirmPayment(String paymentIntentId) async {
    final response = await _apiService.post('/api/payments/confirm',
      body: {'paymentIntentId': paymentIntentId}
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la confirmation du paiement: ${response.body}');
    }
  }

  // NEW: Create Kkiapay payment via backend
  Future<Map<String, dynamic>> createKkiapayPayment({
    required double amount,
    required String reason,
    required String customerEmail,
    required String phoneNumber,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/payments/kkiapay',
      body: {
        'amount': amount.toInt(),
        'reason': reason,
        'customerEmail': customerEmail,
        'phoneNumber': phoneNumber,
        'userId': userId,
      }
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création du paiement Kkiapay: ${response.body}');
    }
  }

  // NEW: Get payment history
  Future<List<dynamic>> getPaymentHistory() async {
    final response = await _apiService.get('/api/payments/history');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique des paiements: ${response.body}');
    }
  }

  // NEW: Get details of a specific payment
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    final response = await _apiService.get('/api/payments/$paymentId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des détails du paiement: ${response.body}');
    }
  }

  // NEW: Request a refund
  Future<Map<String, dynamic>> requestRefund(String paymentId, double amount, String reason) async {
    final response = await _apiService.post('/api/payments/$paymentId/refund',
      body: {
        'amount': amount,
        'reason': reason,
      }
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la demande de remboursement: ${response.body}');
    }
  }

  // NEW: Save a payment method
  Future<Map<String, dynamic>> savePaymentMethod(String paymentMethodId) async {
    final response = await _apiService.post('/api/payments/methods',
      body: {'paymentMethodId': paymentMethodId}
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'enregistrement du mode de paiement: ${response.body}');
    }
  }

  // NEW: Get saved payment methods
  Future<List<dynamic>> getSavedPaymentMethods() async {
    final response = await _apiService.get('/api/payments/methods');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des modes de paiement: ${response.body}');
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

  // Get user's invoices (payment history)
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
