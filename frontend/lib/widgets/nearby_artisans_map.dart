import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/services/location_service.dart';
import 'package:frontend/services/artisan_service.dart';

class NearbyArtisansMap extends StatefulWidget {
  const NearbyArtisansMap({super.key});

  @override
  State<NearbyArtisansMap> createState() => _NearbyArtisansMapState();
}

class _NearbyArtisansMapState extends State<NearbyArtisansMap> {
  final LocationService _locationService = LocationService();
  final ArtisanService _artisanService = ArtisanService();
  
  List<dynamic> _artisans = [];
  bool _isLoading = true;
  Position? _userPosition;
  String _errorMessage = '';

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

      Position userPosition = await _locationService.getCurrentLocation();
      setState(() {
        _userPosition = userPosition;
        _isLoading = false;
      });

      // Charger les artisans à proximité
      final artisans = await _artisanService.getArtisansByCoordinates(
        userPosition.latitude,
        userPosition.longitude,
        radius: 10.0, // Rayon de 10 km
      );
      
      setState(() {
        _artisans = artisans;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_disabled, size: 60, color: Colors.grey),
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
      );
    }

    if (_userPosition == null) {
      return const Center(
        child: Text('Impossible de déterminer votre position'),
      );
    }

    return FlutterMap(
      options: MapOptions(
        center: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        // Marqueur pour la position de l'utilisateur
        MarkerLayer(
          markers: [
            Marker(
              width: 45.0,
              height: 45.0,
              point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
              builder: (ctx) => const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 45,
              ),
            ),
            // Marqueurs pour les artisans à proximité
            ..._artisans.map((artisan) => Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(
                artisan['latitude']?.toDouble() ?? 0.0,
                artisan['longitude']?.toDouble() ?? 0.0,
              ),
              builder: (ctx) => Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )).toList(),
          ],
        ),
      ],
    );
  }
}