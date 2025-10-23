import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/token_manager.dart'; // Import TokenManager
import 'package:provider/provider.dart';
import '../services/demand_service.dart';
import '../widgets/glass_card.dart';
import 'package:lottie/lottie.dart';
import '../widgets/empty_state.dart';

class ArtisanDemandsScreen extends StatefulWidget {
  const ArtisanDemandsScreen({Key? key}) : super(key: key);

  @override
  _ArtisanDemandsScreenState createState() => _ArtisanDemandsScreenState();
}

class _ArtisanDemandsScreenState extends State<ArtisanDemandsScreen> {
  final DemandService _demandService = DemandService();
  final TokenManager _tokenManager = TokenManager(); // Instance of TokenManager
  List<dynamic> _demands = [];
  String? _error;
  bool _isLoading = true;
  String? _userRole; // State variable for user role
  StreamSubscription? _demandUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen(); // Call the new initialization method
  }

  Future<void> _initializeScreen() async {
    // Get user role first
    final role = await _tokenManager.getUserRole();
    if (!mounted) return;

    setState(() {
      _userRole = role;
    });

    // Only load demands if the user is an artisan
    if (_userRole == 'artisan' || _userRole == 'commercant') {
      _loadDemands();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupSocketListener();
      });
    } else {
      setState(() {
        _isLoading = false; // Stop loading as we don't need to fetch data
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
      final demands = await _demandService.getProfessionalDemands();
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
    // Ensure we only listen for sockets if the user is an artisan
    if ((_userRole != 'artisan' && _userRole != 'commercant') || !mounted) return;
    
    final socketService = context.read<SocketService>();
    _demandUpdateSubscription = socketService.demandUpdates.listen((demandData) {
      if (!mounted) return;

      final int index = _demands.indexWhere((d) => d['id'] == demandData['id']);
      final notificationProvider = context.read<NotificationUIProvider>();

      setState(() {
        if (index != -1) {
          _demands[index]['status'] = demandData['status'];
        } else {
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
    // First, check if the role has been determined
    if (_userRole == null) {
      return Center(child: Lottie.asset('assets/lottie/loading.json', width: 150, height: 150));
    }

    // If the user is not an artisan, show an access denied message
    if (_userRole != 'artisan' && _userRole != 'commercant') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Cette section est réservée aux artisans.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Original body logic for artisans
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
              child: const EmptyState(message: 'Vous n\'avez reçu aucune demande.'),
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
            padding: const EdgeInsets.all(8.0), // Changed from only(bottom: 8.0) to all(8.0) for consistency
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