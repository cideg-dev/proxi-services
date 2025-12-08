import 'dart:async';
import 'dart:convert';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/models/user_model.dart';

class AuthService {
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.safeJsonDecode(response.body);
      String? token;
      String? refreshToken;

      if (data.containsKey('token')) {
        token = data['token'];
      } else if (data.containsKey('access_token')) {
        token = data['access_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        token = data['session']['access_token'];
      }

      if (data.containsKey('refreshToken')) {
        refreshToken = data['refreshToken'];
      } else if (data.containsKey('refresh_token')) {
        refreshToken = data['refresh_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        refreshToken = data['session']['refresh_token'];
      }

      if (token != null) {
        await _tokenManager.setToken(token);
        if (refreshToken != null) {
          await _tokenManager.setRefreshToken(refreshToken);
        }

        Map<String, dynamic>? user;
        if (data.containsKey('user')) {
          user = data['user'];
        } else if (data.containsKey('session') && data['session']['user'] != null) {
          user = data['session']['user'];
        }

        if (user != null) {
          String? role = user['role'];
          if (role == null && user['app_metadata'] != null) {
            role = user['app_metadata']['role'];
          }
          if (role == null && user['user_metadata'] != null) {
            role = user['user_metadata']['role'];
          }

          await _tokenManager.persistUserIdentity(
            role: role,
            email: user['email'],
          );
        }
      }
      return data;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role, Map<String, dynamic> profileData, {String? referralCode}) async {
    if (referralCode != null && referralCode.isNotEmpty) {
      profileData['referralCode'] = referralCode;
    }

    final response = await ApiService.post('/auth/register', {
      'email': email,
      'password': password,
      'role': role,
      'profileData': profileData,
    });

    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.safeJsonDecode(response.body);
      String? token;
      String? refreshToken;

      if (data.containsKey('token')) {
        token = data['token'];
      } else if (data.containsKey('access_token')) {
        token = data['access_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        token = data['session']['access_token'];
      }

      if (data.containsKey('refreshToken')) {
        refreshToken = data['refreshToken'];
      } else if (data.containsKey('refresh_token')) {
        refreshToken = data['refresh_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        refreshToken = data['session']['refresh_token'];
      }

      if (token != null) {
        await _tokenManager.setToken(token);
        if (refreshToken != null) {
          await _tokenManager.setRefreshToken(refreshToken);
        }

         Map<String, dynamic>? user;
        if (data.containsKey('user')) {
          user = data['user'];
        } else if (data.containsKey('session') && data['session']['user'] != null) {
          user = data['session']['user'];
        }

        if (user != null) {
           String? role = user['role'];
          if (role == null && user['app_metadata'] != null) {
            role = user['app_metadata']['role'];
          }
          if (role == null && user['user_metadata'] != null) {
            role = user['user_metadata']['role'];
          }

          await _tokenManager.persistUserIdentity(
            role: role,
            email: user['email'],
          );
        }
      }
      return data;
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }

  Future<User> getProfile() async {
    final response = await ApiService.get('/profile');
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.safeJsonDecode(response.body);

      Map<String, dynamic> userMap;
      if (data.containsKey('user')) {
        userMap = data['user'];
      } else {
        userMap = data;
      }

      if (userMap['role'] == null) {
        userMap['role'] = await _tokenManager.getUserRole();
      }
      if (userMap['email'] == null) {
        userMap['email'] = await _tokenManager.getUserEmail();
      }

      return User.fromJson(userMap);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final response = await ApiService.put('/profile', profileData);
    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.safeJsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await ApiService.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });

    if (!ApiService.isSuccessful(response.statusCode)) {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  Future<User> getProfileById(int userId) async {
    final response = await ApiService.get('/users/$userId');

    if (ApiService.isSuccessful(response.statusCode)) {
      final data = ApiService.safeJsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final errorMessage = ApiService.extractErrorMessage(response);
      throw Exception(errorMessage);
    }
  }
}
