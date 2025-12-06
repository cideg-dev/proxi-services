import 'package:flutter/material.dart';
import '../services/demand_service.dart';
import '../models/demand_model.dart';
import 'package:intl/intl.dart';

class DemandDetailScreen extends StatefulWidget {
  final int demandId;
  const DemandDetailScreen({Key? key, required this.demandId}) : super(key: key);

  @override
  _DemandDetailScreenState createState() => _DemandDetailScreenState();
}

class _DemandDetailScreenState extends State<DemandDetailScreen> {
  final DemandService _demandService = DemandService();
  late Future<Demand> _demandFuture;

  @override
  void initState() {
    super.initState();
    _demandFuture = _demandService.getDemandById(widget.demandId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la Demande #${widget.demandId}'),
      ),
      body: FutureBuilder<Demand>(
        future: _demandFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucun détail trouvé pour cette demande.'));
          }

          final demand = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                _buildDetailRow('Statut', demand.status),
                _buildDetailRow('Artisan', demand.professionalName ?? 'N/A'),
                _buildDetailRow('Client', demand.clientName ?? 'N/A'),
                const Divider(height: 30),
                Text('Description', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(demand.serviceDescription),
                const Divider(height: 30),
                 _buildDetailRow('Créée le', DateFormat('dd/MM/yyyy HH:mm').format(demand.createdAt)),
                 if (demand.scheduledDate != null)
                   _buildDetailRow('Prévue le', DateFormat('dd/MM/yyyy HH:mm').format(demand.scheduledDate!)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
