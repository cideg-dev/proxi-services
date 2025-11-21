// frontend/lib/services/supabase_artisan_service.dart
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;

class SupabaseArtisanService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getArtisans() async {
    final response = await _functionsService.getArtisans();
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load artisans: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getArtisanById(int id) async {
    // Pour récupérer un artisan spécifique, nous devons filtrer la liste
    final artisans = await getArtisans();
    final artisan = artisans.firstWhere(
      (element) => element['id'] == id,
      orElse: () => throw Exception('Artisan not found'),
    );
    return artisan;
  }

  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await _functionsService.getArtisanReviews(artisanId);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews: ${response.body}');
    }
  }

  // Autres méthodes qui peuvent être adaptées selon les besoins
}