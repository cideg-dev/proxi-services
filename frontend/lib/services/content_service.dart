import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';

class ContentService {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  // Obtenir les articles du blog
  Future<List<dynamic>> getBlogPosts({
    String? category,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null) queryParams['category'] = category;
    if (searchQuery != null) queryParams['search'] = searchQuery;

    final uri = Uri.parse('/api/content/blog-posts').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des articles: ${response.body}');
    }
  }

  // Obtenir un article spécifique
  Future<Map<String, dynamic>> getBlogPost(int postId) async {
    final response = await _apiService.get('/api/content/blog-posts/$postId');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement de l\'article: ${response.body}');
    }
  }

  // Obtenir les articles populaires
  Future<List<dynamic>> getPopularPosts({int limit = 5}) async {
    final response = await _apiService.get('/api/content/popular-posts?limit=$limit');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des articles populaires: ${response.body}');
    }
  }

  // Obtenir les articles récents
  Future<List<dynamic>> getRecentPosts({int limit = 5}) async {
    final response = await _apiService.get('/api/content/recent-posts?limit=$limit');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des articles récents: ${response.body}');
    }
  }

  // Obtenir les catégories d'articles
  Future<List<dynamic>> getBlogCategories() async {
    final response = await _apiService.get('/api/content/blog-categories');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des catégories: ${response.body}');
    }
  }

  // Créer un nouvel article (pour les utilisateurs autorisés)
  Future<Map<String, dynamic>> createBlogPost({
    required String title,
    required String content,
    required String category,
    String? excerpt,
    String? imageUrl,
    bool isPublished = false,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/content/blog-posts',
      body: {
        'authorId': userId,
        'title': title,
        'content': content,
        'category': category,
        if (excerpt != null) 'excerpt': excerpt,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isPublished': isPublished,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la création de l\'article: ${response.body}');
    }
  }

  // Mettre à jour un article existant
  Future<Map<String, dynamic>> updateBlogPost({
    required int postId,
    String? title,
    String? content,
    String? category,
    String? excerpt,
    String? imageUrl,
    bool? isPublished,
  }) async {
    final response = await _apiService.put('/api/content/blog-posts/$postId',
      body: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (category != null) 'category': category,
        if (excerpt != null) 'excerpt': excerpt,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isPublished != null) 'isPublished': isPublished,
      }
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la mise à jour de l\'article: ${response.body}');
    }
  }

  // Liker/unliker un article
  Future<Map<String, dynamic>> toggleLikePost(int postId) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/content/blog-posts/$postId/like',
      body: {'userId': userId}
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'action like: ${response.body}');
    }
  }

  // Commenter un article
  Future<Map<String, dynamic>> commentOnPost({
    required int postId,
    required String comment,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await _apiService.post('/api/content/blog-posts/$postId/comment',
      body: {
        'userId': userId,
        'comment': comment,
      }
    );
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de l\'ajout du commentaire: ${response.body}');
    }
  }

  // Obtenir les commentaires d'un article
  Future<List<dynamic>> getPostComments(int postId, {int page = 1, int limit = 10}) async {
    final response = await _apiService.get(
      '/api/content/blog-posts/$postId/comments?page=$page&limit=$limit'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des commentaires: ${response.body}');
    }
  }

  // Rechercher des articles
  Future<List<dynamic>> searchBlogPosts(String query, {int page = 1, int limit = 10}) async {
    final response = await _apiService.get(
      '/api/content/search?query=$query&page=$page&limit=$limit'
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la recherche d\'articles: ${response.body}');
    }
  }

  // Obtenir les articles liés à un service ou artisan
  Future<List<dynamic>> getRelatedContent({
    String? serviceType,
    int? artisanId,
    int limit = 5,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (serviceType != null) queryParams['serviceType'] = serviceType;
    if (artisanId != null) queryParams['artisanId'] = artisanId.toString();

    final uri = Uri.parse('/api/content/related').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec du chargement des contenus liés: ${response.body}');
    }
  }
}