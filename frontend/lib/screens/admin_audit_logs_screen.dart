import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/widgets/glass_card.dart'; // For consistent styling
import 'package:intl/intl.dart'; // For date formatting

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({Key? key}) : super(key: key);

  @override
  _AdminAuditLogsScreenState createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _logs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _limit = 10;
  String _searchQuery = '';
  String? _selectedActionType; // Filter by action type
  String? _selectedEntityType; // Filter by entity type
  bool _hasMoreLogs = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _actionTypes = [
    'user_login', 'user_blocked', 'report_resolved', 'profile_update',
    // Add other action types as they are logged
  ];
  final List<String> _entityTypes = [
    'user', 'report', 'profile', 'message', 'review', 'portfolio_item',
    // Add other entity types as they are logged
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMoreLogs && !_isLoading) {
        _loadLogs(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({bool isLoadMore = false}) async {
    if (_isLoading || (!isLoadMore && _logs.isNotEmpty && _searchQuery.isEmpty && _selectedActionType == null && _selectedEntityType == null)) return;
    if (!isLoadMore) {
      _currentPage = 1; // Reset page for new search or refresh
      _hasMoreLogs = true;
    }

    setState(() {
      _isLoading = true;
      if (!isLoadMore) _error = null; // Clear error on fresh load
    });

    try {
      final response = await _adminService.getAuditLogs(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        actionType: _selectedActionType,
        entityType: _selectedEntityType,
      );

      if (!mounted) return;

      setState(() {
        if (!isLoadMore) {
          _logs = response['logs'];
        } else {
          _logs.addAll(response['logs']);
        }
        _currentPage = response['page'];
        _hasMoreLogs = (_currentPage * _limit) < response['total'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des logs d\'audit: $e';
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
      _currentPage = 1;
      _hasMoreLogs = true;
    });
    _loadLogs();
  }

  void _onActionTypeFilterChanged(String? type) {
    setState(() {
      _selectedActionType = type;
      _currentPage = 1;
      _hasMoreLogs = true;
    });
    _loadLogs();
  }

  void _onEntityTypeFilterChanged(String? type) {
    setState(() {
      _selectedEntityType = type;
      _currentPage = 1;
      _hasMoreLogs = true;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Rechercher dans les détails',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par action',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedActionType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes les actions')),
                    ..._actionTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                  ],
                  onChanged: _onActionTypeFilterChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par entité',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedEntityType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes les entités')),
                    ..._entityTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                  ],
                  onChanged: _onEntityTypeFilterChanged,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadLogs(),
            child: _isLoading && _logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _logs.isEmpty
                        ? const Center(child: Text('Aucun log d\'audit trouvé.'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _logs.length + (_hasMoreLogs ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _logs.length) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final log = _logs[index];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GlassCard(
                                  child: ListTile(
                                    title: Text('Action: ${log['action_type']}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Utilisateur: ${log['user_name'] ?? log['user_email'] ?? 'N/A'} (ID: ${log['user_id'] ?? 'N/A'})'),
                                        Text('Entité: ${log['entity_type'] ?? 'N/A'} (ID: ${log['entity_id'] ?? 'N/A'})'),
                                        Text('Détails: ${log['details'] != null ? jsonEncode(log['details']) : 'N/A'}'),
                                        Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(log['timestamp']))}'),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: Navigate to log detail screen if needed
                                      print('View log details for ${log['id']}');
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
}
