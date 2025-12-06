import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:provider/provider.dart';
import '../services/demand_service.dart';
import '../widgets/glass_card.dart';
import 'demand_detail_screen.dart';
import 'package:lottie/lottie.dart';
import '../widgets/empty_state.dart';
import '../models/demand_model.dart';

class ClientDemandsScreen extends StatefulWidget {
  const ClientDemandsScreen({Key? key}) : super(key: key);

  @override
  _ClientDemandsScreenState createState() => _ClientDemandsScreenState();
}

class _ClientDemandsScreenState extends State<ClientDemandsScreen> {
  final DemandService _demandService = DemandService();
  final TokenManager _tokenManager = TokenManager();
  List<Demand> _demands = [];
  String? _error;
  bool _isLoading = true;
  String? _userRole;
  StreamSubscription? _demandUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final role = await _tokenManager.getUserRole();
    if (!mounted) return;

    setState(() {
      _userRole = role;
    });

    if (_userRole == 'client') {
      _loadDemands();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupSocketListener();
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
      final demands = await _demandService.getClientDemands();
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
    if (_userRole != 'client' || !mounted) return;

    final socketService = context.read<SocketService>();
    _demandUpdateSubscription = socketService.demandUpdates.listen((updatedDemand) {
      if (!mounted) return;

      // Note: socket update returns Map, not Demand object directly usually.
      // We might need to handle this carefully. Assuming updatedDemand is Map.
      final int index = _demands.indexWhere((d) => d.id == updatedDemand['id']);
      if (index != -1) {
        // We can't easily update immutable Demand object in place.
        // We should probably reload or create a new Demand object.
        // For now, let's just reload to be safe and consistent.
        _loadDemands();

        final notificationProvider = context.read<NotificationUIProvider>();
        notificationProvider.showNotification(
          NotificationData(
            title: 'Statut de la demande mis à jour',
            message: 'Votre demande pour ${updatedDemand['professional_name'] ?? 'un professionnel'} est maintenant "${updatedDemand['status']}".',
            icon: Icons.info_outline,
            color: Colors.blueAccent,
          ),
        );
      }
    });
  }

  Future<void> _cancelDemand(int demandId) async {
    try {
      await _demandService.cancelDemand(demandId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande annulée avec succès.'), backgroundColor: Colors.green),
      );
      _loadDemands(); // Refresh the list
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
        title: const Text('Mes Demandes'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_userRole == null) {
      return Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150));
    }

    if (_userRole != 'client') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Cette section est réservée aux clients.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150));
    }
    if (_error != null) {
      return EmptyState(message: _error!);
    }
    if (_demands.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDemands,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const EmptyState(message: 'Vous n\'avez fait aucune demande.'),
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
          final isPending = demand.status == 'pending';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
              child: ListTile(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/demand_detail',
                    arguments: demand.id,
                  ).then((_) => _loadDemands()); // Refresh when coming back
                },
                title: Text(demand.professionalName ?? 'Professionnel inconnu'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demande #${demand.id}'),
                    const SizedBox(height: 4),
                    Text(demand.serviceDescription),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(demand.status),
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                trailing: isPending
                    ? TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        label: const Text('Annuler', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => _showCancelConfirmation(demand.id),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(int demandId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: const Text('Êtes-vous sûr de vouloir annuler cette demande ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Non'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Oui, annuler'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelDemand(demandId);
              },
            ),
          ],
        );
      },
    );
  }
}
