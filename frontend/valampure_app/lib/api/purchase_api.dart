import 'dart:convert';
import 'package:http/http.dart' as http;
import 'client_api.dart';
import 'dart:typed_data';

class PurchaseApi {
  // 1. GET PRESIGNED URL
  // Asks the backend for permission to upload a file to MinIO
  static Future<Map<String, dynamic>> getPresignedUrl(String extension) async {
    try {
      final response = await ApiClient.get(
        '/uploads/presign-purchase?file_ext=$extension',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get upload permission');
      }
    } catch (e) {
      print("DEBUG: getPresignedUrl Error -> $e");
      rethrow;
    }
  }

  // 2. UPLOAD TO MINIO
  // Sends the file bytes directly to MinIO using the presigned URL
  static Future<void> uploadToMinio(
    String uploadUrl,
    Uint8List fileBytes,
  ) async {
    try {
      // Use the bytes directly instead of file.readAsBytes()
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: fileBytes,
        headers: {"Content-Type": "application/octet-stream"},
      );

      if (response.statusCode != 200) {
        throw Exception("MinIO Upload Failed: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("DEBUG: uploadToMinio Error -> $e");
      rethrow;
    }
  }

  // 3. CREATE PURCHASE ENTRY
  // Sends the JSON data (including the temp_object_name) to Postgres
  static Future<bool> createPurchase(Map<String, dynamic> data) async {
    print("DEBUG: Sending to /purchases/create -> $data");

    try {
      final response = await ApiClient.post('/purchases/create', data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Purchase Backend Error: ${error['detail']}");
        return false;
      }
    } catch (e) {
      print("DEBUG: createPurchase Error -> $e");
      rethrow;
    }
  }
}
