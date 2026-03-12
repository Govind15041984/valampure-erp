import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/auth_storage.dart';
import 'config_api.dart';

// USE: Centralized API engine for Valampure ERP.
// WHEN: Used for every single network call to ensure JWT is attached
//       and account status (Active/Expiry) is checked.
class ApiClient {
  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthStorage.instance.getToken();

    final response = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  static Future<http.Response> get(String path) async {
    final token = await AuthStorage.instance.getToken();

    final response = await http.get(
      Uri.parse('$kBaseUrl$path'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    return _processResponse(response);
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthStorage.instance.getToken();

    final response = await http.put(
      Uri.parse('$kBaseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _processResponse(response); // Now handling status here too
  }

  // NEW: Added Patch method for partial updates (e.g., updating Partner details)
  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthStorage.instance.getToken();

    final response = await http.patch(
      Uri.parse('$kBaseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return _processResponse(response);
  }

  // USE: Global "Guard" to handle Account Deactivation or Expiry.
  // WHEN: Runs after every request before the data reaches your UI.
  static http.Response _processResponse(http.Response response) {
    if (response.statusCode == 403) {
      // Logic for Valampure: If the backend says 403, the account is
      // either deactivated or the support date has expired.
      try {
        final errorData = jsonDecode(response.body);
        print("⚠️ ACCESS DENIED: ${errorData['detail']}");
      } catch (e) {
        print("⚠️ ACCESS DENIED: Unknown error");
      }

      // Peer Tip: You can trigger a Logout event here later
      // to force the user back to the login screen.
    }

    // Log unauthorized access (Token expired or invalid)
    if (response.statusCode == 401) {
      print("❌ UNAUTHORIZED: Token is likely expired.");
    }

    return response;
  }

  static Future<http.Response> delete(String path) async {
    final token = await AuthStorage.instance.getToken();

    final response = await http.delete(
      Uri.parse('$kBaseUrl$path'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    return _processResponse(response);
  }
}
