import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/dashboard/client_dashboard.dart';
import 'package:frontend/widgets/dashboard/artisan_dashboard.dart';
import 'package:frontend/widgets/dashboard/commercant_dashboard.dart';
import 'package:frontend/widgets/dashboard/admin_dashboard.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  final String userRole;

  const EnhancedDashboardScreen({super.key, required this.userRole});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> {
  final AuthService _authService = AuthService();
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getProfile();
      if (mounted) {
        setState(() {
          _userName = user.name ?? user.email ?? 'Utilisateur';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $_userName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Bienvenue sur votre tableau de bord',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildDashboardForRole(widget.userRole),
      ),
    );
  }

  Widget _buildDashboardForRole(String role) {
    switch (role) {
      case 'client':
        return const ClientDashboard();
      case 'artisan':
        return const ArtisanDashboard();
      case 'commercant':
        return const CommercantDashboard();
      case 'admin':
        return const AdminDashboard();
      default:
        return Center(
          child: Text('Rôle non reconnu : $role'),
        );
    }
  }
}