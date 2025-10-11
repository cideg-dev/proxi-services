import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:provider/provider.dart';
import '../services/demand_service.dart';
import '../widgets/glass_card.dart';

class ArtisanDemandsScreen extends StatefulWidget {
  const ArtisanDemandsScreen({Key? key}) : super(key: key);

  @override
  _ArtisanDemandsScreenState createState() => _ArtisanDemandsScreenState();
}

class _ArtisanDemandsScreenState extends State<ArtisanDemandsScreen> {
  final DemandService _demandService = DemandService();
  List<dynamic> _demands = [];
  String? _error;
  bool _isLoading = true;
  StreamSubscription? _demandUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadDemands();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListener();
    });
  }

  @override
  void dispose() {
    _demandUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDemands() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final demands = await _demandService.getArtisanDemands();
      if (!mounted) return;
      setState(() {
        _demands = demands;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _setupSocketListener() {
    final socketService = context.read<SocketService>();
    _demandUpdateSubscription = socketService.demandUpdates.listen((demandData) {
      if (!mounted) return;

      final int index = _demands.indexWhere((d) => d['id'] == demandData['id']);
      final notificationProvider = context.read<NotificationUIProvider>();

      setState(() {
        if (index != -1) {
          // This is an update to an existing demand (e.g., client cancelled)
          // For now, we just update the status
          _demands[index]['status'] = demandData['status'];
        } else {
          // This is a new demand, add it to the top of the list
          _demands.insert(0, demandData);
          notificationProvider.showNotification(
            NotificationData(
              title: 'Nouvelle demande reçue',
              message: 'Vous avez une nouvelle demande de ${demandData['clientNom'] ?? 'un client'}.',
              icon: Icons.add_alert,
              color: Theme.of(context).primaryColor,
            ),
          );
        }
      });
    });
  }

  Future<void> _updateDemandStatus(int demandId, String status) async {
    try {
      await _demandService.updateDemandStatus(demandId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande mise à jour.'), backgroundColor: Colors.green),
      );
      // Optimistically update the UI
      final int index = _demands.indexWhere((d) => d['id'] == demandId);
      if (index != -1) {
        setState(() {
          _demands[index]['status'] = status;
        });
      }
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
        title: const Text('Mes Demandes Reçues'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_demands.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDemands,
        child: ListView(
          children: const [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Vous n\'avez reçu aucune demande.')),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDemands,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _demands.length,
        itemBuilder: (context, index) {
          final demand = _demands[index];
          final isPending = demand['status'] == 'pending';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
              child: ListTile(
                title: Text('Demande de ${demand['clientNom'] ?? 'Client inconnu'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(demand['service_description'] ?? 'Pas de description.'),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(demand['status'] ?? 'inconnu'),
                      backgroundColor: Colors.black.withOpacity(0.3),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                trailing: isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                            tooltip: 'Accepter',
                            onPressed: () => _updateDemandStatus(demand['id'], 'accepted'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            tooltip: 'Refuser',
                            onPressed: () => _updateDemandStatus(demand['id'], 'declined'),
                          ),
                        ],
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