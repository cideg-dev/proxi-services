import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';
import 'package:frontend/services/dashboard_service.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final DashboardService _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _dashboardService.getClientStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'demandsCount': 0, 'unreadMessages': 0};
        
        return Column(
          children: [
            QuickActionCard(
              title: 'Trouver un Artisan',
              subtitle: 'Recherchez des professionnels qualifiés',
              icon: Icons.search,
              iconColor: Colors.blue,
              route: '/advanced_search',
              onTap: () => Navigator.pushNamed(context, '/advanced_search'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Mes Demandes',
              subtitle: '${stats['demandsCount']} demandes en cours',
              icon: Icons.assignment,
              iconColor: Colors.orange,
              route: '/client_demands',
              onTap: () => Navigator.pushNamed(context, '/client_demands'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Messages',
              subtitle: '${stats['unreadMessages']} nouveaux messages',
              icon: Icons.message,
              iconColor: Colors.green,
              route: '/chat_list',
              onTap: () => Navigator.pushNamed(context, '/chat_list'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Artisans à proximité',
              subtitle: 'Voir sur la carte',
              icon: Icons.map,
              iconColor: Colors.red,
              route: '/nearby_artisans',
              onTap: () => Navigator.pushNamed(context, '/nearby_artisans'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Commerçants',
              subtitle: 'Découvrir les boutiques',
              icon: Icons.store,
              iconColor: Colors.purple,
              route: '/merchants',
              onTap: () => Navigator.pushNamed(context, '/merchants'),
            ),
          ],
        );
      },
    );
  }
}
