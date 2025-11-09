import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:frontend/widgets/payment_form.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final int? artisanId;
  final int? merchantId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    this.artisanId,
    this.merchantId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effectuer un Paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la transaction
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé de la transaction',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Description:'),
                          Expanded(
                            child: Text(
                              widget.description,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant:'),
                          Text(
                            '${widget.amount.toStringAsFixed(0)} XOF',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Formulaire de paiement
              PaymentForm(
                amount: widget.amount,
                description: widget.description,
                artisanId: widget.artisanId,
                merchantId: widget.merchantId,
                onPaymentComplete: (success, transactionId) {
                  if (success) {
                    // Afficher un message de succès
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Paiement réussi'),
                        content: const Text('Votre paiement a été traité avec succès.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Retourner à l'écran précédent ou à un écran de confirmation
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Afficher un message d'erreur
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Échec du paiement'),
                        content: const Text('Le paiement a échoué. Veuillez réessayer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}