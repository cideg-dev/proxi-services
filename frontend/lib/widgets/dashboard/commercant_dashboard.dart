import 'package:flutter/material.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';

class CommercantDashboard extends StatelessWidget {
  const CommercantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const QuickActionCard(
          title: 'Mes Produits',
          subtitle: 'Gérez votre catalogue',
          icon: Icons.store,
          iconColor: Colors.blue,
          // route: '/merchant_products', // To be implemented
          route: '/artisan_services', // Temporary fallback
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Commandes',
          subtitle: 'Suivez les commandes clients',
          icon: Icons.shopping_cart,
          iconColor: Colors.green,
          // route: '/merchant_orders', // To be implemented
           route: '/artisan_demands', // Temporary fallback
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Messages',
          subtitle: 'Discutez avec vos clients',
          icon: Icons.message,
          iconColor: Colors.green,
          route: '/chat_list',
          onTap: () => Navigator.pushNamed(context, '/chat_list'), // Assuming chat_list handles role
        ),
        const SizedBox(height: 16),
        const QuickActionCard(
          title: 'Booster ma Boutique',
          subtitle: 'Attirez plus de clients',
          icon: Icons.rocket_launch,
          iconColor: Colors.red,
          route: '/profile_boost',
        ),
      ],
    );
  }
}
