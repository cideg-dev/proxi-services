import 'package:flutter/material.dart';
import 'package:frontend/widgets/glass_card.dart'; // New import
import '../services/admin_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_constants.dart';
import 'admin_user_management_screen.dart'; // New import
import 'admin_report_management_screen.dart'; // New import
import 'admin_audit_logs_screen.dart'; // New import
import 'package:http/http.dart' as http; // Required for DB migration
import 'package:frontend/services/token_manager.dart'; // Required for DB migration

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<dynamic>> _verificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  void _loadVerifications() {
    setState(() {
      _verificationsFuture = _adminService.getPendingVerifications();
    });
  }

  Future<void> _updateStatus(int userId, String status) async {
    try {
      await _adminService.updateVerificationStatus(userId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour avec succès.'), backgroundColor: Colors.green),
      );
      _loadVerifications(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openDocument(String? documentUrl) async {
    if (documentUrl != null) {
      final fullUrl = Uri.parse('${ApiConstants.baseUrl}$documentUrl');
      if (await canLaunchUrl(fullUrl)) {
        await launchUrl(fullUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le document: $fullUrl')),
        );
      }
    }
  }

  Future<void> _runDbMigration() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lancement de la migration de la BDD...')),
    );
    try {
      final token = await TokenManager().getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant.');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/migrate-db'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Migration de la BDD réussie !'), backgroundColor: Colors.green),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Échec de la migration de la BDD.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de migration de la BDD: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController( // New: Tab controller
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Admin'),
          bottom: const TabBar( // New: Tab bar
            tabs: [
              Tab(text: 'Vérifications'),
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Signalements'),
              Tab(text: 'Logs d\'Audit'),
            ],
          ),
        ),
        body: TabBarView( // New: Tab bar view
          children: [
            _buildVerificationsTab(), // Existing content for verifications
            const AdminUserManagementScreen(), // Integrated user management screen
            const AdminReportManagementScreen(), // Integrated report management screen
            Column(
              children: [
                const Expanded(child: AdminAuditLogsScreen()),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.build),
                    label: const Text('Lancer la migration de la BDD (Temporaire)'),
                    onPressed: _runDbMigration,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _verificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucune demande de vérification en attente.'));
        }

        final verifications = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _loadVerifications(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0), // Add padding to list
            itemCount: verifications.length,
            itemBuilder: (context, index) {
              final verification = verifications[index];
              return Padding( // New: Padding around GlassCard
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassCard( // New: Use GlassCard
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${verification['name']} (ID: ${verification['id']})', style: Theme.of(context).textTheme.titleLarge),
                        Text('Rôle: ${verification['role']}'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.description),
                          label: const Text('Voir le document'),
                          onPressed: () => _openDocument(verification['document_verification_url']),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Approuver'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updateStatus(verification['id'], 'verified'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close),
                              label: const Text('Rejeter'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => _updateStatus(verification['id'], 'rejected'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }






}