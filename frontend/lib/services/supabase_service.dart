// frontend/lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://ufeqnnbokyalwjfskhmw.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmZXFubmJva3lhbHdqZnNraG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NTg0NzAsImV4cCI6MjA3OTEzNDQ3MH0.R9hzOusA0ESMwCrZlmrNTFNgbj4c5YYpexPA4UksLcs';

  final SupabaseClient _client = SupabaseClient(_url, _anonKey);

  SupabaseClient get client => _client;
  
  // MÃ©thode pour s'inscrire
  Future<User?> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    return response.user;
  }

  // MÃ©thode pour se connecter
  Future<User?> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  // MÃ©thode pour se dÃ©connecter
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // MÃ©thode pour rÃ©cupÃ©rer les artisans
  Future<List<Map<String, dynamic>>> getArtisans() async {
    final response = await _client
      .from('users')
      .select('id, role, artisan_profiles (nom_complet, specialite, location, photo_url)')
      .eq('role', 'artisan');
    
    return response;
  }

  // MÃ©thode pour rÃ©cupÃ©rer les avis d'un artisan
  Future<List<Map<String, dynamic>>> getArtisanReviews(int artisanId) async {
    final response = await _client
      .from('reviews')
      .select('id, artisan_id, client_id, rating, comment, created_at')
      .eq('artisan_id', artisanId);
    
    return response;
  }

  // MÃ©thode pour ajouter un avis
  Future<Map<String, dynamic>?> addReview(int artisanId, int rating, String comment) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
      .from('reviews')
      .insert({
        'artisan_id': artisanId,
        'client_id': user.id,
        'rating': rating,
        'comment': comment,
      })
      .select()
      .single();

    return response;
  }
}
