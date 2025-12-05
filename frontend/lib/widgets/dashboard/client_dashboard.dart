import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const QuickActionCard(
          title: 'Trouver un Artisan',
          subtitle: 'Recherchez des professionnels qualifiés',
          icon: Icons.search,
          iconColor: Colors.blue,
          route: '/advanced_search',
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Mes Demandes',
          subtitle: 'Suivez vos demandes de services',
          icon: Icons.assignment,
          iconColor: Colors.orange,
          route: '/client_demands',
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Messages',
          subtitle: 'Discutez avec les artisans',
          icon: Icons.message,
          iconColor: Colors.green,
          route: '/chat_list',
        ),
      ],
    );
  }
}
