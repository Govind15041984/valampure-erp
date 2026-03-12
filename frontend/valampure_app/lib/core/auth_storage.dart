import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  AuthStorage._internal();
  static final AuthStorage instance = AuthStorage._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = "valampure_jwt";
  static const String _userIdKey = "valampure_user_id";
  static const String _roleKey = "valampure_role";

  // SAVE METHODS
  Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);
  Future<void> saveUserId(String userId) async =>
      await _storage.write(key: _userIdKey, value: userId);
  Future<void> saveRole(String role) async =>
      await _storage.write(key: _roleKey, value: role);

  // GET METHODS
  Future<String?> getToken() async => await _storage.read(key: _tokenKey);
  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);
  Future<String?> getRole() async => await _storage.read(key: _roleKey);

  Future<void> clear() async => await _storage.deleteAll();
}
