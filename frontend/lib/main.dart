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

  await dotenv.load(fileName: ".env");

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