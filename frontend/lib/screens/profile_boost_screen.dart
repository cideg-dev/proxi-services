import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:frontend/screens/kkiapay_webview_screen.dart'; // New import

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({Key? key}) : super(key: key);

  @override
  _ProfileBoostScreenState createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String? _error;

  // Example boost options
  final List<Map<String, dynamic>> _boostOptions = [
    {'id': 1, 'name': 'Boost 1 semaine', 'amount': 500.0, 'reason': 'Profile Boost 1 week'},
    {'id': 2, 'name': 'Boost 1 mois', 'amount': 2000.0, 'reason': 'Profile Boost 1 month'},
    {'id': 3, 'name': 'Boost 3 mois', 'amount': 5000.0, 'reason': 'Profile Boost 3 months'},
  ];

  Future<void> _initiatePayment(double amount, String reason) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _paymentService.initiateKkiapayPayment(amount: amount, reason: reason);
      if (!mounted) return;

      final String paymentUrl = response['paymentUrl'];
      final String ourTransactionId = response['ourTransactionId'];

      // Navigate to WebView for Kkiapay payment
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KkiapayWebviewScreen(
            paymentUrl: paymentUrl,
            ourTransactionId: ourTransactionId,
          ),
        ),
      );

      if (!mounted) return;

      // Handle result from WebView (e.g., payment success/failure)
      if (result != null && result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement réussi ! Votre profil est boosté.'), backgroundColor: Colors.green),
        );
        // Optionally, navigate back to profile or update UI
        Navigator.pop(context, true); // Indicate success to previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement annulé ou échoué: ${result?['message'] ?? 'Inconnu'}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de l\'initiation du paiement: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booster votre profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _boostOptions.length,
                  itemBuilder: (context, index) {
                    final option = _boostOptions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        title: Text(option['name']),
                        subtitle: Text('${option['amount']} XOF'),
                        trailing: ElevatedButton(
                          onPressed: () => _initiatePayment(option['amount'], option['reason']),
                          child: const Text('Payer'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
