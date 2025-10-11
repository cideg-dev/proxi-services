import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/widgets/glass_card.dart'; // For consistent styling
import 'package:intl/intl.dart'; // For date formatting

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({Key? key}) : super(key: key);

  @override
  _AdminReportManagementScreenState createState() => _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState extends State<AdminReportManagementScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _reports = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _limit = 10;
  String _searchQuery = '';
  String? _selectedStatus; // Filter by status
  String? _selectedReportType; // Filter by report type
  bool _hasMoreReports = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _reportStatuses = ['pending', 'resolved', 'rejected'];
  final List<String> _reportTypes = ['user', 'message', 'review', 'portfolio_item'];

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMoreReports && !_isLoading) {
        _loadReports(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReports({bool isLoadMore = false}) async {
    if (_isLoading || (!isLoadMore && _reports.isNotEmpty && _searchQuery.isEmpty && _selectedStatus == null && _selectedReportType == null)) return;
    if (!isLoadMore) {
      _currentPage = 1; // Reset page for new search or refresh
      _hasMoreReports = true;
    }

    setState(() {
      _isLoading = true;
      if (!isLoadMore) _error = null; // Clear error on fresh load
    });

    try {
      final response = await _adminService.getReports(
        page: _currentPage,
        limit: _limit,
        search: _searchQuery,
        status: _selectedStatus,
        reportType: _selectedReportType,
      );

      if (!mounted) return;

      setState(() {
        if (!isLoadMore) {
          _reports = response['reports'];
        } else {
          _reports.addAll(response['reports']);
        }
        _currentPage = response['page'];
        _hasMoreReports = (_currentPage * _limit) < response['total'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur de chargement des signalements: $e';
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
      _hasMoreReports = true;
    });
    _loadReports();
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
      _hasMoreReports = true;
    });
    _loadReports();
  }

  void _onReportTypeFilterChanged(String? type) {
    setState(() {
      _selectedReportType = type;
      _currentPage = 1;
      _hasMoreReports = true;
    });
    _loadReports();
  }

  Future<void> _resolveReport(int reportId, String status) async {
    try {
      await _adminService.resolveReport(reportId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signalement marqué comme $status avec succès.'), backgroundColor: Colors.green),
      );
      _loadReports(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteReport(int reportId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce signalement ? Cette action est irréversible.'),
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
        await _adminService.deleteReport(reportId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signalement supprimé avec succès.'), backgroundColor: Colors.green),
        );
        _loadReports(); // Refresh list
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
              labelText: 'Rechercher par raison',
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
                    labelText: 'Filtrer par statut',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les statuts')),
                    ..._reportStatuses.map((status) => DropdownMenuItem(value: status, child: Text(status))),
                  ],
                  onChanged: _onStatusFilterChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedReportType,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les types')),
                    ..._reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                  ],
                  onChanged: _onReportTypeFilterChanged,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadReports(),
            child: _isLoading && _reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _reports.isEmpty
                        ? const Center(child: Text('Aucun signalement trouvé.'))
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _reports.length + (_hasMoreReports ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _reports.length) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final report = _reports[index];
                              final bool isPending = report['status'] == 'pending';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: GlassCard(
                                  child: ListTile(
                                    title: Text('Signalement #${report['id']} - Type: ${report['report_type']}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Raison: ${report['reason']}'),
                                        Text('Statut: ${report['status']}'),
                                        Text('Rapporteur: ${report['reporter_name'] ?? report['reporter_email']}'),
                                        if (report['reported_user_name'] != null || report['reported_user_email'] != null)
                                          Text('Signalé: ${report['reported_user_name'] ?? report['reported_user_email']}'),
                                        Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(report['created_at']))}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isPending) ...[
                                          IconButton(
                                            icon: const Icon(Icons.check_circle),
                                            color: Colors.green,
                                            onPressed: () => _resolveReport(report['id'], 'resolved'),
                                            tooltip: 'Résoudre',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel),
                                            color: Colors.orange,
                                            onPressed: () => _resolveReport(report['id'], 'rejected'),
                                            tooltip: 'Rejeter',
                                          ),
                                        ],
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () => _deleteReport(report['id']),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // TODO: Navigate to report detail screen if needed
                                      print('View report details for ${report['id']}');
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
