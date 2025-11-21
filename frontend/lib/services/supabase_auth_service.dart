// frontend/lib/services/supabase_auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';

class SupabaseAuthService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  // Pour l'instant, nous conservons l'interface similaire à l'ancien service
  // mais avec des appels aux fonctions Supabase
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _functionsService.signin(email: email, password: password);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Note: Avec la solution de correspondance, la fonction signin retourne
      // un objet de session/user de Supabase, pas un token personnalisé
      // Nous devons peut-être gérer cela différemment
      
      // Pour l'instant, supposons que la session contient les infos nécessaires
      final session = data['session'];
      final user = data['user'];
      
      // Pour cette solution, nous stockons les détails de l'utilisateur
      if (user != null) {
        await _tokenManager.persistUserIdentity(
          role: user['role'] as String?,
          email: user['email'] as String?,
        );
      }
      
      return data;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Failed to login';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to login: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role, Map<String, dynamic> profileData, {String? referralCode}) async {
    final response = await _functionsService.signup(
      email: email,
      password: password,
      role: role,
      profileData: profileData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // La fonction signup retourne les données de l'utilisateur créé
      final user = data['user'];
      final profile = data['profile'];
      
      if (user != null) {
        await _tokenManager.persistUserIdentity(
          role: user['role'] as String?,
          email: user['email'] as String?,
        );
      }
      
      return data;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error'] ?? 'Failed to register';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to register: ${response.body}');
      }
    }
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }

  // Les autres méthodes devront être adaptées pour utiliser les fonctions Supabase appropriées
  // ou directement l'API Supabase pour les opérations qui nécessitent une authentification
}