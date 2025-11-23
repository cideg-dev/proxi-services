import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';

class TokenManager {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role'; // New key for user role
  static const _emailKey = 'user_email'; // New key for user email

  String? _userRoleCache; // In-memory cache for user role
  String? _userEmailCache; // In-memory cache for user email

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    // When token is set, clear caches as user might have changed
    _userRoleCache = null;
    _userEmailCache = null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // New method to persist user identity details
  Future<void> persistUserIdentity({String? role, String? email}) async {
    if (role != null) {
      await _storage.write(key: _roleKey, value: role);
      _userRoleCache = role;
    }
    if (email != null) {
      await _storage.write(key: _emailKey, value: email);
      _userEmailCache = email;
    }
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
    _userRoleCache = null; // Clear in-memory cache
    _userEmailCache = null; // Clear in-memory cache
  }

  Future<Map<String, dynamic>> _getDecodedToken() async {
    final token = await getToken();
    if (token != null) {
      return Jwt.parseJwt(token);
    }
    throw Exception('Token not found');
  }

  Future<int?> getUserId() async {
    try {
      final decodedToken = await _getDecodedToken();
      // The user ID is directly in the token payload as 'id'
      if (decodedToken.containsKey('id')) {
        return (decodedToken['id'] as num?)?.toInt();
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user ID: $e');
      return null;
    }
  }

  Future<String?> getUserRole() async {
    if (_userRoleCache != null) return _userRoleCache;

    String? role = await _storage.read(key: _roleKey);
    if (role != null) {
      _userRoleCache = role;
      return role;
    }

    try {
      final decodedToken = await _getDecodedToken();
      if (decodedToken.containsKey('role')) {
        role = decodedToken['role'] as String?;
        if (role != null) {
          _userRoleCache = role;
          await _storage.write(key: _roleKey, value: role);
        }
        return role;
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user role: $e');
      return null;
    }
  }

  // New method to get user email
  Future<String?> getUserEmail() async {
    if (_userEmailCache != null) return _userEmailCache;

    String? email = await _storage.read(key: _emailKey);
    if (email != null) {
      _userEmailCache = email;
      return email;
    }

    try {
      final decodedToken = await _getDecodedToken();
      if (decodedToken.containsKey('email')) {
        email = decodedToken['email'] as String?;
        if (email != null) {
          _userEmailCache = email;
          await _storage.write(key: _emailKey, value: email);
        }
        return email;
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user email: $e');
      return null;
    }
  }
  
  // This method is kept for compatibility in places where the whole user object might be needed
  // but it should be used with caution as it reconstructs the user from the token.
  // It will now also try to get role/email from storage if not in token.
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final decodedToken = await _getDecodedToken();
      // Create a user object from the token payload
      final userMap = <String, dynamic>{};

      // Add properties from the token directly
      if (decodedToken.containsKey('id')) {
        userMap['id'] = decodedToken['id'];
      }
      if (decodedToken.containsKey('email')) {
        userMap['email'] = decodedToken['email'];
      }
      if (decodedToken.containsKey('role')) {
        userMap['role'] = decodedToken['role'];
      }

      // Try to fill missing role/email from storage if not in token
      userMap['role'] ??= await getUserRole();
      userMap['email'] ??= await getUserEmail();

      return userMap.isEmpty ? null : userMap;
    } catch (e) {
      print('Error decoding token or getting user object: $e');
      return null;
    }
  }
}
