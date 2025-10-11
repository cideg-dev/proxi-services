import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/navigation_service.dart';
import 'package:frontend/providers/notification_ui_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/theme_provider.dart';
import 'package:frontend/screens/my_groups_screen.dart';
import 'package:frontend/screens/create_group_screen.dart';
import 'package:frontend/widgets/in_app_notification.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement depuis assets/app.env si présent.
  // Si le fichier est absent (ex: build ou déploiement mal fait), attraper l'erreur
  // et fournir des valeurs par défaut afin d'éviter un crash lors du démarrage.
  try {
    await dotenv.load(fileName: "assets/app.env");
  } catch (e, st) {
    // Log pour debug local; ne pas interrompre l'exécution en prod.
    // L'erreur la plus fréquente ici est FileNotFoundError lors du chargement web.
    // Exemple de message attendu dans les logs du navigateur : FileNotFoundError
    // Remplir des valeurs par défaut raisonnables.
    print('Warning: impossible de charger assets/app.env: $e');
    // Print stack trace for debugging (uses the caught stack trace variable)
    print(st);
    // Fournir des valeurs par défaut si elles n'existent pas
    try {
      if (dotenv.env['API_URL'] == null) dotenv.env['API_URL'] = 'http://localhost:3000';
      if (dotenv.env['FRONTEND_URL'] == null) dotenv.env['FRONTEND_URL'] = 'http://localhost:5173';
    } catch (_) {
      // Si dotenv.env n'est pas modifiable pour une raison quelconque, on ignore.
    }
  }

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
    // It's better to initialize listeners where context is available and after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      final notificationProvider = Provider.of<NotificationUIProvider>(context, listen: false);

      // Listen to notifications from the socket service
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Proxi-Services',
          navigatorKey: NavigationService.navigatorKey,
          theme: themeProvider.currentTheme,
          home: const Scaffold(
            body: Stack(
              children: [
                SplashScreen(), // Your initial screen
                InAppNotification(), // Overlay notification widget
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