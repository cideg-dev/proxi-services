import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_service.dart';
import 'package:intl/intl.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  final AppointmentService _appointmentService = AppointmentService();
  
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await _appointmentService.getUserAppointments();
      
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des rendez-vous: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAppointments,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun rendez-vous pour le moment',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Vos rendez-vous apparaîtront ici',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAppointments,
                      child: ListView.builder(
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return _buildAppointmentCard(appointment, theme);
                        },
                      ),
                    ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment, ThemeData theme) {
    final status = appointment['status'] ?? 'pending';
    final professional = appointment['professional'] ?? {};
    final professionalName = professional['name'] ?? 'Professionnel';
    final serviceType = appointment['serviceType'] ?? 'Service';
    
    DateTime dateTime;
    if (appointment['dateTime'] != null) {
      dateTime = DateTime.parse(appointment['dateTime']);
    } else {
      dateTime = DateTime.now();
    }

    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);

    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Confirmé';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'En attente';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Terminé';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = status;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceType,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        professionalName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (appointment['description'] != null && appointment['description'].isNotEmpty)
              Text(
                appointment['description'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAppointmentOptions(appointment);
                    },
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('Options'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.cardColor,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentOptions(dynamic appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Détails'),
              onTap: () {
                Navigator.pop(context);
                _showAppointmentDetails(appointment);
              },
            ),
            if (appointment['status'] == 'pending') ...[
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Annuler'),
                onTap: () {
                  Navigator.pop(context);
                  _showCancellationConfirmation(appointment['id']);
                },
              ),
            ],
            if (appointment['status'] == 'confirmed') ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  // Implémenter la modification du rendez-vous
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(dynamic appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du rendez-vous'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Service', appointment['serviceType']),
              _buildDetailRow('Professionnel', appointment['professional']['name'] ?? 'Inconnu'),
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy').format(DateTime.parse(appointment['dateTime']))),
              _buildDetailRow('Heure', DateFormat('HH:mm').format(DateTime.parse(appointment['dateTime']))),
              if (appointment['description'] != null && appointment['description'].isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(appointment['description']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _showCancellationConfirmation(int appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text('Êtes-vous sûr de vouloir annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Fermer la confirmation
              try {
                await _appointmentService.cancelAppointment(appointmentId);
                setState(() {
                  _loadAppointments(); // Recharger la liste
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rendez-vous annulé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'annulation: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }
}