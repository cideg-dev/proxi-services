import 'package:flutter/material.dart';
import 'package:frontend/screens/advanced_search_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/merchants_screen.dart';
import 'package:frontend/screens/nearby_artisans_screen.dart';
import 'package:frontend/screens/register_choice_screen.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/merchant_service.dart';
import 'package:frontend/services/api_constants.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:frontend/widgets/glass_card.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({super.key});

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final ArtisanService _artisanService = ArtisanService();
  final MerchantService _merchantService = MerchantService();
  final TokenManager _tokenManager = TokenManager();

  late Future<List<dynamic>> _featuredArtisansFuture;
  late Future<List<dynamic>> _featuredMerchantsFuture;

  @override
  void initState() {
    super.initState();
    _featuredArtisansFuture = _fetchFeaturedArtisans();
    _featuredMerchantsFuture = _fetchFeaturedMerchants();
  }

  Future<List<dynamic>> _fetchFeaturedArtisans() async {
    try {
      // Récupérer les artisans avec leurs portfolios
      return await _artisanService.getAllArtisansWithPortfolio();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des artisans: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchFeaturedMerchants() async {
    try {
      // Récupérer les commerçants mis en avant
      return await _merchantService.getFeaturedMerchants();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des commerçants: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barre de navigation supérieure
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proxi-Services',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text('Connexion'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterChoiceScreen()),
                            );
                          },
                          child: const Text('Inscription'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Section d'introduction
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Trouvez les meilleurs artisans et commerçants près de chez vous',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous avec des professionnels de confiance pour tous vos besoins.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Barre de recherche avancée
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher artisans, commerçants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      // Naviguer vers l'écran de recherche avancée avec la requête
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvancedSearchScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),

              // Section des artisans en vedette
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Artisans en Vedette',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Naviguer vers la liste complète des artisans à proximité
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NearbyArtisansScreen()),
                        );
                      },
                      child: const Text('Voir plus'),
                    ),
                  ],
                ),
              ),
              
              // Affichage des artisans
              Expanded(
                flex: 1,
                child: FutureBuilder<List<dynamic>>(
                  future: _featuredArtisansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Aucun artisan trouvé.'));
                    }

                    final artisans = snapshot.data!;
                    // Calculer le nombre de colonnes en fonction de la largeur de l'écran
                    int crossAxisCount = screenWidth > 700 ? 3 : 2;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: artisans.length > 6 ? 6 : artisans.length,
                        itemBuilder: (context, index) {
                          final artisan = artisans[index];
                          return _buildArtisanCard(artisan);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Section des commerçants en vedette
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commerçants en Vedette',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Naviguer vers la liste complète des commerçants
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MerchantsScreen()),
                        );
                      },
                      child: const Text('Voir plus'),
                    ),
                  ],
                ),
              ),

              // Affichage des commerçants
              Expanded(
                flex: 1,
                child: FutureBuilder<List<dynamic>>(
                  future: _featuredMerchantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Aucun commerçant trouvé.'));
                    }

                    final merchants = snapshot.data!;
                    // Calculer le nombre de colonnes en fonction de la largeur de l'écran
                    int crossAxisCount = screenWidth > 700 ? 3 : 2;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: merchants.length > 6 ? 6 : merchants.length,
                        itemBuilder: (context, index) {
                          final merchant = merchants[index];
                          return _buildMerchantCard(merchant);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanCard(dynamic artisan) {
    final theme = Theme.of(context);
    final portfolioItems = artisan['portfolio'] ?? [];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image de portfolio (première image ou image par défaut)
          Expanded(
            flex: 2,
            child: portfolioItems.isNotEmpty
                ? Image.network(
                    portfolioItems[0]['image_url'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.store, size: 40),
                  ),
          ),
          // Informations sur l'artisan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    artisan['name'] ?? artisan['email'] ?? 'Artisan',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artisan['specialty'] ?? 'Spécialité',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (artisan['rating'] ?? 'N/A').toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(dynamic merchant) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image du commerçant ou de ses produits
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surfaceVariant,
              child: const Icon(Icons.store, size: 40),
            ),
          ),
          // Informations sur le commerçant
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    merchant['name'] ?? merchant['email'] ?? 'Commerçant',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    merchant['business_type'] ?? 'Type de commerce',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (merchant['rating'] ?? 'N/A').toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}