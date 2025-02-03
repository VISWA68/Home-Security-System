import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

class ApiService {
  final String baseUrl = "http://192.168.219.231:8000"; 
  late IOWebSocketChannel channel;

  Future<String> registerFace(String imagePath, String userName) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      body: jsonEncode({"image_path": imagePath, "user_name": userName}),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    return data.containsKey("success") ? data["success"] : data["error"];
  }

  Future<String> deleteFace(String userName) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/delete"),
      body: jsonEncode({"user_name": userName}),
      headers: {"Content-Type": "application/json"},
    );

    final data = jsonDecode(response.body);
    return data.containsKey("success") ? data["success"] : data["error"];
  }

  void startRecognition(void Function(String) onData) {
    channel = IOWebSocketChannel.connect("ws://192.168.219.231/ws");

    channel.stream.listen((message) {
      final response = jsonDecode(message);
      onData(response.containsKey("status") ? response["status"] : response["error"] ?? "Unknown Error");
    });

    channel.sink.add(jsonEncode({"action": "start"}));
  }

  void closeConnection() {
    channel.sink.close();
  }
}
