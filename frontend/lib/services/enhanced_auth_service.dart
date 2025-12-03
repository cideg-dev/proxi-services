import 'dart:convert';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/navigation_service.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_constants.dart';
import 'package:flutter/material.dart';

class EnhancedApiService {
  final TokenManager _tokenManager = TokenManager();

  // Handles authenticated requests with enhanced error handling
  Future<http.Response> _handleRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    // Check if we have a token before making the request
    final token = await _tokenManager.getToken();
    
    // If no token is available, redirect to login
    if (token == null || token.isEmpty) {
      if (NavigationService.navigatorKey.currentState != null) {
        NavigationService.navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      throw Exception('No authentication token available');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await request(headers);

      // Handle authentication errors (401, 403)
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleAuthError();
        throw Exception('Authentication Error: ${response.body}');
      }
      
      return response;
    } catch (e) {
      // Log the error for debugging
      print('API request error: $e');
      rethrow;
    }
  }

  // Handles unauthenticated requests (public endpoints)
  Future<http.Response> _handleUnauthenticatedRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      return response;
    } catch (e) {
      // Log the error for debugging
      print('Public API request error: $e');
      rethrow;
    }
  }

  Future<void> _handleAuthError() async {
    await _tokenManager.clearToken();
    if (NavigationService.navigatorKey.currentState != null) {
      NavigationService.navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Authenticated methods with enhanced error handling
  Future<http.Response> get(String endpoint) async {
    return await _handleRequest((headers) => http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    ));
  }

  Future<http.Response> post(String endpoint, {Object? body}) async {
    return await _handleRequest((headers) => http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> put(String endpoint, {Object? body}) async {
    return await _handleRequest((headers) => http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> delete(String endpoint) async {
    return await _handleRequest((headers) => http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    ));
  }

  // Enhanced method for authenticated multipart requests
  Future<http.StreamedResponse> multipartRequest(
    String method,
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    // Check if we have a token before making the request
    final token = await _tokenManager.getToken();
    
    // If no token is available, redirect to login
    if (token == null || token.isEmpty) {
      if (NavigationService.navigatorKey.currentState != null) {
        NavigationService.navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      throw Exception('No authentication token available');
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };

    var request = http.MultipartRequest(method, Uri.parse('${ApiConstants.baseUrl}$endpoint'));
    request.headers.addAll(headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files);
    }

    return request.send();
  }

  // Unauthenticated methods (public endpoints)
  Future<http.Response> getPublic(String endpoint) {
    return _handleUnauthenticatedRequest(() => http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
    ));
  }

  Future<http.Response> postPublic(String endpoint, {Object? body}) {
    return _handleUnauthenticatedRequest(() => http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    ));
  }
}