import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// USE: Securely stores the JWT token and user identity in the device's keychain.
// WHEN: Triggered after a successful login or when checking if a session is still valid.
class AuthStorage {
  AuthStorage._internal();
  static final AuthStorage instance = AuthStorage._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Updated key name for Valampure
  static const String _tokenKey = "valampure_jwt";
  static const String _userIdKey = "valampure_user_id";

  // USE: Saves the token after a successful /login response.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // USE: Saves the user ID so we know which business profile to fetch.
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // USE: Used by ApiClient to attach the 'Bearer' token to headers.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // USE: Completely wipes user data.
  // WHEN: Triggered on Logout or when a 403 (Expiry) error is detected.
  Future<void> clear() async {
    await _storage.deleteAll(); // Clears everything (token and user ID)
  }
}
