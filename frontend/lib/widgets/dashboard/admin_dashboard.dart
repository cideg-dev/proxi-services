import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const QuickActionCard(
          title: 'Gestion Utilisateurs',
          subtitle: 'Gérer les comptes utilisateurs',
          icon: Icons.people,
          iconColor: Colors.blue,
          route: '/admin_users', // To be implemented or part of admin panel
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Validation Documents',
          subtitle: 'Vérifier les pièces d\'identité',
          icon: Icons.verified_user,
          iconColor: Colors.orange,
          route: '/admin_verification', // To be implemented
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Statistiques Globales',
          subtitle: 'Vue d\'ensemble de la plateforme',
          icon: Icons.analytics,
          iconColor: Colors.purple,
          route: '/admin_stats', // To be implemented
        ),
         const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Panel Admin',
          subtitle: 'Accéder au panneau complet',
          icon: Icons.admin_panel_settings,
          iconColor: Colors.red,
          route: '/admin_panel',
        ),
      ],
    );
  }
}
