import 'package:flutter/material.dart';
import 'package:frontend/screens/kkiapay_webview_screen.dart';
import 'package:frontend/services/demacheur_service.dart';
import 'package:frontend/services/payment_service.dart';

class DemacheurScreen extends StatefulWidget {
  const DemacheurScreen({Key? key}) : super(key: key);

  @override
  _DemacheurScreenState createState() => _DemacheurScreenState();
}

class _DemacheurScreenState extends State<DemacheurScreen> {
  final DemacheurService _demacheurService = DemacheurService();
  final PaymentService _paymentService = PaymentService();
  String _status = 'Chargement...';
  String? _expiresAt;
  bool _isLoading = true;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionStatus();
  }

  Future<void> _fetchSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _demacheurService.getSubscriptionStatus();
      setState(() {
        _status = data['status'];
        _expiresAt = data['expires_at'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubscription() async {
    setState(() {
      _isPaying = true;
    });

    try {
      // Amount is in CFA, e.g., 2000 F CFA
      final response = await _paymentService.initiateKkiapayPayment(
        amount: 2000,
        reason: 'Abonnement Démacheur Proxi-Services',
      );

      final String? paymentUrl = response['paymentUrl'];
      final String? ourTransactionId = response['ourTransactionId'];

      if (paymentUrl != null && ourTransactionId != null) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KkiapayWebviewScreen(
              paymentUrl: paymentUrl,
              ourTransactionId: ourTransactionId,
            ),
          ),
        );

        // Handle payment result
        if (result != null && result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paiement réussi!')),
          );
          // Refresh subscription status
          _fetchSubscriptionStatus();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le paiement a échoué ou a été annulé.')),
          );
        }
      } else {
        throw Exception('URL de paiement non reçue.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isPaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir Démacheur'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Statut de l\'abonnement: $_status'),
                    if (_expiresAt != null)
                      Text('Expire le: $_expiresAt'),
                    const SizedBox(height: 20),
                    if (_status != 'active')
                      ElevatedButton(
                        onPressed: _isPaying ? null : _handleSubscription,
                        child: _isPaying
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('S\'abonner (2000 F CFA)'),
                      )
                    else
                      ElevatedButton(
                        onPressed: null,
                        child: const Text('Abonnement Actif'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
