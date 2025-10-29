
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:frontend/navigation_service.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/services/api_constants.dart';

class ApiService {
  final TokenManager _tokenManager = TokenManager();

  // Handles authenticated requests
  Future<http.Response> _handleRequest(Future<http.Response> Function(Map<String, String> headers) request) async {
    final token = await _tokenManager.getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    final response = await request(headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      _handleAuthError();
      throw Exception('Authentication Error');
    }
    return response;
  }

  // Handles unauthenticated requests
  Future<http.Response> _handleUnauthenticatedRequest(Future<http.Response> Function() request) async {
    final response = await request();
    // No auth error handling needed for public endpoints
    return response;
  }

  void _handleAuthError() async {
    await _tokenManager.clearToken();
    if (NavigationService.navigatorKey.currentState != null) {
      NavigationService.navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Authenticated methods
  Future<http.Response> get(String endpoint) {
    return _handleRequest((headers) => http.get(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    ));
  }

  Future<http.Response> post(String endpoint, {Object? body}) {
    return _handleRequest((headers) => http.post(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> put(String endpoint, {Object? body}) {
    return _handleRequest((headers) => http.put(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> delete(String endpoint) {
    return _handleRequest((headers) => http.delete(
      Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      headers: headers,
    ));
  }

  // New method for authenticated multipart requests, now platform-agnostic
  Future<http.StreamedResponse> multipartRequest(String method, String endpoint, {Map<String, String>? fields, List<http.MultipartFile>? files}) async {
    final token = await _tokenManager.getToken();
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


  // Unauthenticated methods
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
