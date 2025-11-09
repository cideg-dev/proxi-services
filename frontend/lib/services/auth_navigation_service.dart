import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/public_home_screen.dart';
import 'package:frontend/services/token_manager.dart';

class AuthNavigationService extends StatefulWidget {
  const AuthNavigationService({super.key});

  @override
  State<AuthNavigationService> createState() => _AuthNavigationServiceState();
}

class _AuthNavigationServiceState extends State<AuthNavigationService> {
  final TokenManager tokenManager = TokenManager();
  String? _token;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final token = await tokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      final role = await tokenManager.getUserRole();
      if (mounted) {
        setState(() {
          _token = token;
          _userRole = role;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _token = null;
          _userRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher la page appropriée en fonction de l'état d'authentification et du rôle
    if (_token != null && _token!.isNotEmpty) {
      // Si l'utilisateur est authentifié, afficher la page d'accueil correspondant à son rôle
      switch (_userRole) {
        case 'client':
          // Importer et retourner l'écran client ici si implémenté
          return const HomeScreen(); // Temporairement HomeScreen, à modifier plus tard
        case 'artisan':
        case 'commercant':
        default:
          return const HomeScreen();
      }
    } else {
      // Si l'utilisateur n'est pas authentifié, afficher la page d'accueil publique
      return const PublicHomeScreen();
    }
  }
}