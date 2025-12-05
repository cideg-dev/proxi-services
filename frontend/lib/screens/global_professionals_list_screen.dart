import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart'; // Assuming an admin service or a general user service
import 'package:frontend/screens/profile_screen.dart'; // To navigate to user profile

class GlobalProfessionalsListScreen extends StatefulWidget {
  const GlobalProfessionalsListScreen({super.key});

  @override
  State<GlobalProfessionalsListScreen> createState() => _GlobalProfessionalsListScreenState();
}

class _GlobalProfessionalsListScreenState extends State<GlobalProfessionalsListScreen> {
  final AdminService _adminService = AdminService(); // Using AdminService for now, might need a general UserService
  late Future<List<dynamic>> _usersFuture;
  String _searchQuery = '';
  String? _selectedRoleFilter; // 'client', 'artisan', 'commercant'

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<dynamic>> _fetchUsers() async {
    return _adminService.getAllUsers(role: _selectedRoleFilter, search: _searchQuery);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _usersFuture = _fetchUsers(); // Re-fetch with new search query
    });
  }

  void _onRoleFilterChanged(String? newRole) {
    setState(() {
      _selectedRoleFilter = newRole;
      _usersFuture = _fetchUsers(); // Re-fetch with new role filter
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer les Utilisateurs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrer par rôle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
              value: _selectedRoleFilter,
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous les rôles')),
                DropdownMenuItem(value: 'client', child: Text('Clients')),
                DropdownMenuItem(value: 'artisan', child: Text('Artisans')),
                DropdownMenuItem(value: 'commercant', child: Text('Commerçants')),
              ],
              onChanged: _onRoleFilterChanged,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun utilisateur trouvé.'));
                }

                final users = snapshot.data!;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
              },
            ),
          ),
        ],
      ),
    );
  }
}
