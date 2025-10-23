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
      if (token != null) {
        await _tokenManager.setToken(token);
        // Persist user role and email after successful login
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _tokenManager.persistUserIdentity(
            role: user['role'] as String?,
            email: user['email'] as String?,
          );
        }
      }
      return data;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to login';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to login: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role, Map<String, dynamic> profileData, {String? referralCode}) async {
    final body = {
      'email': email,
      'password': password,
      'role': role,
      'profileData': profileData,
    };

    // Add referral code to the body if it exists and is not empty
    if (referralCode != null && referralCode.isNotEmpty) {
      body['referralCode'] = referralCode;
    }

    final response = await _postWithRetry(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
      <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await _tokenManager.setToken(token);
        // Persist user role and email after successful registration
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          await _tokenManager.persistUserIdentity(
            role: user['role'] as String?,
            email: user['email'] as String?,
          );
        }
      }
      return data;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        if (response.statusCode == 400 && errorBody.containsKey('errors')) {
          // If backend sends validation errors array
          final errors = (errorBody['errors'] as List).map((e) => e['msg'] as String).join('\n');
          throw Exception(errors);
        } else {
          final errorMessage = errorBody['message'] ?? 'Failed to register';
          throw Exception(errorMessage);
        }
      } catch (e) {
        throw Exception('Failed to register: ${response.body}');
      }
    }
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ensure 'user' map exists
      if (!data.containsKey('user') || data['user'] == null) {
        data['user'] = <String, dynamic>{};
      }
      final userMap = data['user'] as Map<String, dynamic>;

      // Fill missing role/email from TokenManager if API doesn't provide them
      if (userMap['role'] == null) {
        userMap['role'] = await _tokenManager.getUserRole();
      }
      if (userMap['email'] == null) {
        userMap['email'] = await _tokenManager.getUserEmail();
      }
      return data;
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to load profile: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to update profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/change-password'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
       try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Échec de la mise à jour du mot de passe');
      } catch (e) {
         throw Exception('Échec de la mise à jour du mot de passe: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> getProfileById(int userId) async {
    final token = await _tokenManager.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/profile/$userId'), // Assuming a /api/profile/:userId endpoint
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to load profile: ${response.body}');
      }
    }
  }
}
