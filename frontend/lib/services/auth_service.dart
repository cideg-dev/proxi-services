import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'token_manager.dart';

class AuthService {
  final TokenManager _tokenManager = TokenManager();

  Future<http.Response> _postWithRetry(
      Uri url, Map<String, String> headers, String body,
      {int retries = 3, Duration delay = const Duration(seconds: 2)}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 10));
        // Si le statut n'est pas une erreur serveur, on retourne la réponse
        if (response.statusCode < 500) {
          return response;
        }
        // Sinon, on continue pour retenter (erreur serveur)
      } on SocketException catch (e) {
        print("SocketException: $e. Tentative ${i + 1} sur $retries...");
        if (i == retries - 1) rethrow; // Lance l'erreur à la dernière tentative
      } on TimeoutException catch (e) {
        print("TimeoutException: $e. Tentative ${i + 1} sur $retries...");
        if (i == retries - 1) rethrow;
      } on HttpException catch (e) {
        print("HttpException: $e. Tentative ${i + 1} sur $retries...");
        if (i == retries - 1) rethrow;
      }
      await Future.delayed(delay);
    }
    throw Exception('Toutes les tentatives de connexion ont échoué.');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _postWithRetry(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
      <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = data['user'];
      if (token != null && user != null) {
        await _tokenManager.setToken(token);
        await _tokenManager.setUser(user);
      }
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to login';
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role) async {
    final response = await _postWithRetry(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
      <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final user = data['user'];
      if (token != null && user != null) {
        await _tokenManager.setToken(token);
        await _tokenManager.setUser(user);
      }
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to register';
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }
}
