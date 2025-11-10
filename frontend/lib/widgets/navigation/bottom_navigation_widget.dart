import 'package:flutter/material.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/my_profile_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/screens/enhanced_dashboard_screen.dart';
import 'package:frontend/screens/home_screen.dart';

class BottomNavigationWidget extends StatefulWidget {
  final String userRole;
  final int initialIndex;

  const BottomNavigationWidget({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Écrans pour chaque onglet
  late final List<Widget> _screens;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialiser les écrans en fonction du rôle de l'utilisateur
    _screens = _getScreensForRole(widget.userRole);
  }

  List<Widget> _getScreensForRole(String role) {
    switch (role) {
      case 'client':
        return [
          const EnhancedDashboardScreen(userRole: 'client'),
          const ChatListScreen(),
          const ProfessionalsListScreen(),
          const MyProfileScreen(),
          const SettingsScreen(),
        ];
      case 'artisan':
        return [
          const EnhancedDashboardScreen(userRole: 'artisan'),
          const ChatListScreen(),
          const ArtisanPortfolioScreen(),
          const MyProfileScreen(),
          const SettingsScreen(),
        ];
      case 'commercant':
        return [
          const EnhancedDashboardScreen(userRole: 'commercant'),
          const ChatListScreen(),
          const EnhancedDashboardScreen(userRole: 'commercant'), // Placeholder pour produits/services
          const MyProfileScreen(),
          const SettingsScreen(),
        ];
      case 'admin':
        return [
          const EnhancedDashboardScreen(userRole: 'admin'),
          const EnhancedDashboardScreen(userRole: 'admin'), // Placeholder pour utilisateurs
          const EnhancedDashboardScreen(userRole: 'admin'), // Placeholder pour rapports
          const MyProfileScreen(),
          const SettingsScreen(),
        ];
      default:
        return [
          const EnhancedDashboardScreen(userRole: 'client'),
          const ChatListScreen(),
          const ProfessionalsListScreen(),
          const MyProfileScreen(),
          const SettingsScreen(),
        ];
    }
  }

  Widget _buildPlaceholderScreen(String title, IconData icon, Color color) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Contenu à venir',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(_getIconForRoleAndIndex(widget.userRole, 2)),
            label: _getLabelForRoleAndIndex(widget.userRole, 2),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  IconData _getIconForRoleAndIndex(String role, int index) {
    if (index != 2) return Icons.work; // Default icon

    switch (role) {
      case 'artisan':
        return Icons.photo_library;
      case 'commercant':
        return Icons.store;
      case 'admin':
        return Icons.report;
      default:
        return Icons.work;
    }
  }

  String _getLabelForRoleAndIndex(String role, int index) {
    if (index != 2) return 'Autre';

    switch (role) {
      case 'artisan':
        return 'Portfolio';
      case 'commercant':
        return 'Produits';
      case 'admin':
        return 'Rapports';
      default:
        return 'Services';
    }
  }
}