import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:frontend/widgets/glass_card.dart';
import 'package:intl/intl.dart'; // For date formatting

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _paymentService.getInvoices(); // Need to add this method to PaymentService
      if (!mounted) return;
      setState(() {
        _invoices = response['invoices'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des factures: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Factures'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _invoices.isEmpty
                  ? const Center(child: Text('Vous n\'avez aucune facture.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassCard(
                            child: ListTile(
                              title: Text('Facture #${invoice['id']} - ${invoice['reason'] ?? 'Paiement'}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Montant: ${invoice['amount']} ${invoice['currency']}'),
                                  Text('Statut: ${invoice['status']}'),
                                  Text('Méthode: ${invoice['payment_method'] ?? 'N/A'}'),
                                  Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(invoice['created_at']))}'),
                                ],
                              ),
                              onTap: () {
                                // TODO: Navigate to invoice detail screen if needed
                                print('View invoice details for ${invoice['id']}');
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
