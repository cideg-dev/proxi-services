import 'package:flutter/material.dart';
import 'package:frontend/services/client_service.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/merchant_service.dart';
import 'package:frontend/screens/nearby_artisans_screen.dart';
import 'package:frontend/screens/merchants_screen.dart';

class ClientServicesWidget extends StatelessWidget {
  const ClientServicesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services pour vous',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildServiceCard(
                context,
                'Trouver un Artisan',
                Icons.build,
                theme.colorScheme.primary,
                () {
                  Navigator.pushNamed(context, '/nearby_artisans');
                },
              ),
              _buildServiceCard(
                context,
                'Trouver un Commerçant',
                Icons.store,
                theme.colorScheme.secondary,
                () {
                  Navigator.pushNamed(context, '/professionals_list');
                },
              ),
              _buildServiceCard(
                context,
                'Mes Demandes',
                Icons.assignment,
                Colors.orange,
                () {
                  // TODO: Navigate to client's demands screen
                },
              ),
              _buildServiceCard(
                context,
                'Mes Favoris',
                Icons.favorite,
                Colors.red,
                () {
                  // TODO: Navigate to client's favorites screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _calculateWidth(context), // Pour 2 colonnes avec espacement
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Vérifier que la largeur de l'écran est valide
    if (screenWidth.isNaN || screenWidth.isInfinite || screenWidth <= 0) {
      // Valeur par défaut si la largeur de l'écran est invalide
      return 150.0;
    }

    double calculatedWidth = (screenWidth - 52) / 2;

    // Vérifier que le calcul est valide
    if (calculatedWidth.isNaN || calculatedWidth.isInfinite || calculatedWidth <= 0) {
      // Valeur par défaut si le calcul est invalide
      return 150.0;
    }

    // Protection supplémentaire contre les valeurs trop grandes qui pourraient causer des erreurs de layout
    if (calculatedWidth > 1000) {
      return 400.0; // Largeur max raisonnable pour une carte
    }

    return calculatedWidth;
  }
}