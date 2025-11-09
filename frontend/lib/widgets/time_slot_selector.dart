import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_service.dart';
import 'package:intl/intl.dart';

class TimeSlotSelector extends StatefulWidget {
  final int professionalId;
  final DateTime selectedDate;
  final Function(DateTime selectedTime)? onTimeSelected;

  const TimeSlotSelector({
    super.key,
    required this.professionalId,
    required this.selectedDate,
    this.onTimeSelected,
  });

  @override
  State<TimeSlotSelector> createState() => _TimeSlotSelectorState();
}

class _TimeSlotSelectorState extends State<TimeSlotSelector> {
  final AppointmentService _appointmentService = AppointmentService();
  List<DateTime> _availableSlots = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final slots = await _appointmentService.getAvailableSlots(
        widget.professionalId,
        widget.selectedDate,
      );
      
      setState(() {
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des créneaux: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(_errorMessage),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('Aucun créneau disponible pour cette date'),
        ),
      );
    }

    // Grouper les créneaux par demi-journée
    final morningSlots = _availableSlots.where((slot) => slot.hour < 12).toList();
    final afternoonSlots = _availableSlots.where((slot) => slot.hour >= 12).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (morningSlots.isNotEmpty) ...[
            const Text(
              'Matin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeSlotGrid(morningSlots),
            const SizedBox(height: 16),
          ],
          if (afternoonSlots.isNotEmpty) ...[
            const Text(
              'Après-midi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeSlotGrid(afternoonSlots),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid(List<DateTime> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final timeString = DateFormat('HH:mm').format(slot);
        return ChoiceChip(
          label: Text(timeString),
          selected: false,
          onSelected: (selected) {
            if (selected && widget.onTimeSelected != null) {
              widget.onTimeSelected!(slot);
            }
          },
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).cardColor,
          selectedShadowColor: Colors.transparent,
          shadowColor: Colors.transparent,
        );
      }).toList(),
    );
  }
}