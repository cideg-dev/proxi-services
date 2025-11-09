import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';

class PaymentForm extends StatefulWidget {
  final double amount;
  final String description;
  final int? artisanId;
  final int? merchantId;
  final Function(bool success, String? transactionId)? onPaymentComplete;

  const PaymentForm({
    super.key,
    required this.amount,
    required this.description,
    this.artisanId,
    this.merchantId,
    this.onPaymentComplete,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _paymentMethod = 'kkiapay';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Text(
            'Paiement de ${widget.amount.toStringAsFixed(0)} XOF',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Sélection de la méthode de paiement
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Méthode de paiement',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'kkiapay',
                        label: Text('Kkiapay'),
                        icon: Icon(Icons.payments),
                      ),
                      ButtonSegment(
                        value: 'orange_money',
                        label: Text('Orange Money'),
                        icon: Icon(Icons.phone_iphone),
                      ),
                      ButtonSegment(
                        value: 'mtn_mobile_money',
                        label: Text('MTN Mobile Money'),
                        icon: Icon(Icons.phone_iphone),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _paymentMethod = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Informations de contact
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations de contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Message d'erreur
          if (_errorMessage != null)
            Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Bouton de paiement
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text('Payer ${widget.amount.toStringAsFixed(0)} XOF'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_emailController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs obligatoires';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Créer le paiement en fonction de la méthode sélectionnée
      Map<String, dynamic> result;
      
      switch (_paymentMethod) {
        case 'kkiapay':
          result = await _paymentService.createKkiapayPayment(
            amount: widget.amount,
            reason: widget.description,
            customerEmail: _emailController.text,
            phoneNumber: _phoneController.text,
          );
          break;
        default:
          // Pour les autres méthodes, on utiliserait d'autres appels API
          result = await _paymentService.createKkiapayPayment(
            amount: widget.amount,
            reason: widget.description,
            customerEmail: _emailController.text,
            phoneNumber: _phoneController.text,
          );
          break;
      }

      // Appeler la fonction de rappel avec le résultat
      if (widget.onPaymentComplete != null) {
        widget.onPaymentComplete!(true, result['transactionId']?.toString());
      }

      // Fermer le dialogue avec succès
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement initié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du paiement: $e';
        _isLoading = false;
      });
      if (widget.onPaymentComplete != null) {
        widget.onPaymentComplete!(false, null);
      }
    }
  }
}