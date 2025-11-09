import 'package:flutter/material.dart';
import 'package:frontend/services/appointment_service.dart';
import 'package:intl/intl.dart';

class DateSelector extends StatefulWidget {
  final int professionalId;
  final Function(DateTime selectedDate)? onDateSelected;

  const DateSelector({
    super.key,
    required this.professionalId,
    this.onDateSelected,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  final AppointmentService _appointmentService = AppointmentService();
  List<DateTime> _availableDates = [];
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
  }

  Future<void> _loadAvailableDates() async {
    try {
      // Récupérer les horaires de travail pour déterminer les dates disponibles
      final schedule = await _appointmentService.getProfessionalSchedule(widget.professionalId);
      
      // Pour cet exemple, nous allons proposer les 7 prochains jours ouvrables
      // En production, cela serait basé sur les horaires réels et les rendez-vous déjà pris
      final now = DateTime.now();
      final dates = <DateTime>[];
      
      for (int i = 0; i < 14; i++) {
        final date = DateTime(now.year, now.month, now.day + i);
        // Ici, on suppose que tous les jours sont disponibles sauf le dimanche
        if (date.weekday != 7) { // 7 = dimanche
          dates.add(date);
        }
      }
      
      setState(() {
        _availableDates = dates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des dates: $e';
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionnez une date',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final dateString = DateFormat('EEE\ndd/MM').format(date);
                final isSelected = _selectedDate != null && 
                    _selectedDate!.day == date.day && 
                    _selectedDate!.month == date.month && 
                    _selectedDate!.year == date.year;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${date.day}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedDate = date;
                        });
                        if (widget.onDateSelected != null) {
                          widget.onDateSelected!(date);
                        }
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).cardColor,
                    labelStyle: isSelected 
                        ? const TextStyle(color: Colors.white) 
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}