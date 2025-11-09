import 'package:flutter/material.dart';
import 'package:frontend/screens/enhanced_dashboard_screen.dart';

// Ancien DashboardScreen mis à jour pour rediriger vers le nouveau tableau de bord
class DashboardScreen extends StatelessWidget {
  final String userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    // Redirige vers le nouveau tableau de bord amélioré
    return EnhancedDashboardScreen(userRole: userRole);
  }
}