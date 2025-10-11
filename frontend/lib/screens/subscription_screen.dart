import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:frontend/widgets/glass_card.dart';
import 'package:intl/intl.dart'; // For date formatting

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _paymentService.getSubscriptions(); // Need to add this method to PaymentService
      if (!mounted) return;
      setState(() {
        _subscriptions = response['subscriptions'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des abonnements: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelSubscription(int subscriptionId) async {
    try {
      await _paymentService.cancelSubscription(subscriptionId); // Need to add this method to PaymentService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abonnement annulé avec succès.'), backgroundColor: Colors.green),
      );
      _loadSubscriptions(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Abonnements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _subscriptions.isEmpty
                  ? const Center(child: Text('Vous n\'avez aucun abonnement actif.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = _subscriptions[index];
                        final bool isActive = subscription['status'] == 'active';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassCard(
                            child: ListTile(
                              title: Text(subscription['subscription_type']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Statut: ${subscription['status']}'),
                                  Text('Début: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(subscription['start_date']))}'),
                                  if (subscription['end_date'] != null)
                                    Text('Fin: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(subscription['end_date']))}'),
                                ],
                              ),
                              trailing: isActive
                                  ? ElevatedButton(
                                      onPressed: () => _cancelSubscription(subscription['id']),
                                      child: const Text('Annuler'),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
