import 'package:flutter/material.dart';
import 'package:frontend/services/navigation_service.dart'; // Mise à jour pour utiliser le nouveau service
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
// Services à commenter temporairement pour le build
// import 'package:frontend/services/analytics_service.dart';
// import 'package:frontend/services/ai_service.dart';
// import 'package:frontend/services/badge_service.dart';
// import 'package:frontend/services/content_service.dart';
// import 'package:frontend/services/identity_verification_service.dart';
// import 'package:frontend/services/loyalty_service.dart';
// import 'package:frontend/services/moderation_service.dart';
// import 'package:frontend/services/offline_mode_service.dart';
// import 'package:frontend/services/predictive_analysis_service.dart';
// import 'package:frontend/services/recommendation_service.dart';
// import 'package:frontend/services/referral_service.dart';
// import 'package:frontend/services/social_sharing_service.dart';
// import 'package:frontend/services/localization_service.dart';
// import 'package:frontend/services/performance_service.dart';

import 'package:frontend/services/auth_navigation_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/services/security_service.dart';
// import 'package:frontend/services/socket_service.dart'; // Déjà géré conditionnellement
import 'package:frontend/services/theme_provider.dart';
import 'package:frontend/services/route_guard.dart';
// Services à commenter temporairement pour le build
// import 'package:frontend/services/advanced_search_service.dart';
// import 'package:frontend/services/appointment_service.dart';
// import 'package:frontend/services/demand_service.dart';
// import 'package:frontend/services/admin_service.dart';
// import 'package:frontend/services/dashboard_service.dart';
// import 'package:frontend/services/demacheur_service.dart';
// import 'package:frontend/services/location_service.dart';
// import 'package:frontend/services/notification_service.dart';
// import 'package:frontend/services/payment_service.dart';
// import 'package:frontend/services/qa_service.dart';
import 'package:frontend/screens/my_groups_screen.dart';
import 'package:frontend/screens/create_group_screen.dart';
import 'package:frontend/widgets/in_app_notification.dart';
import 'package:frontend/widgets/navigation/bottom_navigation_widget.dart';
import 'package:frontend/routes/app_routes.dart'; // Importer les routes centralisées
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
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NotificationUIProvider()),
        // Plus de providers pour le moment pour permettre le build
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
      // SocketService est désactivé pour permettre le build
      // Pourrait être réactivé dans une version ultérieure
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
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
          routes: AppRoutes.routes, // Utiliser les routes centralisées
          onGenerateRoute: AppRoutes.onGenerateRoute, // Utiliser le gestionnaire de routes centralisé
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}