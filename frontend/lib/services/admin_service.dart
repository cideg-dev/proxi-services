import 'dart:convert';
import 'package:frontend/services/api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getPendingVerifications() async {
    final response = await _apiService.get('/api/admin/verifications');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending verifications');
    }
  }

  Future<void> updateVerificationStatus(int userId, String status) async {
    final response = await _apiService.put(
      '/api/admin/verifications/$userId',
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update verification status';
      throw Exception(errorMessage);
    }
  }

    // Get all users for the global list with optional role filter and search
  Future<List<dynamic>> getAllUsers({String? role, String? search}) async {
    final Map<String, String> queryParams = {};
    if (role != null) queryParams['role'] = role;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('/api/users/all').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load all users');
    }
  }

  // Get all users for admin panel with pagination and search
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10, String search = ''}) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };

    final uri = Uri.parse('/api/admin/users').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Get user by ID for admin panel
  Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await _apiService.get('/api/admin/users/$userId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  // Block or unblock a user
  Future<void> blockUser(int userId, bool isBlocked) async {
    final response = await _apiService.put(
      '/api/admin/users/$userId/block',
      body: {'isBlocked': isBlocked},
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update user block status';
      throw Exception(errorMessage);
    }
  }

  // Delete a user
  Future<void> deleteUser(int userId) async {
    final response = await _apiService.delete('/api/admin/users/$userId');
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to delete user';
      throw Exception(errorMessage);
    }
  }

  // Get all reports for admin panel with pagination, search, and filters
  Future<Map<String, dynamic>> getReports({int page = 1, int limit = 10, String search = '', String? status, String? reportType}) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (status != null) queryParams['status'] = status;
    if (reportType != null) queryParams['report_type'] = reportType;

    final uri = Uri.parse('/api/admin/reports').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reports');
    }
  }

  // Resolve or reject a report
  Future<void> resolveReport(int reportId, String status) async {
    final response = await _apiService.put(
      '/api/admin/reports/$reportId/resolve',
      body: {'status': status},
    );
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to resolve report';
      throw Exception(errorMessage);
    }
  }

  // Delete a report
  Future<void> deleteReport(int reportId) async {
    final response = await _apiService.delete('/api/admin/reports/$reportId');
    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to delete report';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get audit logs for admin panel with pagination, search, and filters
  Future<Map<String, dynamic>> getAuditLogs({int page = 1, int limit = 10, String search = '', int? userId, String? actionType, String? entityType}) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (userId != null) queryParams['userId'] = userId.toString();
    if (actionType != null) queryParams['actionType'] = actionType;
    if (entityType != null) queryParams['entityType'] = entityType;

    final uri = Uri.parse('/api/admin/audit-logs').replace(queryParameters: queryParams);
    final response = await _apiService.get(uri.toString());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load audit logs');
    }
  }
}


