import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/chat_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TokenManager _tokenManager = TokenManager();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ChatService().onNotification((message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nouveau message de ${message['senderName']}: ${message['message']}')),
      );
    });
  }

  void _loadUserData() async {
    final role = await _tokenManager.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  void _logout() {
    TokenManager().clearToken();
    ChatService().disconnect();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: _userRole == null
          ? const Center(child: CircularProgressIndicator())
          : DashboardScreen(userRole: _userRole!),
    );
  }
}