import 'package:flutter/material.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:frontend/screens/my_profile_screen.dart';
import 'package:frontend/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<User> _profileFuture;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _profileFuture = _authService.getProfileById(widget.userId!);
    } else {
      _profileFuture = _authService.getProfile();
    }
  }

  // Fonction pour calculer le pourcentage de complétion du profil
  double _calculateProfileCompletion(User user) {
    int totalFields = 0;
    int completedFields = 0;
    
    // Convert to map for easier dynamic checking
    final profile = user.toJson();

    // Champs communs
    // Assuming User model maps these correctly or we check properties
    if (user.name != null && user.name!.isNotEmpty) completedFields++;
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) completedFields++;
    if (user.city != null && user.city!.isNotEmpty) completedFields++;
    
    totalFields += 3;

    // Champs spécifiques au rôle
    final String? role = user.role;
    if (role == 'client') {
      if (user.address != null && user.address!.isNotEmpty) completedFields++;
      // Check for 'sexe' in profile map if not in User model
      if (profile['sexe'] != null && profile['sexe'].toString().isNotEmpty) completedFields++;
      totalFields += 2; 
    } else if (role == 'artisan' || role == 'commercant') {
      const professionalFields = [
        'specialite',
        'description',
        'annees_experience',
        'horaires_ouverture',
        'langues_parlees',
        'assurance_professionnelle'
      ];
      totalFields += professionalFields.length;
      
      for (var field in professionalFields) {
        if (profile[field] != null) {
           if (field == 'langues_parlees' && (profile[field] is List && (profile[field] as List).isNotEmpty)) {
            completedFields++;
          } else if (field != 'langues_parlees' && profile[field].toString().isNotEmpty){
             completedFields++;
          }
        }
      }
    }
    
    return totalFields > 0 ? (completedFields / totalFields) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<User>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Aucune donnée de profil trouvée.'));
          }

          final user = snapshot.data!;
          final userData = user.toJson(); 
          final completionPercentage = _calculateProfileCompletion(user);
          final role = user.role;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(user, completionPercentage),
              const SizedBox(height: 30),
              _buildActionButtons(role),
              const SizedBox(height: 20),
              _buildProfileDetails(userData, role),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user, double completion) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name ?? 'Utilisateur',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          user.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        LinearPercentIndicator(
          lineHeight: 20.0,
          percent: completion,
          center: Text(
            "${(completion * 100).toStringAsFixed(0)}%",
            style: const TextStyle(fontSize: 12.0, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          barRadius: const Radius.circular(10),
          progressColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 8),
        const Text('Complétion du profil', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons(String? role) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyProfileScreen()),
            ).then((_) {
              // Refresh profile when returning
              setState(() {
                _profileFuture = _authService.getProfile();
              });
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Modifier mon profil'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        if (role == 'artisan') ...[
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArtisanPortfolioScreen()),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Gérer mon portfolio'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ArtisanServicesScreen()),
              );
            },
            icon: const Icon(Icons.build),
            label: const Text('Gérer mes services'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.blueGrey,
            ),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings),
          label: const Text('Paramètres'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> data, String? role) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Détaillées',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 20),
          _buildDetailRow(Icons.phone, 'Téléphone', data['telephone'] ?? data['phoneNumber']),
          _buildDetailRow(Icons.location_on, 'Localisation', data['location'] ?? data['city']),
          if (role == 'client') ...[
            _buildDetailRow(Icons.home, 'Adresse', data['adresse'] ?? data['address']),
            _buildDetailRow(Icons.person, 'Sexe', data['sexe']),
          ] else if (role == 'artisan' || role == 'commercant') ...[
            _buildDetailRow(Icons.build, 'Spécialité / Type', data['specialite'] ?? data['type_commerce']),
            _buildDetailRow(Icons.description, 'Description', data['description']),
            _buildDetailRow(Icons.calendar_today, 'Expérience', data['annees_experience'] != null ? '${data['annees_experience']} ans' : null),
            _buildDetailRow(Icons.schedule, 'Horaires', data['horaires_ouverture']),
            _buildDetailRow(Icons.language, 'Langues', (data['langues_parlees'] as List?)?.join(', ')),
            _buildDetailRow(Icons.verified_user, 'Assurance Pro', data['assurance_professionnelle'] == true ? 'Oui' : 'Non'),
          ]
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value ?? 'Non spécifié', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}