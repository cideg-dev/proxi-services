import 'package:flutter/material.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/screens/profile_boost_screen.dart'; // New import
import 'package:frontend/screens/subscription_screen.dart'; // New import
import 'package:frontend/screens/invoices_screen.dart'; // New import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TokenManager _tokenManager = TokenManager();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _tokenManager.getUser();
    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: <Widget>[
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(_user!['email'] ?? 'Non défini'),
                ),
                ListTile(
                  title: const Text('Rôle'),
                  subtitle: Text(_user!['role'] ?? 'Non défini'),
                ),
                // Add more profile information here
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileBoostScreen()),
                      );
                      // Handle result from ProfileBoostScreen if needed
                      if (result == true) {
                        // Profile boost successful, maybe show a confirmation or refresh profile data
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil boosté avec succès !'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: const Text('Booster mon profil'),
                  ),
                ),
                ListTile(
                  title: const Text('Mes Abonnements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubscriptionScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Mes Factures'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InvoicesScreen()),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
