// frontend/lib/services/navigation_service.dart
import 'package:flutter/material.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/my_profile_screen.dart';
import 'package:frontend/screens/register_choice_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/screens/reset_password_screen.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/demand_detail_screen.dart';
import 'package:frontend/screens/create_demand_screen.dart';
import 'package:frontend/screens/conversations_list_screen.dart';
import 'package:frontend/screens/nearby_artisans_screen.dart';
import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/screens/my_groups_screen.dart';
import 'package:frontend/screens/create_group_screen.dart';
import 'package:frontend/screens/advanced_search_screen.dart';

// Enumération des routes nommées
enum AppRoute {
  // Routes publiques
  login('/login'),
  register('/register'),
  registerClient('/register/client'),
  registerArtisan('/register/artisan'),
  registerCommercant('/register/commercant'),
  resetPassword('/reset-password'),

  // Routes protégées - Tableau de bord et base
  home('/home'),
  dashboard('/dashboard'),
  myProfile('/my_profile'),
  settings('/settings'),

  // Routes spécifiques aux clients
  clientDemands('/client_demands'),
  createDemand('/create_demand'),
  nearbyArtisans('/nearby_artisans'),
  professionalsList('/professionals_list'),
  artisanDetail('/artisan_detail'),
  conversationsList('/conversations'),
  chat('/chat'),
  demandDetail('/demand_detail'),
  advancedSearch('/advanced_search'),

  // Routes spécifiques aux artisans
  artisanDemands('/artisan_demands'),
  artisanPortfolio('/artisan_portfolio'),
  artisanServices('/artisan_services'),

  // Routes spécifiques aux commerçants
  merchantProducts('/merchant_products'),

  // Routes spécifiques aux admins
  adminPanel('/admin_panel'),
  adminUsers('/admin_users'),
  adminReports('/admin_reports'),

  // Autres routes
  myGroups('/my_groups'),
  createGroup('/create_group');

  const AppRoute(this.path);
  final String path;

  // Constructeur pour créer une route avec paramètres
  String withParams(Map<String, String> params) {
    final paramString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$path?${paramString.isNotEmpty ? paramString : ''}';
  }
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Liste des routes publiques (ne nécessitant pas d'authentification)
  static const List<String> publicRoutes = [
    '/login',
    '/register',
    '/register/client',
    '/register/artisan',
    '/register/commercant',
    '/reset-password',
  ];

  // Liste des routes réservées aux administrateurs
  static const List<String> adminOnlyRoutes = [
    '/admin_panel',
    '/admin_users',
    '/admin_reports',
  ];

  // Liste des routes réservées aux artisans et commerçants
  static const List<String> artisanOnlyRoutes = [
    '/artisan_demands',
    '/artisan_portfolio',
    '/artisan_services',
  ];

  // Liste des routes réservées aux clients
  static const List<String> clientOnlyRoutes = [
    '/client_demands',
  ];

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushNamed<T>(routeName, arguments: arguments);
    }
    return null;
  }

  static Future<T?> pushReplacementNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushReplacementNamed<T>(routeName, arguments: arguments);
    }
    return null;
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
    required RoutePredicate predicate,
  }) {
    final state = navigatorKey.currentState;
    if (state != null) {
      return state.pushNamedAndRemoveUntil<T>(routeName, predicate, arguments: arguments);
    }
    return null;
  }

  static bool pop<T extends Object?>([T? result]) {
    final state = navigatorKey.currentState;
    if (state != null) {
      state.pop(result);
      return true;
    }
    return false;
  }

  // Méthode pour naviguer vers une route avec vérification d'accès
  static Future<bool> navigateToRoute(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    // Si c'est une route publique, naviguer directement
    if (publicRoutes.contains(routeName)) {
      return await pushNamed(routeName, arguments: arguments) ?? false;
    }

    // Vérifier l'authentification
    final token = await TokenManager().getToken();
    if (token == null || token.isEmpty) {
      // Rediriger vers la page de login si non authentifié
      await pushReplacementNamed('/login');
      return false;
    }

    // Récupérer le rôle de l'utilisateur
    final userRole = await TokenManager().getUserRole();

    // Vérifier si la route est réservée aux administrateurs
    if (adminOnlyRoutes.contains(routeName) && userRole != 'admin') {
      // Afficher un message d'accès refusé
      _showAccessDenied(context, 'Accès réservé aux administrateurs');
      return false;
    }

    // Vérifier si la route est réservée aux artisans
    if (artisanOnlyRoutes.contains(routeName) && userRole != 'artisan' && userRole != 'commercant') {
      _showAccessDenied(context, 'Accès réservé aux artisans et commerçants');
      return false;
    }

    // Vérifier si la route est réservée aux clients
    if (clientOnlyRoutes.contains(routeName) && userRole != 'client') {
      _showAccessDenied(context, 'Accès réservé aux clients');
      return false;
    }

    // Toutes les vérifications passées, naviguer vers la route
    return await pushNamed(routeName, arguments: arguments) ?? false;
  }

  // Méthode pour afficher un message d'accès refusé
  static void _showAccessDenied(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accès refusé'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}