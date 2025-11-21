// frontend/lib/services/supabase_user_service.dart
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:http/http.dart' as http;

class SupabaseUserService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  // Méthode pour enregistrer un utilisateur
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? profileData,
  }) async {
    final response = await _functionsService.signup(
      email: email,
      password: password,
      role: role,
      profileData: profileData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // Méthode pour connecter un utilisateur
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _functionsService.signin(
      email: email,
      password: password,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // Méthode pour déconnecter un utilisateur
  Future<void> logout() async {
    await _tokenManager.clearToken();
  }
}