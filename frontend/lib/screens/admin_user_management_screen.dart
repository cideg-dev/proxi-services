import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/widgets/glass_card.dart'; // For consistent styling
import 'package:frontend/services/api_constants.dart'; // For image URLs

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _limit = 10;
  String _searchQuery = '';
  bool _hasMoreUsers = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMoreUsers && !_isLoading) {
        _loadUsers(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool isLoadMore = false}) async {
    if (_isLoading || (!isLoadMore && _users.isNotEmpty)) return; // Prevent double loading on initial load
    if (!isLoadMore) {
      _currentPage = 1; // Reset page for new search or refresh
      _hasMoreUsers = true;
    }

    setState(() {
      _isLoading = true;
      if (!isLoadMore) _error = null; // Clear error on fresh load
    });

    try {
      final response = await _adminService.getUsers(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
      );

      if (!mounted) return;

      setState(() {
        if (!isLoadMore) {
          _users = response['users'];
        } else {
          _users.addAll(response['users']);
        }
        _currentPage = response['page'];
        _hasMoreUsers = (_currentPage * _limit) < response['total'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des utilisateurs: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset page for new search
      _hasMoreUsers = true; // Assume more results for new search
    });
    _loadUsers();
  }

  Future<void> _toggleBlockUser(int userId, bool isBlocked) async {
    try {
      await _adminService.blockUser(userId, !isBlocked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Utilisateur ${!isBlocked ? 'bloqué' : 'débloqué'} avec succès.'), backgroundColor: Colors.green),
      );
      _loadUsers(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteUser(int userId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cet utilisateur ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur supprimé avec succès.'), backgroundColor: Colors.green),
        );
        _loadUsers(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher un utilisateur',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadUsers(),
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _users.isEmpty
                        ? const Center(child: Text('Aucun utilisateur trouvé.'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _users.length + (_hasMoreUsers ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _users.length) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final user = _users[index];
                              final bool isBlocked = user['is_blocked'] ?? false;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GlassCard(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user['photo_url'] != null
                                          ? NetworkImage('${ApiConstants.baseUrl}${user['photo_url']}')
                                          : null,
                                      child: user['photo_url'] == null
                                          ? Icon(_getRoleIcon(user['role']))
                                          : null,
                                    ),
                                    title: Text(user['name'] ?? user['email']),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Email: ${user['email']}'),
                                        Text('Rôle: ${user['role']}'),
                                        if (user['verification_status'] != null)
                                          Text('Vérification: ${user['verification_status']}'),
                                        Text('Statut: ${isBlocked ? 'Bloqué' : 'Actif'}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(isBlocked ? Icons.lock_open : Icons.lock),
                                          color: isBlocked ? Colors.green : Colors.orange,
                                          onPressed: () => _toggleBlockUser(user['id'], isBlocked),
                                          tooltip: isBlocked ? 'Débloquer' : 'Bloquer',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deleteUser(user['id']),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: Navigate to user detail screen if needed
                                      print('View user details for ${user['id']}');
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'client':
        return Icons.person;
      case 'artisan':
        return Icons.construction;
      case 'commercant':
        return Icons.store;
      case 'admin':
        return Icons.security;
      default:
        return Icons.person_outline;
    }
  }
}
