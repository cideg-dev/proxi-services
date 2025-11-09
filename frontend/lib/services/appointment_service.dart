import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class AppointmentService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Créer un nouveau rendez-vous
  Future<Map<String, dynamic>> createAppointment({
    required int professionalId,
    required String serviceType,
    required DateTime dateTime,
    required String description,
    double? price,
  }) async {
    final response = await _apiService.post('/api/appointments',
      body: {
        'professionalId': professionalId,
        'serviceType': serviceType,
        'dateTime': dateTime.toIso8601String(),
        'description': description,
        if (price != null) 'price': price,
      }
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création du rendez-vous: ${response.body}');
    }
  }

  // Obtenir les rendez-vous de l'utilisateur
  Future<List<dynamic>> getUserAppointments() async {
    final response = await _apiService.get('/api/appointments/user');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des rendez-vous: ${response.body}');
    }
  }

  // Obtenir les rendez-vous d'un professionnel
  Future<List<dynamic>> getProfessionalAppointments(int professionalId) async {
    final response = await _apiService.get('/api/appointments/professional/$professionalId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des rendez-vous: ${response.body}');
    }
  }

  // Obtenir les horaires disponibles pour un professionnel
  Future<List<DateTime>> getAvailableSlots(int professionalId, DateTime date) async {
    final response = await _apiService.get(
      '/api/appointments/available-slots/$professionalId?date=${date.toIso8601String()}'
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['slots'] as List).map((slot) => DateTime.parse(slot)).toList();
    } else {
      throw Exception('Échec du chargement des horaires disponibles: ${response.body}');
    }
  }

  // Annuler un rendez-vous
  Future<void> cancelAppointment(int appointmentId) async {
    final response = await _apiService.put('/api/appointments/$appointmentId/cancel');

    if (response.statusCode != 200) {
      throw Exception('Échec de l\'annulation du rendez-vous: ${response.body}');
    }
  }

  // Confirmer un rendez-vous
  Future<void> confirmAppointment(int appointmentId) async {
    final response = await _apiService.put('/api/appointments/$appointmentId/confirm');

    if (response.statusCode != 200) {
      throw Exception('Échec de la confirmation du rendez-vous: ${response.body}');
    }
  }

  // Mettre à jour un rendez-vous
  Future<Map<String, dynamic>> updateAppointment(
    int appointmentId, {
    int? professionalId,
    String? serviceType,
    DateTime? dateTime,
    String? description,
    double? price,
  }) async {
    final response = await _apiService.put('/api/appointments/$appointmentId',
      body: {
        if (professionalId != null) 'professionalId': professionalId,
        if (serviceType != null) 'serviceType': serviceType,
        if (dateTime != null) 'dateTime': dateTime.toIso8601String(),
        if (description != null) 'description': description,
        if (price != null) 'price': price,
      }
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour du rendez-vous: ${response.body}');
    }
  }

  // Obtenir les détails d'un rendez-vous
  Future<Map<String, dynamic>> getAppointmentDetails(int appointmentId) async {
    final response = await _apiService.get('/api/appointments/$appointmentId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des détails du rendez-vous: ${response.body}');
    }
  }

  // Obtenir l'horaire de travail d'un professionnel
  Future<Map<String, dynamic>> getProfessionalSchedule(int professionalId) async {
    final response = await _apiService.get('/api/schedules/$professionalId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'horaire: ${response.body}');
    }
  }
}