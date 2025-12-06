import 'package:flutter/material.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/widgets/nearby_artisans_map.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';
import 'package:frontend/models/artisan_model.dart';
import 'package:geolocator/geolocator.dart'; // For distance calculation

class NearbyArtisansScreen extends StatefulWidget {
  const NearbyArtisansScreen({super.key});

  @override
  State<NearbyArtisansScreen> createState() => _NearbyArtisansScreenState();
}

class _NearbyArtisansScreenState extends State<NearbyArtisansScreen> {
  final LocationService _locationService = LocationService();
  final ArtisanService _artisanService = ArtisanService();
  
  List<Artisan> _artisans = [];
  bool _isLoading = true;
  bool _showMap = true; // Pour basculer entre carte et liste
  String _errorMessage = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadNearbyArtisans();
  }

  Future<void> _loadNearbyArtisans() async {
    try {
      bool isLocationEnabled = await _locationService.isLocationEnabled();
      if (!isLocationEnabled) {
        setState(() {
          _errorMessage = 'Veuillez activer la localisation sur votre appareil';
          _isLoading = false;
        });
        return;
      }

      final position = await _locationService.getCurrentLocation();
      final artisans = await _locationService.getNearbyArtisans();
      
      setState(() {
        _currentPosition = position;
        _artisans = artisans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des artisans: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisans à proximité'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Voir en liste' : 'Voir sur la carte',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNearbyArtisans,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Barre de recherche et filtres
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un artisan...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    // Boutons pour basculer entre carte et liste
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _showMap = true),
                              style: ButtonStyle(
                                backgroundColor: _showMap
                                    ? MaterialStateProperty.all<Color>(theme.colorScheme.primary.withValues(alpha: 0.2))
                                    : MaterialStateProperty.all<Color>(Colors.transparent),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              child: const Text('Carte'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _showMap = false),
                              style: ButtonStyle(
                                backgroundColor: !_showMap
                                    ? MaterialStateProperty.all<Color>(theme.colorScheme.primary.withValues(alpha: 0.2))
                                    : MaterialStateProperty.all<Color>(Colors.transparent),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              child: const Text('Liste'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Affichage carte ou liste
                    Expanded(
                      child: _showMap
                          ? NearbyArtisansMap()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _artisans.length,
                              itemBuilder: (context, index) {
                                final artisan = _artisans[index];
                                return _buildArtisanCard(artisan, theme);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildArtisanCard(Artisan artisan, ThemeData theme) {
    double distance = 0.0;
    if (_currentPosition != null && artisan.latitude != null && artisan.longitude != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        artisan.latitude!,
        artisan.longitude!,
      ) / 1000;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(
            Icons.store,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(artisan.name ?? artisan.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artisan.specialty ?? 'Spécialité non spécifiée',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 16,
            ),
            Text(
              (artisan.averageRating ?? 0.0).toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        onTap: () {
          // Naviguer vers le détail de l'artisan
          Navigator.pushNamed(
            context,
            '/artisan_detail',
            arguments: artisan.id,
          );
        },
      ),
    );
  }
}