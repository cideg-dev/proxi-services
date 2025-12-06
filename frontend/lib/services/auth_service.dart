import 'dart:async';
import 'dart:convert';
import 'package:frontend/services/supabase_functions_service.dart';
import 'package:frontend/services/token_manager.dart';
import 'package:frontend/models/user_model.dart';

class AuthService {
  final SupabaseFunctionsService _functionsService = SupabaseFunctionsService();
  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _functionsService.signin(
      email: email,
      password: password,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String? token;
      if (data.containsKey('token')) {
        token = data['token'];
      } else if (data.containsKey('access_token')) {
        token = data['access_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        token = data['session']['access_token'];
      }

      if (token != null) {
        await _tokenManager.setToken(token);
        
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
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Failed to login';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to login: ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String role, Map<String, dynamic> profileData, {String? referralCode}) async {
    if (referralCode != null && referralCode.isNotEmpty) {
      profileData['referralCode'] = referralCode;
    }

    final response = await _functionsService.signup(
      email: email,
      password: password,
      role: role,
      profileData: profileData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      String? token;
      if (data.containsKey('token')) {
        token = data['token'];
      } else if (data.containsKey('access_token')) {
        token = data['access_token'];
      } else if (data.containsKey('session') && data['session'] is Map) {
        token = data['session']['access_token'];
      }

      if (token != null) {
        await _tokenManager.setToken(token);
        
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
      try {
        final errorBody = jsonDecode(response.body);
        if (response.statusCode == 400 && errorBody.containsKey('errors')) {
          final errors = (errorBody['errors'] as List).map((e) => e['msg'] as String).join('\n');
          throw Exception(errors);
        } else {
          final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Failed to register';
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

  Future<User> getProfile() async {
    final response = await _functionsService.getUserProfile();
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
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
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Failed to load profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to load profile: ${response.body}');
      }
    }
  }

  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _functionsService.updateUserProfile(profileData);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Failed to update profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await _functionsService.proxyToFunction(
      'auth', 
      '/change-password', 
      'POST',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }
    );
    
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? body['error'] ?? 'Échec de la mise à jour du mot de passe');
      } catch (e) {
        throw Exception('Échec de la mise à jour du mot de passe: ${response.body}');
      }
    }
  }

  Future<User> getProfileById(int userId) async {
    final response = await _functionsService.proxyToFunction(
      'profile', 
      '/$userId', 
      'GET'
    );
    
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? errorBody['error'] ?? 'Failed to load profile';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Failed to load profile: ${response.body}');
      }
    }
  }
}
