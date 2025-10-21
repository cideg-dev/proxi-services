import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:frontend/widgets/glass_card.dart';

import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/global_professionals_list_screen.dart';

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
    final theme = Theme.of(context);
    final items = _buildDashboardItems(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: AuthService().getProfile(), // Fetch profile to get user's name
                builder: (context, snapshot) {
                  String userName = 'Utilisateur';
                  if (snapshot.hasData && snapshot.data!['profile'] != null) {
                    final profile = snapshot.data!['profile'];
                    if (widget.userRole == 'client' || widget.userRole == 'artisan') {
                      userName = profile['nom_complet'] ?? 'Utilisateur';
                    } else if (widget.userRole == 'commercant') {
                      userName = profile['nom_entreprise'] ?? 'Commerçant';
                    }
                  }
                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(_animationController),
                    child: Text(
                      'Bonjour, $userName !',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16.0),
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeInOut)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un service ou un professionnel...',
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
                ),
                child: Text(
                  'Professionnels en vedette',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Featured professionals/services
              FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _animationController, curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
                ),
                child: SizedBox(
                  height: 200, // Adjust height as needed
                  child: FutureBuilder<List<dynamic>>(
                    future: ArtisanService().getFeaturedProfessionals(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Aucun professionnel en vedette pour le moment.'));
                      }

                      final professionals = snapshot.data!;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: professionals.length,
                        itemBuilder: (context, index) {
                          final professional = professionals[index];
                          return Card(
                            margin: const EdgeInsets.only(right: 16.0),
                            child: SizedBox(
                              width: 150,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: professional['photo_url'] != null
                                        ? NetworkImage('${ApiConstants.baseUrl}${professional['photo_url']}')
                                        : null,
                                    child: professional['photo_url'] == null
                                        ? Text(professional['name'] != null ? professional['name'][0].toUpperCase() : '')
                                        : null,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    professional['name'] ?? 'Inconnu',
                                    style: theme.textTheme.titleSmall,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    professional['specialty_or_type'] ?? '',
                                    style: theme.textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
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
          ),
        ),
      ],
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
            icon: Icons.group,
            title: 'Explorer les Utilisateurs',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalProfessionalsListScreen())),
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
            icon: Icons.group,
            title: 'Explorer les Utilisateurs',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalProfessionalsListScreen())),
          ),
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
            icon: Icons.group,
            title: 'Explorer les Utilisateurs',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GlobalProfessionalsListScreen())),
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