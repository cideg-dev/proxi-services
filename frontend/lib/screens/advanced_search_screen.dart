import 'package:flutter/material.dart';
import 'package:frontend/services/advanced_search_service.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/services/merchant_service.dart';
import 'package:frontend/widgets/advanced_search_bar.dart';
import 'package:frontend/widgets/search_filters.dart';
import 'package:frontend/widgets/star_rating.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final ArtisanService _artisanService = ArtisanService();
  final MerchantService _merchantService = MerchantService();
  
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  int _currentPage = 1;
  bool _hasMoreResults = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche Avancée'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche avancée
          AdvancedSearchBar(
            onSearch: _performSearch,
            hintText: 'Rechercher artisans, commerçants...',
          ),
          
          // Résultats de recherche
          Expanded(
            child: _isLoading && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Entrez un terme de recherche pour commencer'
                                  : 'Aucun résultat trouvé pour "$_searchQuery"',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (_searchQuery.isNotEmpty) {
                            await _performSearch(_searchQuery, _filters);
                          }
                        },
                        child: ListView.builder(
                          itemCount: _results.length + (_hasMoreResults ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _results.length) {
                              // Élément de chargement pour la pagination
                              return _hasMoreResults
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final item = _results[index];
                            return _buildResultCard(item, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic item, ThemeData theme) {
    final isArtisan = item.containsKey('specialty'); // Supposition basée sur la structure
    final name = item['name'] ?? item['email'] ?? (isArtisan ? 'Artisan' : 'Commerçant');
    final rating = (item['rating'] ?? item['average_rating'] ?? 0.0).toDouble();
    final specialty = item['specialty'] ?? item['business_type'] ?? 'Inconnu';
    final distance = item['distance'] != null ? '${item['distance'].toStringAsFixed(2)} km' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(
            isArtisan ? Icons.build : Icons.store,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              specialty,
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StarRating(
                  rating: rating,
                  allowHalfRating: true,
                  allowEditing: false,
                ),
                const SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: theme.textTheme.bodySmall,
                ),
                if (distance.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.location_on,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          // Naviguer vers le détail selon le type
          if (isArtisan) {
            Navigator.pushNamed(
              context,
              '/artisan_detail',
              arguments: item['id'],
            );
          } else {
            // Pour les commerçants, vous pouvez créer un écran similaire
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => MerchantDetailScreen(merchantId: item['id']),
            //   ),
            // );
          }
        },
      ),
    );
  }

  Future<void> _performSearch(String query, Map<String, dynamic> filters) async {
    setState(() {
      _searchQuery = query;
      _filters = filters;
      _isLoading = true;
      if (query.isEmpty) {
        _results = [];
      }
    });

    if (query.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Effectuer la recherche globale
      final results = await _searchService.globalSearch(
        query: query,
        minRating: filters['minRating']?.toDouble(),
        category: filters['category'] ?? filters['specialty'],
      );

      setState(() {
        _results = [
          ...results['artisans'] ?? [],
          ...results['merchants'] ?? [],
        ];
        _isLoading = false;
        _hasMoreResults = false; // Pour cette implémentation simple
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche: $e')),
      );
    }
  }
}