import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class ArtisanDashboard extends StatelessWidget {
  const ArtisanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const QuickActionCard(
          title: 'Mes Services',
          subtitle: 'Gérez vos services offerts',
          icon: Icons.build,
          iconColor: Colors.blue,
          route: '/artisan_services',
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Demandes Reçues',
          subtitle: 'Voir les nouvelles demandes',
          icon: Icons.assignment_turned_in,
          iconColor: Colors.orange,
          route: '/artisan_demands',
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Mon Portfolio',
          subtitle: 'Gérez vos réalisations',
          icon: Icons.photo_library,
          iconColor: Colors.purple,
          route: '/artisan_portfolio',
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Booster mon Profil',
          subtitle: 'Augmentez votre visibilité',
          icon: Icons.rocket_launch,
          iconColor: Colors.red,
          route: '/profile_boost',
        ),
      ],
    );
  }
}
