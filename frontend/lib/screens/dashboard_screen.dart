import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';

import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: _buildDashboardItems(context),
    );
  }

  List<Widget> _buildDashboardItems(BuildContext context) {
    List<DashboardItem> items = [];

    switch (userRole) {
      case 'client':
        items = [
          DashboardItem(
            icon: Icons.search,
            title: 'Parcourir les artisans',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfessionalsListScreen())),
          ),

          DashboardItem(
            icon: Icons.person,
            title: 'Mon Profil',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          DashboardItem(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
          ),
        ];
        break;
      case 'artisan':
      case 'commercant':
        items = [
          DashboardItem(
            icon: Icons.dashboard,
            title: 'Mes Demandes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArtisanDemandsScreen())),
          ),
          DashboardItem(
            icon: Icons.person,
            title: 'Mon Profil',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          DashboardItem(
            icon: Icons.build,
            title: 'Mes Services',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArtisanServicesScreen())),
          ),
          DashboardItem(
            icon: Icons.photo_library,
            title: 'Mon Portfolio',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArtisanPortfolioScreen())),
          ),
          DashboardItem(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
          ),
        ];
        break;
      case 'admin':
        items = [
          DashboardItem(
            icon: Icons.admin_panel_settings,
            title: 'Panel Admin',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen())),
          ),
          DashboardItem(
            icon: Icons.search,
            title: 'Parcourir les artisans',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfessionalsListScreen())),
          ),
          DashboardItem(
            icon: Icons.chat,
            title: 'Messages',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListScreen())),
          ),
        ];
        break;
    }

    return items;
  }
}

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DashboardItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}