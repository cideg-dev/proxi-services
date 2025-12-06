import 'package:geolocator/geolocator.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/artisan_service.dart';
import 'package:frontend/models/artisan_model.dart';

class LocationService {
  final ApiService _apiService = ApiService();
  final ArtisanService _artisanService = ArtisanService();

  /// Vérifie si la localisation est activée sur l'appareil
  Future<bool> isLocationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Récupère la position actuelle de l'utilisateur
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Service de localisation désactivé');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission de localisation refusée définitivement');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    );
  }

  /// Calcule la distance entre deux coordonnées en kilomètres
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convertir en km
  }

  /// Récupère les artisans les plus proches de l'utilisateur
  Future<List<Artisan>> getNearbyArtisans({double? radius = 10.0}) async {
    try {
      Position position = await getCurrentLocation();
      
      final response = await _apiService.getPublic(
        '/api/artisans/nearby?lat=${position.latitude}&lng=${position.longitude}&radius=${radius ?? 10.0}'
      );

      if (response.statusCode == 200) {
        final List<Artisan> artisans = await _artisanService.getArtisans();
        final List<Artisan> nearbyArtisans = [];

        // Calculer la distance pour chaque artisan et filtrer selon le rayon
        for (var artisan in artisans) {
          if (artisan.latitude != null && artisan.longitude != null) {
            double distance = calculateDistance(
              position.latitude,
              position.longitude,
              artisan.latitude!,
              artisan.longitude!,
            );

            if (distance <= (radius ?? 10.0)) {
              nearbyArtisans.add(artisan);
            }
          }
        }

        // Trier par distance (re-calculating since we didn't store it)
        nearbyArtisans.sort((a, b) {
          double distA = calculateDistance(position.latitude, position.longitude, a.latitude!, a.longitude!);
          double distB = calculateDistance(position.latitude, position.longitude, b.latitude!, b.longitude!);
          return distA.compareTo(distB);
        });

        return nearbyArtisans;
      } else {
        throw Exception('Échec de la récupération des artisans à proximité');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des artisans à proximité: $e');
    }
  }

  /// Récupère la position de l'utilisateur et formatte pour l'affichage
  Future<Map<String, dynamic>> getUserLocationInfo() async {
    try {
      Position position = await getCurrentLocation();
      
      // Pour l'instant, on retourne les coordonnées brutes
      // L'implémentation complète de la conversion en adresse peut nécessiter une API externe
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': 'Coordonnées GPS',
        'formatted_address': '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}'
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des informations de localisation: $e');
    }
  }
}