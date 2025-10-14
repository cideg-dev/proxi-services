import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';

class TokenManager {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
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
      // The user ID is nested within a 'user' object in the payload
      if (decodedToken.containsKey('user') && decodedToken['user'] is Map) {
        return (decodedToken['user']['id'] as num?)?.toInt();
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user ID: $e');
      return null;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final decodedToken = await _getDecodedToken();
      // The role is nested within a 'user' object in the payload
      if (decodedToken.containsKey('user') && decodedToken['user'] is Map) {
        return decodedToken['user']['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user role: $e');
      return null;
    }
  }
  
  // This method is kept for compatibility in places where the whole user object might be needed
  // but it should be used with caution as it reconstructs the user from the token.
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final decodedToken = await _getDecodedToken();
      if (decodedToken.containsKey('user') && decodedToken['user'] is Map) {
        return decodedToken['user'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error decoding token or getting user object: $e');
      return null;
    }
  }
}
