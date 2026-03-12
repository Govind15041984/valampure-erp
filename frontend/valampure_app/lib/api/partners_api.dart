import 'dart:convert';
import 'package:http/http.dart' as http;
import 'client_api.dart'; // Assuming this contains your baseUrl and token logic

class PartnersApi {
  static const String _endpoint = '/partners';

  /// 1. Create a New Partner (Supplier or Buyer)
  static Future<bool> createPartner(Map<String, dynamic> partnerData) async {
    try {
      final response = await ApiClient.post(_endpoint, partnerData);

      if (response.statusCode == 201) {
        print("DEBUG: Partner Created Successfully");
        return true;
      } else {
        print("DEBUG: Partner Creation Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("DEBUG: Error in createPartner: $e");
      return false;
    }
  }

  /// 2. Fetch Partners by Type (SUPPLIER or BUYER)
  static Future<List<dynamic>> getPartners(String type) async {
    try {
      // Endpoint becomes /partners/SUPPLIER or /partners/BUYER
      final response = await ApiClient.get('$_endpoint/$type');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("DEBUG: Fetch Partners Failed: ${response.body}");
        return [];
      }
    } catch (e) {
      print("DEBUG: Error in getPartners: $e");
      return [];
    }
  }

  /// 3. Update Partner Details
  //static Future<bool> updatePartner(
  //  String id,
  //  Map<String, dynamic> updateData,
  //) async {
  //  try {
  //    final response = await ApiClient.patch('$_endpoint/$id', updateData);
  //    return response.statusCode == 200;
  //  } catch (e) {
  //    print("DEBUG: Error in updatePartner: $e");
  //    return false;
  //  }
  //}

  static Future<List<dynamic>> getPartnerLedger(String partnerId) async {
    final response = await ApiClient.get('/partners/$partnerId/ledger');
    return jsonDecode(response.body);
  }
}
