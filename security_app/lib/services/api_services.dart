import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  final String baseUrl =
      "http://192.168.219.231:5000"; 

  Future<String> registerFace(String imagePath, String name) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));

      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      request.fields['name'] = name;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      Map<String, dynamic> jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return "success";
      } else if (response.statusCode == 403) {
        return "spoofing_detected";
      }

      return jsonResponse['error'] ?? "error";
    } catch (e) {
      print('Error in registerFace: $e');
      return "error";
    }
  }

  Future<bool> deleteFace(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': name,
        },
      );

      print('Delete Response Status: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting face: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> startRecognition() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recognize'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 500) {
        return {'error': 'Could not access camera'};
      }

      return {'error': 'Unknown error occurred'};
    } catch (e) {
      print('Error in recognition: $e');
      return {'error': e.toString()};
    }
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking server status: $e');
      return false;
    }
  }
}
