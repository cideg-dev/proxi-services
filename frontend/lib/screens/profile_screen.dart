import 'package:flutter/material.dart';
import 'package:frontend/screens/artisan_portfolio_screen.dart';
import 'package:frontend/screens/artisan_services_screen.dart';
import 'package:frontend/screens/chat_list_screen.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:frontend/screens/my_profile_screen.dart'; // Pour la modification

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

  // Fonction pour calculer le pourcentage de complétion du profil
  double _calculateProfileCompletion(Map<String, dynamic> profile) {
    int totalFields = 0;
    int completedFields = 0;

    // Champs communs
    const commonFields = ['nom_complet', 'telephone', 'location'];
    totalFields += commonFields.length;
    for (var field in commonFields) {
      if (profile[field] != null && profile[field].toString().isNotEmpty) {
        completedFields++;
      }
    }

    // Champs spécifiques au rôle
    final String? role = profile['role'];
    if (role == 'client') {
      const clientFields = ['adresse', 'sexe'];
      totalFields += clientFields.length;
       for (var field in clientFields) {
        if (profile[field] != null && profile[field].toString().isNotEmpty) {
          completedFields++;
        }
      }
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
           if (field == 'langues_parlees' && (profile[field] as List).isNotEmpty) {
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune donnée de profil trouvée.'));
          }

          final user = snapshot.data!['user'] ?? {};
          final profile = snapshot.data!['profile'] ?? {};
          final allData = {...user, ...profile};
          final completionPercentage = _calculateProfileCompletion(allData);
          final role = allData['role'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(allData, completionPercentage),
              const SizedBox(height: 30),
              _buildActionButtons(role),
              const SizedBox(height: 20),
              _buildProfileDetails(allData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data, double completion) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 60.0,
          lineWidth: 8.0,
          animation: true,
          percent: completion,
          center: CircleAvatar(
            radius: 50.0,
            // backgroundImage: data['profile_photo_url'] != null
            //     ? NetworkImage(data['profile_photo_url'])
            //     : null,
            child: data['profile_photo_url'] == null
                ? Text(
                    data['nom_complet']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 15),
        Text(
          data['nom_complet'] ?? 'Nom non défini',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          data['email'] ?? 'Email non défini',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 5),
        Chip(
          label: Text(data['role'] ?? 'Rôle non défini'),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String? role) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Modifier mon profil'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyProfileScreen()),
            ).then((_) {
              // Rafraîchir les données du profil au retour
              setState(() {
                _profileFuture = _authService.getProfile();
              });
            });
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50), // full width
          ),
        ),
        const SizedBox(height: 10),
        if (role == 'artisan' || role == 'commercant') ...[
           _buildNavigateButton(
            context,
            icon: Icons.work,
            label: 'Mes Services',
            screen: const ArtisanServicesScreen(),
          ),
          const SizedBox(height: 10),
          _buildNavigateButton(
            context,
            icon: Icons.photo_library,
            label: 'Mon Portfolio',
            screen: const ArtisanPortfolioScreen(),
          ),
          const SizedBox(height: 10),
        ],
        _buildNavigateButton(
          context,
          icon: Icons.message,
          label: 'Messages',
          screen: const ChatListScreen(),
        ),
         const SizedBox(height: 10),
        _buildNavigateButton(
          context,
          icon: Icons.settings,
          label: 'Paramètres',
          screen: const SettingsScreen(),
        ),
      ],
    );
  }

   Widget _buildNavigateButton(BuildContext context, {required IconData icon, required String label, Widget? screen}) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        } else {
          // Pour l'instant, affiche une modale car les routes ne sont pas prêtes
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('En cours de développement'),
              content: Text('La navigation vers "$label" n\'est pas encore implémentée.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 45),
      ),
    );
  }


  Widget _buildProfileDetails(Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations Détaillées',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 20),
            _buildDetailRow(Icons.phone, 'Téléphone', data['telephone']),
            _buildDetailRow(Icons.location_on, 'Localisation', data['location']),
            if (data['role'] == 'client') ...[
              _buildDetailRow(Icons.home, 'Adresse', data['adresse']),
              _buildDetailRow(Icons.person, 'Sexe', data['sexe']),
            ] else if (data['role'] == 'artisan' || data['role'] == 'commercant') ...[
              _buildDetailRow(Icons.build, 'Spécialité / Type', data['specialite'] ?? data['type_commerce']),
              _buildDetailRow(Icons.description, 'Description', data['description']),
              _buildDetailRow(Icons.calendar_today, 'Expérience', '${data['annees_experience']} ans'),
              _buildDetailRow(Icons.schedule, 'Horaires', data['horaires_ouverture']),
              _buildDetailRow(Icons.language, 'Langues', (data['langues_parlees'] as List?)?.join(', ')),
              _buildDetailRow(Icons.verified_user, 'Assurance Pro', data['assurance_professionnelle'] == true ? 'Oui' : 'Non'),
            ]
          ],
        ),
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