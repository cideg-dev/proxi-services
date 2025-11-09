import 'package:flutter/material.dart';
import 'package:frontend/services/client_service.dart';
import 'package:frontend/widgets/client_services_widget.dart';
import 'package:frontend/screens/login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final ClientService _clientService = ClientService();
  
  Map<String, dynamic>? _clientProfile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadClientProfile();
  }

  Future<void> _loadClientProfile() async {
    try {
      final profile = await _clientService.getMyProfile();
      
      setState(() {
        _clientProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du profil: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    // Déconnexion du client
    _clientService.updateMyProfile({}).catchError((error) {
      // Ne pas tenir compte de l'erreur lors de la déconnexion
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Espace Client'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
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
                        onPressed: _loadClientProfile,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section profil
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _clientProfile?['name'] ?? _clientProfile?['email'] ?? 'Client',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _clientProfile?['email'] ?? 'Email non disponible',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Services pour le client
                      const ClientServicesWidget(),
                      // Historique des demandes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Mes Demandes Récentes',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      FutureBuilder<List<dynamic>>(
                        future: _clientService.getClientDemands(_clientProfile?['id'] ?? 0),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(child: Text('Erreur: ${snapshot.error}')),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'Aucune demande trouvée.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length > 3 ? 3 : snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final demand = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: ListTile(
                                  leading: const Icon(Icons.assignment),
                                  title: Text(demand['title'] ?? 'Demande sans titre'),
                                  subtitle: Text(
                                    demand['description'] ?? 'Description non disponible',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    demand['status'] ?? 'Statut inconnu',
                                    style: TextStyle(
                                      color: _getStatusColor(theme, demand['status']),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Color _getStatusColor(ThemeData theme, String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'accepted':
      case 'accepté':
        return Colors.green;
      case 'rejected':
      case 'rejeté':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}