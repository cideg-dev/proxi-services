import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';

class AdminService {
  final TokenManager _tokenManager = TokenManager();

  Future<List<dynamic>> getPendingVerifications() async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/verifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending verifications');
    }
  }

  Future<void> updateVerificationStatus(int userId, String status) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/verifications/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update verification status';
      throw Exception(errorMessage);
    }
  }

  // Get all users for admin panel with pagination and search
  Future<Map<String, dynamic>> getUsers({int page = 1, int limit = 10, String search = ''}) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/admin/users').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Get user by ID for admin panel
  Future<Map<String, dynamic>> getUserById(int userId) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  // Block or unblock a user
  Future<void> blockUser(int userId, bool isBlocked) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/users/$userId/block'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'isBlocked': isBlocked}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update user block status';
      throw Exception(errorMessage);
    }
  }

  // Delete a user
  Future<void> deleteUser(int userId) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to delete user';
      throw Exception(errorMessage);
    }
  }

  // Get all reports for admin panel with pagination, search, and filters
  Future<Map<String, dynamic>> getReports({int page = 1, int limit = 10, String search = '', String? status, String? reportType}) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (status != null) queryParams['status'] = status;
    if (reportType != null) queryParams['report_type'] = reportType;

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/admin/reports').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reports');
    }
  }

  // Resolve or reject a report
  Future<void> resolveReport(int reportId, String status) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/reports/$reportId/resolve'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to resolve report';
      throw Exception(errorMessage);
    }
  }

  // Delete a report
  Future<void> deleteReport(int reportId) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/admin/reports/$reportId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to delete report';
      throw Exception(errorMessage);
    }
  }

  // NEW: Get audit logs for admin panel with pagination, search, and filters
  Future<Map<String, dynamic>> getAuditLogs({int page = 1, int limit = 10, String search = '', int? userId, String? actionType, String? entityType}) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }

    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'search': search,
    };
    if (userId != null) queryParams['userId'] = userId.toString();
    if (actionType != null) queryParams['actionType'] = actionType;
    if (entityType != null) queryParams['entityType'] = entityType;

    final uri = Uri.parse('${ApiConstants.baseUrl}/api/admin/audit-logs').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load audit logs');
    }
  }
}


