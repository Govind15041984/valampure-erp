import 'dart:convert';
import 'client_api.dart';
import '../core/auth_storage.dart';

class ProfilesApi {
  // NEW USE: Checks if a mobile number exists in the system.
  // WHEN: Triggered from the MobileScreen when the user clicks 'CONTINUE'.
  static Future<bool> checkUser(String mobile) async {
    try {
      // Calls your FastAPI GET endpoint
      final response = await ApiClient.get('/auth/check-user/$mobile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Returns true if business exists, false if it's a new registration
        return data['exists'] ?? false;
      } else {
        // If the backend returns an error (like 404 or 500), we treat it as not found
        return false;
      }
    } catch (e) {
      print("DEBUG: checkUser Error -> $e");
      // Re-throw so the MobileScreen can show a connection error SnackBar
      rethrow;
    }
  }

  // USE: Creates a new business account.
  // WHEN: Triggered from the Signup Screen.
  static Future<bool> signup(Map<String, dynamic> userData) async {
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
    print("DEBUG: Sending to /auth/login -> mobile: $mobile, pin: $pin");

    // Note: If you haven't changed the backend yet, this sends as JSON body.
    // If your backend still expects Query Params, you'll need to change this
    // to '/auth/login?mobile=$mobile&pin=$pin'
    final response = await ApiClient.post('/auth/login', {
      'mobile': mobile,
      'pin': pin,
    });

    print("DEBUG: Response Code: ${response.statusCode}");
    print("DEBUG: Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      await AuthStorage.instance.saveToken(data['access_token']);
      if (data['user'] != null) {
        await AuthStorage.instance.saveRole(data['user']['role']);
        await AuthStorage.instance.saveUserId(data['user']['id'].toString());
      }
      return true;
    } else {
      final error = jsonDecode(response.body);
      print("DEBUG: Backend Error Detail: ${error['detail']}");
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

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiClient.get('/auth/me');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load profile details');
      }
    } catch (e) {
      print("DEBUG: getProfile Error -> $e");
      rethrow;
    }
  }
}
