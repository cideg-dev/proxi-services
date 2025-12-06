import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_service.dart';
import 'package:frontend/widgets/date_selector.dart';
import 'package:frontend/widgets/time_slot_selector.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final int professionalId;
  final String professionalName;
  final String serviceType;

  const AppointmentBookingScreen({
    super.key,
    required this.professionalId,
    required this.professionalName,
    required this.serviceType,
  });

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  bool _isBooking = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre un Rendez-vous'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations sur le professionnel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rendez-vous avec',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.professionalName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.serviceType,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sélection de la date
              DateSelector(
                professionalId: widget.professionalId,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; // Réinitialiser l'heure quand la date change
                  });
                },
              ),
              
              // Sélection de l'heure
              if (_selectedDate != null)
                TimeSlotSelector(
                  professionalId: widget.professionalId,
                  selectedDate: _selectedDate!,
                  onTimeSelected: (time) {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                ),
              
              // Description du service
              if (_selectedDate != null && _selectedTime != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description du service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Décrivez les détails de votre demande...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Bouton de réservation
              if (_selectedDate != null && _selectedTime != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookAppointment,
                    child: _isBooking
                        ? const CircularProgressIndicator()
                        : Text(
                            'Confirmer le rendez-vous',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              
              // Résumé du rendez-vous
              if (_selectedDate != null && _selectedTime != null)
                Card(
                  margin: const EdgeInsets.only(top: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Résumé du rendez-vous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Heure: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.design_services,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Service: ${widget.serviceType}',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() {
      _isBooking = true;
    });

    try {
      await _appointmentService.createAppointment(
        professionalId: widget.professionalId,
        serviceType: widget.serviceType,
        dateTime: dateTime,
        description: _descriptionController.text,
      );

      // Afficher un message de succès
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rendez-vous confirmé'),
            content: const Text('Votre rendez-vous a été enregistré avec succès.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Retour à l'écran précédent
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la réservation: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }
}