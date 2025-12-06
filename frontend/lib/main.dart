import 'package:flutter/material.dart';
import 'package:frontend/navigation_service.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/screens/advanced_search_screen.dart';
import 'package:frontend/screens/appointment_booking_screen.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/conversations_list_screen.dart';
import 'package:frontend/screens/integration_test_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/merchants_screen.dart';
import 'package:frontend/screens/nearby_artisans_screen.dart';
import 'package:frontend/screens/payment_screen.dart';
import 'package:frontend/screens/public_home_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/analytics_service.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/auth_navigation_service.dart';
import 'package:frontend/services/badge_service.dart';
import 'package:frontend/services/content_service.dart';
import 'package:frontend/services/identity_verification_service.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:frontend/services/loyalty_service.dart';
import 'package:frontend/services/moderation_service.dart';
import 'package:frontend/services/offline_mode_service.dart';
import 'package:frontend/services/performance_service.dart';
import 'package:frontend/services/predictive_analysis_service.dart';
import 'package:frontend/services/recommendation_service.dart';
import 'package:frontend/services/referral_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/services/security_service.dart';
import 'package:frontend/services/social_sharing_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/theme_provider.dart';
import 'package:frontend/services/route_guard.dart';
import 'package:frontend/screens/my_groups_screen.dart';
import 'package:frontend/screens/create_group_screen.dart';
import 'package:frontend/widgets/in_app_notification.dart';
import 'package:frontend/widgets/navigation/bottom_navigation_widget.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/screens/artisan_demands_screen.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/client_demands_screen.dart';
import 'package:frontend/screens/professionals_list_screen.dart';
import 'package:frontend/screens/profile_boost_screen.dart';
import 'package:frontend/screens/register_choice_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/screens/artisan_detail_screen.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/demand_detail_screen.dart';
import 'package:frontend/screens/create_demand_screen.dart';
import 'package:frontend/screens/kkiapay_webview_screen.dart';
import 'package:frontend/screens/my_profile_screen.dart';
import 'package:frontend/screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SocketService()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationUIProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _notificationSubscription;
  final RouteGuard _routeGuard = RouteGuard();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      final notificationProvider = Provider.of<NotificationUIProvider>(context, listen: false);

      _notificationSubscription = socketService.notifications.listen((data) {
        notificationProvider.showNotification(
          NotificationData(
            title: data['senderName'] ?? 'Nouvelle Notification',
            message: data['message'] ?? 'Vous avez un nouveau message.',
            icon: Icons.message,
            color: Theme.of(context).primaryColor,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    Provider.of<SocketService>(context, listen: false).disconnect();
    super.dispose();
  }

  // Widget pour afficher un message d'accès refusé
  Widget _buildAccessDeniedScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès Refusé')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(NavigationService.navigatorKey.currentContext!).pushReplacementNamed('/login'),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNeon = Color(0xFF00FFC2);
    const secondaryNeon = Color(0xFFFF6EC7);
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);

    final baseDarkTheme = ThemeData.dark(useMaterial3: true);
    final darkTheme = baseDarkTheme.copyWith(
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryNeon,
      colorScheme: baseDarkTheme.colorScheme.copyWith(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: darkSurface,
        onSurface: Colors.white,
        background: darkBackground,
        onBackground: Colors.white,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      cardColor: darkSurface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryNeon, width: 2.0),
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNeon,
          textStyle: GoogleFonts.poppins(),
        ),
      ),
    );

    final baseLightTheme = ThemeData.light(useMaterial3: true);
    final lightTheme = baseLightTheme.copyWith(
      primaryColor: primaryNeon,
      colorScheme: baseLightTheme.colorScheme.copyWith(
        primary: primaryNeon,
        secondary: secondaryNeon,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(baseLightTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
           textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Proxi-Services',
          navigatorKey: NavigationService.navigatorKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const Scaffold(
            body: Stack(
              children: [
                AuthNavigationService(),
                InAppNotification(),
              ],
            ),
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/my_groups': (context) => const MyGroupsScreen(),
            '/create_group': (context) => const CreateGroupScreen(),
            '/advanced_search': (context) => const AdvancedSearchScreen(),
            '/client_demands': (context) => const ClientDemandsScreen(),
            '/conversations': (context) => const ConversationsListScreen(),
            '/professionals_list': (context) => const ProfessionalsListScreen(),
            '/nearby_artisans': (context) => const NearbyArtisansScreen(),
            '/profile_boost': (context) => const ProfileBoostScreen(),
            '/register': (context) => const RegisterChoiceScreen(),
            '/register/client': (context) => const RegisterScreen(role: 'client'),
            '/register/artisan': (context) => const RegisterScreen(role: 'artisan'),
            '/register/commercant': (context) => const RegisterScreen(role: 'commercant'),
            '/artisan_portfolio': (context) => const ArtisanPortfolioScreen(),
            '/artisan_services': (context) => const ArtisanServicesScreen(),
            '/artisan_demands': (context) => const ArtisanDemandsScreen(),
            '/admin_panel': (context) => const AdminPanelScreen(),
            '/my_profile': (context) => const MyProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
          onGenerateRoute: (settings) async {
            // Routes publiques (pas besoin d'authentification)
            final publicRoutes = [
              '/login',
              '/register',
              '/register/client',
              '/register/artisan',
              '/register/commercant',
            ];

            // Si c'est une route publique, autoriser directement
            if (settings.name != null && publicRoutes.contains(settings.name)) {
              return null; // Laisse le système utiliser les routes définies
            }

            // Routes avec arguments spéciaux
            if (settings.name != null) {
              final uri = Uri.parse(settings.name!);
              
              // Reset password - Route publique
              if (settings.name!.startsWith('/reset-password')) {
                final token = uri.queryParameters['token'];
                if (token != null) {
                  return MaterialPageRoute(
                    builder: (context) => ResetPasswordScreen(token: token),
                  );
                }
              }

              // Routes protégées par authentification
              final isAuth = await _routeGuard.isAuthenticated();
              
              if (!isAuth) {
                // Rediriger vers login si non authentifié
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              }

              // Obtenir le rôle de l'utilisateur
              final userRole = await _routeGuard.getUserRole();

              // Routes avec contrôle d'accès basé sur les rôles
              if (settings.name!.startsWith('/admin_panel')) {
                if (userRole != 'admin') {
                  return MaterialPageRoute(
                    builder: (context) => _buildAccessDeniedScreen(
                      'Seuls les administrateurs peuvent accéder à cette page.',
                    ),
                  );
                }
              }

              if (settings.name!.startsWith('/artisan_portfolio') ||
                  settings.name!.startsWith('/artisan_services') ||
                  settings.name!.startsWith('/artisan_demands')) {
                if (userRole != 'artisan' && userRole != 'commercant') {
                  return MaterialPageRoute(
                    builder: (context) => _buildAccessDeniedScreen(
                      'Cette page est réservée aux artisans et commerçants.',
                    ),
                  );
                }
              }

              if (settings.name!.startsWith('/client_demands')) {
                if (userRole != 'client') {
                  return MaterialPageRoute(
                    builder: (context) => _buildAccessDeniedScreen(
                      'Cette page est réservée aux clients.',
                    ),
                  );
                }
              }

              // Routes avec arguments
              if (settings.name!.startsWith('/artisan_detail')) {
                final args = settings.arguments;
                if (args is int) {
                  return MaterialPageRoute(
                    builder: (context) => ArtisanDetailScreen(artisanId: args),
                  );
                }
              }

              if (settings.name!.startsWith('/chat')) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: args['conversationId'],
                    partnerId: args['partnerId'],
                    partnerName: args['partnerName'],
                  ),
                );
              }

              if (settings.name!.startsWith('/demand_detail')) {
                final args = settings.arguments;
                if (args is int) {
                  return MaterialPageRoute(
                    builder: (context) => DemandDetailScreen(demandId: args),
                  );
                }
              }

              if (settings.name!.startsWith('/create_demand')) {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => CreateDemandScreen(
                    artisanId: args?['artisanId'] ?? 0,
                    artisanName: args?['artisanName'] ?? 'Artisan',
                    selectedService: args?['selectedService'],
                  ),
                );
              }
            }
            
            return null;
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}