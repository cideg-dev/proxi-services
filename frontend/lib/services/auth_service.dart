import 'dart:async';
import 'dart:convert';
import 'package:frontend/services/compatibility_api_service.dart';
import 'package:frontend/services/token_manager.dart';

class AuthService {
  final CompatibilityApiService _apiService = CompatibilityApiService();
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.postPublic(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await _tokenManager.setToken(token);
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
    if (referralCode != null && referralCode.isNotEmpty) {
      body['referralCode'] = referralCode;
    }

    final response = await _apiService.postPublic(
      '/api/auth/register',
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await _tokenManager.setToken(token);
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
    final response = await _apiService.get('/api/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!data.containsKey('user') || data['user'] == null) {
        data['user'] = <String, dynamic>{};
      }
      final userMap = data['user'] as Map<String, dynamic>;
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
    final response = await _apiService.put(
      '/api/profile',
      body: profileData,
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
    final response = await _apiService.post(
      '/api/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
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
    final response = await _apiService.get('/api/profile/$userId');
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
