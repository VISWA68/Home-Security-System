import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://your_server_ip:5000'; // Replace with your server IP

  // Register a face
  static Future<Map<String, dynamic>> registerFace(String base64Image, String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register_face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register face: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering face: $e');
    }
  }

  // Detect face
  static Future<Map<String, dynamic>> detectFace(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/detect_face'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to detect face: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error detecting face: $e');
    }
  }
}
