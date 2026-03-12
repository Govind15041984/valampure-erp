import 'dart:convert';
import 'client_api.dart';

class ManufacturingApi {
  // USE: Sends the manufacturing log (description, size, boxes, mts) to the server.
  // WHEN: Triggered when the staff/owner clicks "SAVE PRODUCTION" on the form.
  static Future<bool> logProduction(Map<String, dynamic> data) async {
    print("DEBUG: Sending to /manufacturing/log-entry -> $data");

    try {
      final response = await ApiClient.post('/manufacturing/log-entry', data);

      print("DEBUG: Log Response Code: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Backend Error Detail: ${error['detail']}");
        throw Exception(error['detail'] ?? 'Failed to save manufacturing');
      }
    } catch (e) {
      print("DEBUG: logProduction Error -> $e");
      rethrow;
    }
  }

  // USE: Fetches the real-time "Bank Balance" of all elastic sizes.
  // WHEN: Triggered when the Dashboard or Inventory screen loads.
  static Future<List<dynamic>> getCurrentStock() async {
    try {
      final response = await ApiClient.get('/manufacturing/current-stock');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("DEBUG: Stock Fetch Error -> ${response.body}");
        return [];
      }
    } catch (e) {
      print("DEBUG: getCurrentStock Error -> $e");
      rethrow;
    }
  }

  // USE: Fetches the historical list of manufacturing runs.
  // WHEN: Triggered on the "Production History" screen.
  static Future<List<dynamic>> getProductionHistory() async {
    try {
      final response = await ApiClient.get('/manufacturing/history');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("DEBUG: History Fetch Error -> ${response.body}");
        return [];
      }
    } catch (e) {
      print("DEBUG: getProductionHistory Error -> $e");
      rethrow;
    }
  }
}
