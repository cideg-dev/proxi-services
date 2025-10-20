import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:frontend/widgets/glass_card.dart';

import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;

  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildDashboardItems(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
      ),
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Staggered animation for each item
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (1 / items.length) * index,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: items[index],
          ),
        );
      },
    );
  }

  List<Widget> _buildDashboardItems(BuildContext context) {
    List<DashboardItem> items = [];

    switch (widget.userRole) {
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

class DashboardItem extends StatefulWidget {
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
  State<DashboardItem> createState() => _DashboardItemState();
}

class _DashboardItemState extends State<DashboardItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovering ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        child: GlassCard(
          onTap: widget.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, size: 48.0, color: theme.colorScheme.primary),
              const SizedBox(height: 12.0),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}