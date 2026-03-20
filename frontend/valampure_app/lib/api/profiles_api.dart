import 'dart:convert';
import 'dart:io'; // Needed for File
import 'dart:typed_data'; // Required for Uint8List
import 'package:http/http.dart' as http; // Needed for direct MinIO PUT
import 'client_api.dart';
import '../core/auth_storage.dart';

class ProfilesApi {
  // 1. GET THE PRESIGNED URL
  // Called before uploading the image to MinIO
  static Future<Map<String, dynamic>> getLogoUploadUrl() async {
    try {
      // Calls your new @router.get("/logo-upload-url")
      final response = await ApiClient.get('/auth/logo-upload-url');

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // {upload_url, object_name, file_url}
      } else {
        throw Exception('Failed to get upload signature');
      }
    } catch (e) {
      print("DEBUG: getLogoUploadUrl Error -> $e");
      rethrow;
    }
  }

  // 2. UPLOAD IMAGE DIRECTLY TO MINIO
  // This bypasses FastAPI to handle large files efficiently
  static Future<void> uploadToMinio(String uploadUrl, Uint8List bytes) async {
    try {
      // We send the raw bytes directly.
      // This avoids 'dart:io' which causes the 'Unsupported operation' error on Web.
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': 'image/png', // MinIO requires this for presigned PUT
        },
      );

      if (response.statusCode != 200) {
        // It's helpful to see the body if MinIO rejects the request (e.g., CORS or Expired URL)
        print("DEBUG: MinIO Error Body -> ${response.body}");
        throw Exception("MinIO Upload Failed: ${response.statusCode}");
      }

      print("DEBUG: Image uploaded to MinIO successfully");
    } catch (e) {
      print("DEBUG: uploadToMinio Error -> $e");
      rethrow;
    }
  }

  // --- EXISTING METHODS (KEEP THESE) ---

  static Future<bool> checkUser(String mobile) async {
    try {
      final response = await ApiClient.get('/auth/check-user/$mobile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> signup(Map<String, dynamic> userData) async {
    final response = await ApiClient.post('/auth/signup', userData);
    if (response.statusCode == 200 || response.statusCode == 201) return true;
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Signup failed');
  }

  static Future<bool> login(String mobile, String pin) async {
    final response = await ApiClient.post('/auth/login', {
      'mobile': mobile,
      'pin': pin,
    });

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
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  // UPDATED: updateProfile (Now handles the data map containing logo_temp_name)
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
    final response = await ApiClient.get('/auth/me');
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load profile details');
  }
}
