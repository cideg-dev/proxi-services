import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:frontend/widgets/dashboard/dashboard_widgets.dart';
import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/global_professionals_list_screen.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:fl_chart/fl_chart.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  final String userRole;

  const EnhancedDashboardScreen({super.key, required this.userRole});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildRecentPortfolioSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Dernières réalisations',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 220, // Adjust height as needed
          child: FutureBuilder<List<dynamic>>(
            future: ArtisanService().getRecentPortfolioItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aucune réalisation récente.'));
              }

              final portfolioItems = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: portfolioItems.length,
                itemBuilder: (context, index) {
                  final item = portfolioItems[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtisanDetailScreen(artisanId: item['artisan_id']),
                      ),
                    ),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(right: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                child: Image.network(
                                  item['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Réalisation',
                                    style: theme.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['professional_name'] ?? 'Anonyme',
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientDashboard() {
    final stats = [
      {'title': 'Demandes envoyées', 'value': '12', 'subtitle': '+2 cette semaine', 'icon': Icons.assignment, 'color': Colors.blue},
      {'title': 'Artisans favoris', 'value': '5', 'subtitle': 'Dernière visite: hier', 'icon': Icons.favorite, 'color': Colors.red},
      {'title': 'Demandes en cours', 'value': '3', 'subtitle': '2 en attente', 'icon': Icons.pending_actions, 'color': Colors.orange},
      {'title': 'Évaluations reçues', 'value': '8', 'subtitle': 'Moyenne: 4.7/5', 'icon': Icons.star, 'color': Colors.amber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.4,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return StatsCard(
                    title: stat['title'] as String,
                    value: stat['value'] as String,
                    subtitle: stat['subtitle'] as String,
                    icon: stat['icon'] as IconData,
                    iconColor: stat['color'] as Color,
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Graphique des demandes
              const Text(
                'Activité des demandes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ChartCard(
                title: 'Demandes mensuelles',
                icon: Icons.trending_up,
                iconColor: Colors.green,
                chart: LineChartWidget(
                  data: const [
                    FlSpot(0, 4),
                    FlSpot(1, 6),
                    FlSpot(2, 5),
                    FlSpot(3, 8),
                    FlSpot(4, 7),
                    FlSpot(5, 9),
                    FlSpot(6, 6),
                    FlSpot(7, 8),
                    FlSpot(8, 10),
                    FlSpot(9, 7),
                    FlSpot(10, 9),
                    FlSpot(11, 12),
                  ],
                  title: 'Demandes',
                  chartColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // Actions rapides
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              QuickActionCard(
                title: 'Nouvelle demande',
                subtitle: 'Créez une nouvelle demande de service',
                icon: Icons.add_box,
                iconColor: Colors.blue,
                onTap: () {
                  // Navigate to create demand screen
                },
              ),
              const SizedBox(height: 12),
              QuickActionCard(
                title: 'Trouver un artisan',
                subtitle: 'Recherchez un artisan dans votre région',
                icon: Icons.search,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfessionalsListScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildArtisanDashboard() {
    final stats = [
      {'title': 'Demandes reçues', 'value': '24', 'subtitle': '+5 cette semaine', 'icon': Icons.assignment, 'color': Colors.blue},
      {'title': 'Demandes complétées', 'value': '18', 'subtitle': 'Taux: 75%', 'icon': Icons.check_circle, 'color': Colors.green},
      {'title': 'Évaluations reçues', 'value': '15', 'subtitle': 'Moyenne: 4.6/5', 'icon': Icons.star, 'color': Colors.amber},
      {'title': 'Taux de réponse', 'value': '92%', 'subtitle': 'Meilleur que la moyenne', 'icon': Icons.message, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques
              const Text(
                'Statistiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.4,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return StatsCard(
                    title: stat['title'] as String,
                    value: stat['value'] as String,
                    subtitle: stat['subtitle'] as String,
                    icon: stat['icon'] as IconData,
                    iconColor: stat['color'] as Color,
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Graphique de performance
              const Text(
                'Performance mensuelle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ChartCard(
                title: 'Demandes traitées',
                icon: Icons.trending_up,
                iconColor: Colors.green,
                chart: LineChartWidget(
                  data: const [
                    FlSpot(0, 2),
                    FlSpot(1, 4),
                    FlSpot(2, 3),
                    FlSpot(3, 6),
                    FlSpot(4, 5),
                    FlSpot(5, 8),
                    FlSpot(6, 6),
                    FlSpot(7, 7),
                    FlSpot(8, 9),
                    FlSpot(9, 6),
                    FlSpot(10, 8),
                    FlSpot(11, 10),
                  ],
                  title: 'Demandes traitées',
                  chartColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // Actions rapides
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              QuickActionCard(
                title: 'Mes demandes',
                subtitle: 'Gérez les demandes en attente',
                icon: Icons.assignment,
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ArtisanDemandsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              QuickActionCard(
                title: 'Mon portfolio',
                subtitle: 'Ajoutez ou modifiez votre portfolio',
                icon: Icons.photo_library,
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ArtisanPortfolioScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              QuickActionCard(
                title: 'Mes services',
                subtitle: 'Gérez vos services proposés',
                icon: Icons.build,
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ArtisanServicesScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAdminDashboard() {
    final stats = [
      {'title': 'Nouveaux utilisateurs', 'value': '42', 'subtitle': '+8 cette semaine', 'icon': Icons.person_add, 'color': Colors.blue},
      {'title': 'Demandes totales', 'value': '156', 'subtitle': '32 en attente', 'icon': Icons.assignment, 'color': Colors.green},
      {'title': 'Artisans vérifiés', 'value': '89', 'subtitle': 'Taux: 85%', 'icon': Icons.verified, 'color': Colors.amber},
      {'title': 'Taux satisfaction', 'value': '4.7/5', 'subtitle': 'Basé sur 124 évaluations', 'icon': Icons.sentiment_satisfied, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques
              const Text(
                'Statistiques globales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.4,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return StatsCard(
                    title: stat['title'] as String,
                    value: stat['value'] as String,
                    subtitle: stat['subtitle'] as String,
                    icon: stat['icon'] as IconData,
                    iconColor: stat['color'] as Color,
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Graphique d'activité
              const Text(
                'Croissance des utilisateurs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ChartCard(
                title: 'Inscriptions mensuelles',
                icon: Icons.trending_up,
                iconColor: Colors.green,
                chart: LineChartWidget(
                  data: const [
                    FlSpot(0, 12),
                    FlSpot(1, 18),
                    FlSpot(2, 15),
                    FlSpot(3, 22),
                    FlSpot(4, 20),
                    FlSpot(5, 28),
                    FlSpot(6, 25),
                    FlSpot(7, 30),
                    FlSpot(8, 35),
                    FlSpot(9, 29),
                    FlSpot(10, 34),
                    FlSpot(11, 42),
                  ],
                  title: 'Inscriptions',
                  chartColor: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // Actions rapides
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Actions rapides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              QuickActionCard(
                title: 'Panel Admin',
                subtitle: 'Accédez aux outils d\'administration',
                icon: Icons.admin_panel_settings,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              QuickActionCard(
                title: 'Gestion des utilisateurs',
                subtitle: 'Modifiez ou supprimez des utilisateurs',
                icon: Icons.group,
                iconColor: Colors.blue,
                onTap: () {
                  // Navigate to user management
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Show notification panel
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const NotificationPanel(),
                  );
                },
              ),
              if (NotificationService.getUnreadCount() > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      NotificationService.getUnreadCount().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
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
                ],
              ),
            ),
            
            // Afficher le dashboard spécifique selon le rôle
            switch (widget.userRole) {
              'client' => _buildClientDashboard(),
              'artisan' => _buildArtisanDashboard(),
              'commercant' => _buildArtisanDashboard(),
              'admin' => _buildAdminDashboard(),
              _ => const Center(child: Text('Rôle non reconnu')),
            },
            
            // Section récente (commune à tous les rôles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildRecentPortfolioSection(context),
            ),
          ],
        ),
      ),
    );
  }
}