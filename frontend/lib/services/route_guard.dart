import 'package:frontend/services/token_manager.dart';

/// Service pour gérer la protection des routes et le contrôle d'accès basé sur les rôles
class RouteGuard {
  final TokenManager _tokenManager = TokenManager();

  // Singleton pattern
  static final RouteGuard _instance = RouteGuard._internal();
  factory RouteGuard() => _instance;
  RouteGuard._internal();

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _tokenManager.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Vérifie si l'utilisateur a le rôle requis
  Future<bool> hasRole(List<String> allowedRoles) async {
    if (!await isAuthenticated()) {
      return false;
    }

    final userRole = await _tokenManager.getUserRole();
    if (userRole == null) {
      return false;
    }

    return allowedRoles.contains(userRole);
  }

  /// Vérifie si l'utilisateur a l'un des rôles requis
  Future<bool> hasAnyRole(List<String> allowedRoles) async {
    return await hasRole(allowedRoles);
  }

  /// Obtient le rôle de l'utilisateur actuel
  Future<String?> getUserRole() async {
    if (!await isAuthenticated()) {
      return null;
    }
    return await _tokenManager.getUserRole();
  }

  /// Obtient l'ID de l'utilisateur actuel
  Future<int?> getUserId() async {
    if (!await isAuthenticated()) {
      return null;
    }
    return await _tokenManager.getUserId();
  }
}
