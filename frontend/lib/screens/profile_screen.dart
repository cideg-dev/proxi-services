import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/theme_provider.dart';
import 'my_profile_screen.dart'; // Assurez-vous que cet écran existe

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _authService.getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!['profile'] == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucun profil trouvé.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyProfileScreen()),
                      );
                      _refreshProfile(); // Rafraîchir après la création
                    },
                    child: const Text('Créer mon profil'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data['profile'];
          final completeness = data['completeness'] as int;
          final completenessPercent = completeness / 100.0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Center(
                child: CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 10.0,
                  percent: completenessPercent,
                  center: Text('$completeness%'),
                  progressColor: Colors.green,
                  backgroundColor: Colors.grey.shade300,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Profil complet à $completeness%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Nom'),
                subtitle: Text(profile['nom_complet'] ?? profile['nom_entreprise'] ?? 'Non défini'),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(profile['email'] ?? 'Non défini'), // Note: email is not in profile, needs to be added
              ),
              ListTile(
                title: const Text('Téléphone'),
                subtitle: Text(profile['telephone'] ?? 'Non défini'),
              ),
              ListTile(
                title: const Text('Localisation'),
                subtitle: Text(profile['location'] ?? 'Non défini'),
              ),
              const Divider(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Modifier mon profil'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyProfileScreen()),
                  );
                  _refreshProfile(); // Rafraîchir après modification
                },
              ),
              const Divider(height: 32),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    title: const Text('Mode Sombre'),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
