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

    return response; // We can add the status handler here later
  }

  // USE: Global "Guard" to handle Account Deactivation or Expiry.
  // WHEN: Runs after every request before the data reaches your UI.
  static http.Response _processResponse(http.Response response) {
    if (response.statusCode == 403) {
      // Logic for Valampure: If the backend says 403, the account is
      // either deactivated or the support date has expired.
      final errorData = jsonDecode(response.body);
      print("⚠️ ACCESS DENIED: ${errorData['detail']}");

      // Peer Tip: You can trigger a Logout event here later
      // to force the user back to the login screen.
    }
    return response;
  }
}
