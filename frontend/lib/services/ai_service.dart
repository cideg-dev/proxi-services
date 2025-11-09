import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class AIService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Envoyer une requête à l'assistant virtuel
  Future<Map<String, dynamic>> askVirtualAssistant({
    required String question,
    String? context, // Contexte de la conversation
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/ai/assistant',
      body: {
        'userId': userId,
        'question': question,
        if (context != null) 'context': context,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la requête à l\'assistant: ${response.body}');
    }
  }

  // Démarrer une nouvelle conversation avec l'assistant
  Future<Map<String, dynamic>> startNewConversation() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/ai/conversation/start',
      body: {'userId': userId}
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du démarrage de la conversation: ${response.body}');
    }
  }

  // Obtenir l'historique des conversations avec l'assistant
  Future<List<dynamic>> getAssistantHistory() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/ai/conversations/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'historique: ${response.body}');
    }
  }

  // Obtenir les suggestions de questions fréquentes
  Future<List<dynamic>> getFrequentQuestions() async {
    final response = await _apiService.getPublic('/api/ai/frequent-questions');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des questions fréquentes: ${response.body}');
    }
  }

  // Obtenir des recommandations personnalisées basées sur l'IA
  Future<List<dynamic>> getPersonalizedRecommendations() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/ai/recommendations/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des recommandations: ${response.body}');
    }
  }

  // Analyser une image pour obtenir des suggestions (ex: photo d'un problème)
  Future<Map<String, dynamic>> analyzeImage({
    required String imagePath,
    String? description,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // Note: Cette implémentation suppose que le backend gère l'analyse d'images
    final response = await _apiService.post('/api/ai/image-analysis',
      body: {
        'userId': userId,
        'imagePath': imagePath,
        if (description != null) 'description': description,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'analyse de l\'image: ${response.body}');
    }
  }

  // Obtenir un devis automatique basé sur une description
  Future<Map<String, dynamic>> getAutomatedQuote({
    required String serviceDescription,
    String? location,
    String? details,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/ai/quote',
      body: {
        'userId': userId,
        'serviceDescription': serviceDescription,
        if (location != null) 'location': location,
        if (details != null) 'details': details,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la génération du devis: ${response.body}');
    }
  }

  // Obtenir des alertes intelligentes basées sur les préférences de l'utilisateur
  Future<List<dynamic>> getSmartAlerts() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/ai/smart-alerts/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des alertes intelligentes: ${response.body}');
    }
  }

  // Suggérer des créneaux horaires optimaux pour un service
  Future<List<dynamic>> suggestOptimalAppointmentTimes({
    required String serviceType,
    DateTime? preferredDate,
    String? location,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/ai/optimal-times',
      body: {
        'userId': userId,
        'serviceType': serviceType,
        if (preferredDate != null) 'preferredDate': preferredDate.toIso8601String(),
        if (location != null) 'location': location,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la suggestion des créneaux: ${response.body}');
    }
  }

  // Faire une prédiction basée sur les données historiques de l'utilisateur
  Future<Map<String, dynamic>> predictUserNeeds() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.get('/api/ai/predictions/$userId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la prédiction des besoins: ${response.body}');
    }
  }
}