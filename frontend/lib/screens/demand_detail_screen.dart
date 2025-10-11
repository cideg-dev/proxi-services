import 'package:flutter/material.dart';
import '../services/demand_service.dart';

class DemandDetailScreen extends StatefulWidget {
  final int demandId;
  const DemandDetailScreen({Key? key, required this.demandId}) : super(key: key);

  @override
  _DemandDetailScreenState createState() => _DemandDetailScreenState();
}

class _DemandDetailScreenState extends State<DemandDetailScreen> {
  final DemandService _demandService = DemandService();
  late Future<Map<String, dynamic>> _demandFuture;

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
      body: FutureBuilder<Map<String, dynamic>>(
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
                _buildDetailRow('Statut', demand['status'] ?? 'N/A'),
                _buildDetailRow('Artisan', demand['artisan_name'] ?? 'N/A'),
                _buildDetailRow('Client', demand['client_name'] ?? 'N/A'),
                const Divider(height: 30),
                Text('Description', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(demand['service_description'] ?? 'Aucune description fournie.'),
                const Divider(height: 30),
                 _buildDetailRow('Créée le', demand['created_at'] ?? 'N/A'),
                 _buildDetailRow('Mise à jour le', demand['updated_at'] ?? 'N/A'),
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
