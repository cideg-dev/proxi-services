import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class CommercantDashboard extends StatelessWidget {
  const CommercantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuickActionCard(
          title: 'Mes Produits',
          subtitle: 'Gérez votre catalogue',
          icon: Icons.store,
          iconColor: Colors.blue,
          route: '/artisan_services',
          onTap: () => Navigator.pushNamed(context, '/artisan_services'),
        ),
        const SizedBox(height: 16),
        QuickActionCard(
          title: 'Commandes',
          subtitle: 'Suivez les commandes clients',
          icon: Icons.shopping_cart,
          iconColor: Colors.green,
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
          title: 'Booster ma Boutique',
          subtitle: 'Attirez plus de clients',
          icon: Icons.rocket_launch,
          iconColor: Colors.red,
          route: '/profile_boost',
          onTap: () => Navigator.pushNamed(context, '/profile_boost'),
        ),
      ],
    );
  }
}
