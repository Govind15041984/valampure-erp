import 'dart:convert';
import 'package:http/http.dart' as http;
import 'client_api.dart';

class PaymentsApi {
  /// Sends a new payment or receipt to the backend.
  /// [paymentData] should include partner_id, amount, mode, type, date, etc.
  static Future<bool> createPayment(Map<String, dynamic> paymentData) async {
    try {
      // Note: We use '/payments' because that is the prefix in your main.py
      final response = await ApiClient.post('/payments', paymentData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Payment Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("DEBUG: Exception in PaymentsApi.createPayment: $e");
      return false;
    }
  }
}
