import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class TokenManager {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.deleteAll();
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  Future<void> setUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userString = await _storage.read(key: _userKey);
    if (userString != null) {
      return jsonDecode(userString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<int?> getUserId() async {
    final user = await getUser();
    return user?['id'];
  }

  Future<String?> getUserRole() async {
    final user = await getUser();
    return user?['role'];
  }
}
