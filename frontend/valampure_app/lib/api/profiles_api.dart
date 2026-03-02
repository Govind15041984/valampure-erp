import 'dart:convert';
import 'package:http/http.dart';
import 'client_api.dart';
import '../core/auth_storage.dart';

class ProfilesApi {
  // USE: Creates a new business account.
  // WHEN: Triggered from the Signup Screen.
  static Future<bool> signup(Map<String, dynamic> userData) async {
    // ApiClient already uses kBaseUrl from config_api
    final response = await ApiClient.post('/auth/signup', userData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Signup failed');
    }
  }

  // USE: Authenticates and saves the session.
  // WHEN: Triggered on the PinScreen.
  static Future<bool> login(String mobile, String pin) async {
    final response = await ApiClient.post('/auth/login', {
      'mobile': mobile,
      'pin': pin,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save Token & User ID securely
      await AuthStorage.instance.saveToken(data['access_token']);
      if (data['user'] != null) {
        await AuthStorage.instance.saveUserId(data['user']['id'].toString());
      }
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  // USE: Updates business details like GST/Bank.
  // WHEN: Triggered from Business Settings.
  static Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    final response = await ApiClient.put('/auth/update', updateData);

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Update failed');
    }
  }
}
