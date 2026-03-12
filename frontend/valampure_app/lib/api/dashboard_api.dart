import 'dart:async';
import 'dart:convert';
import 'client_api.dart';

class DashboardApi {
  static Future<Map<String, dynamic>> getSummary() async {
    try {
      // Added a timeout of 10 seconds because the new backend logic
      // involves more complex calculations (ageing, top customers)
      final response = await ApiClient.get(
        '/dashboard/summary',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Basic Validation: Ensure critical keys exist so the UI doesn't crash
        if (data.containsKey('finance') && data.containsKey('growth')) {
          return data;
        } else {
          throw Exception('Dashboard data structure is incomplete');
        }
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Dashboard Backend Error: ${error['detail']}");
        throw Exception('Failed to load dashboard summary');
      }
    } on TimeoutException catch (_) {
      throw Exception(
        'Server is taking too long to respond. Check your connection.',
      );
    } catch (e) {
      print("DEBUG: Dashboard getSummary Error -> $e");
      rethrow;
    }
  }
}
