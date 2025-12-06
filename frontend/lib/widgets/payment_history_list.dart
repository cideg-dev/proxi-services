import 'package:flutter/material.dart';
import 'package:frontend/services/payment_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryList extends StatefulWidget {
  const PaymentHistoryList({super.key});

  @override
  State<PaymentHistoryList> createState() => _PaymentHistoryListState();
}

class _PaymentHistoryListState extends State<PaymentHistoryList> {
  final PaymentService _paymentService = PaymentService();
  
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final payments = await _paymentService.getPaymentHistory();
      
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de l\'historique: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Paiements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPaymentHistory,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun paiement pour le moment',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Vos paiements apparaîtront ici',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPaymentHistory,
                      child: ListView.builder(
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return _buildPaymentItem(payment, theme);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPaymentItem(dynamic payment, ThemeData theme) {
    final amount = (payment['amount'] ?? payment['total_amount'] ?? 0).toDouble();
    final status = payment['status'] ?? payment['payment_status'] ?? 'inconnu';
    final timestamp = payment['createdAt'] != null
        ? DateTime.parse(payment['createdAt'])
        : DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'succeed':
      case 'success':
        statusColor = Colors.green;
        break;
      case 'pending':
      case 'processing':
        statusColor = Colors.orange;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.payments,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paiement: ${payment['description'] ?? 'Transaction'}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${amount.toStringAsFixed(0)} XOF',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}