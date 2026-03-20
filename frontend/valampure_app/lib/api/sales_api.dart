import 'dart:convert';
import 'package:http/http.dart' as http;
import 'client_api.dart';
import 'dart:typed_data';

class SalesApi {
  // 1. GET PRESIGNED URL FOR INVOICE UPLOAD
  // Useful if you want to upload a scanned copy of a signed bill back to the cloud
  static Future<Map<String, dynamic>> getPresignedUrl(String extension) async {
    try {
      final response = await ApiClient.get(
        '/uploads/presign-sales?file_ext=$extension',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get upload permission for sales');
      }
    } catch (e) {
      print("DEBUG: Sales getPresignedUrl Error -> $e");
      rethrow;
    }
  }

  // 2. UPLOAD TO MINIO
  // Sends the invoice file bytes directly to MinIO
  static Future<void> uploadToMinio(
    String uploadUrl,
    Uint8List fileBytes,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: fileBytes,
        headers: {"Content-Type": "application/octet-stream"},
      );

      if (response.statusCode != 200) {
        throw Exception("MinIO Sales Upload Failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("DEBUG: uploadToMinio Error -> $e");
      rethrow;
    }
  }

  // 3. CREATE SALES INVOICE ENTRY
  // This sends the JSON data matching your Pydantic schema to the FastAPI backend.
  // The PostgreSQL trigger will automatically update the Customer's balance.
  static Future<Map<String, dynamic>?> createInvoice(
    Map<String, dynamic> data,
  ) async {
    print("DEBUG: Sending to /sales/create -> ${jsonEncode(data)}");

    try {
      final response = await ApiClient.post('/sales/create', data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("DEBUG: Sales Invoice Created Successfully");
        // Return the decoded JSON body so we can get the 'id'
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Sales Backend Error: ${error['detail']}");
        return null; // Return null if the server rejected it
      }
    } catch (e) {
      print("DEBUG: createInvoice Error -> $e");
      rethrow;
    }
  }

  static Future<String> getNextInvoiceNumber() async {
    try {
      final response = await ApiClient.get('/sales/next-invoice-number');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['next_no'].toString();
      } else {
        print("Error fetching invoice number: ${response.body}");
        return "";
      }
    } catch (e) {
      print("Network Error: $e");
      return "";
    }
  }

  static Future<List<dynamic>> getSalesList({required bool historyMode}) async {
    try {
      // Using your ApiClient.get pattern
      final response = await ApiClient.get(
        '/sales/list?history_mode=$historyMode',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Sales List Fetch Error: ${error['detail']}");
        throw Exception(error['detail'] ?? 'Failed to fetch sales list');
      }
    } catch (e) {
      print("DEBUG: getSalesList Error -> $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSaleDetails(String saleId) async {
    try {
      final response = await ApiClient.get('/sales/detail/$saleId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Sales Detail Fetch Error: ${error['detail']}");
        throw Exception(error['detail'] ?? 'Failed to load invoice details');
      }
    } catch (e) {
      print("DEBUG: getSaleDetails Error -> $e");
      rethrow;
    }
  }
}
