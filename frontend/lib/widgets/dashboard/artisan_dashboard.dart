import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';
import 'package:frontend/services/dashboard_service.dart';

class ArtisanDashboard extends StatefulWidget {
  const ArtisanDashboard({super.key});

  @override
  State<ArtisanDashboard> createState() => _ArtisanDashboardState();
}

class _ArtisanDashboardState extends State<ArtisanDashboard> {
  final DashboardService _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _dashboardService.getArtisanStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'servicesCount': 0, 'demandsReceived': 0};

        return Column(
          children: [
            QuickActionCard(
              title: 'Mes Services',
              subtitle: '${stats['servicesCount']} services actifs',
              icon: Icons.build,
              iconColor: Colors.blue,
              route: '/artisan_services',
              onTap: () => Navigator.pushNamed(context, '/artisan_services'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Demandes Reçues',
              subtitle: '${stats['demandsReceived']} nouvelles demandes',
              icon: Icons.assignment_turned_in,
              iconColor: Colors.orange,
              route: '/artisan_demands',
              onTap: () => Navigator.pushNamed(context, '/artisan_demands'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Messages',
              subtitle: 'Discutez avec vos clients',
              icon: Icons.message,
              iconColor: Colors.green,
              route: '/chat_list',
              onTap: () => Navigator.pushNamed(context, '/chat_list'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Mon Portfolio',
              subtitle: 'Gérez vos réalisations',
              icon: Icons.photo_library,
              iconColor: Colors.purple,
              route: '/artisan_portfolio',
              onTap: () => Navigator.pushNamed(context, '/artisan_portfolio'),
            ),
            const SizedBox(height: 16),
            QuickActionCard(
              title: 'Booster mon Profil',
              subtitle: 'Augmentez votre visibilité',
              icon: Icons.rocket_launch,
              iconColor: Colors.red,
              route: '/profile_boost',
              onTap: () => Navigator.pushNamed(context, '/profile_boost'),
            ),
          ],
        );
      },
    );
  }
}
