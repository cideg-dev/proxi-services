import 'package:flutter/material.dart';
import 'package:frontend/navigation_service.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/screens/advanced_search_screen.dart';
import 'package:frontend/screens/appointment_booking_screen.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/client_home_screen.dart';
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
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/services/predictive_analysis_service.dart';
import 'package:frontend/services/recommendation_service.dart';
import 'package:frontend/services/referral_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/services/security_service.dart';
import 'package:frontend/services/social_sharing_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/theme_provider.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:frontend/screens/my_groups_screen.dart';
import 'package:frontend/screens/create_group_screen.dart';
import 'package:frontend/widgets/in_app_notification.dart';
import 'package:frontend/widgets/navigation/bottom_navigation_widget.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        color: darkSurface.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface.withOpacity(0.5),
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

    // A more modern light theme to match
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
          },
          onGenerateRoute: (settings) {
            if (settings.name != null && settings.name!.startsWith('/reset-password')) {
              final uri = Uri.parse(settings.name!);
              final token = uri.queryParameters['token'];
              if (token != null) {
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(token: token),
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