// frontend/lib/routes/app_routes.dart
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
import 'package:frontend/screens/profile_boost_screen.dart';
import 'package:frontend/services/route_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String registerClient = '/register/client';
  static const String registerArtisan = '/register/artisan';
  static const String registerCommercant = '/register/commercant';
  static const String resetPassword = '/reset-password';
  static const String myProfile = '/my_profile';
  static const String settings = '/settings';
  static const String clientDemands = '/client_demands';
  static const String createDemand = '/create_demand';
  static const String nearbyArtisans = '/nearby_artisans';
  static const String professionalsList = '/professionals_list';
  static const String artisanDetail = '/artisan_detail';
  static const String conversationsList = '/conversations';
  static const String chat = '/chat';
  static const String demandDetail = '/demand_detail';
  static const String advancedSearch = '/advanced_search';
  static const String adminPanel = '/admin_panel';
  static const String artisanDemands = '/artisan_demands';
  static const String artisanPortfolio = '/artisan_portfolio';
  static const String artisanServices = '/artisan_services';
  static const String myGroups = '/my_groups';
  static const String createGroup = '/create_group';
  static const String profileBoost = '/profile_boost';

  // Map des routes statiques
  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterChoiceScreen(),
        registerClient: (context) => const RegisterScreen(role: 'client'),
        registerArtisan: (context) => const RegisterScreen(role: 'artisan'),
        registerCommercant: (context) => const RegisterScreen(role: 'commercant'),
        myProfile: (context) => const MyProfileScreen(),
        settings: (context) => const SettingsScreen(),
        clientDemands: (context) => const ClientDemandsScreen(),
        nearbyArtisans: (context) => const NearbyArtisansScreen(),
        professionalsList: (context) => const ProfessionalsListScreen(),
        conversationsList: (context) => const ConversationsListScreen(),
        adminPanel: (context) => const AdminPanelScreen(),
        artisanDemands: (context) => const ArtisanDemandsScreen(),
        artisanPortfolio: (context) => const ArtisanPortfolioScreen(),
        artisanServices: (context) => const ArtisanServicesScreen(),
        myGroups: (context) => const MyGroupsScreen(),
        profileBoost: (context) => const ProfileBoostScreen(),
      };

  // Méthode pour générer les routes dynamiques
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Routes avec paramètres
      case resetPassword:
        final token = Uri.parse(settings.name!).hasQuery ? Uri.parse(settings.name!).queryParameters['token'] : (args as String?);
        return MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(token: token ?? ''),
        );

      case artisanDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (context) => ArtisanDetailScreen(artisanId: args),
          );
        }
        break;

      case chat:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: args['conversationId'],
              partnerId: args['partnerId'],
              partnerName: args['partnerName'],
            ),
          );
        }
        break;

      case demandDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (context) => DemandDetailScreen(demandId: args),
          );
        }
        break;

      case createDemand:
        if (args is Map<String, dynamic>?) {
          return MaterialPageRoute(
            builder: (context) => CreateDemandScreen(
              artisanId: args?['artisanId'] ?? 0,
              artisanName: args?['artisanName'] ?? 'Artisan',
              selectedService: args?['selectedService'],
            ),
          );
        }
        break;

      case advancedSearch:
        return MaterialPageRoute(
          builder: (context) => const AdvancedSearchScreen(),
        );

      case createGroup:
        return MaterialPageRoute(
          builder: (context) => const CreateGroupScreen(),
        );
    }

    return null;
  }

  // Méthode pour vérifier si une route nécessite une authentification
  static bool requiresAuth(String routeName) {
    return ![
      login,
      register,
      registerClient,
      registerArtisan,
      registerCommercant,
      resetPassword,
    ].contains(routeName);
  }

  // Méthode pour vérifier les permissions de rôle
  static Future<bool> checkPermissions(String routeName) async {
    final routeGuard = RouteGuard();
    
    if (routeName.startsWith(adminPanel) && !(await routeGuard.hasRole(['admin']))) {
      return false;
    }
    
    if ((routeName.startsWith(artisanDemands) || 
         routeName.startsWith(artisanPortfolio) || 
         routeName.startsWith(artisanServices)) && 
        !(await routeGuard.hasAnyRole(['artisan', 'commercant']))) {
      return false;
    }
    
    if (routeName.startsWith(clientDemands) && !(await routeGuard.hasRole(['client']))) {
      return false;
    }
    
    return true;
  }
}