import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class DetectionResponse {
  final String status;
  final String? user;
  final String? error;

  DetectionResponse({
    required this.status,
    this.user,
    this.error,
  });
}

class DetectionProvider with ChangeNotifier {
  bool _isDetecting = false;
  DetectionResponse? _lastResponse;
  IOWebSocketChannel? _channel;

  bool get isDetecting => _isDetecting;
  DetectionResponse? get lastResponse => _lastResponse;

  void startDetection() {
    if (_isDetecting) return;

    try {
      _channel = IOWebSocketChannel.connect(
        'ws://192.168.219.231:8000/ws',
      );

      _isDetecting = true;
      notifyListeners();

      // Send start command
      _channel?.sink.add(json.encode({"action": "start"}));

      // Listen for responses
      _channel?.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _lastResponse = DetectionResponse(
              status: data['status'] ?? 'unknown',
              user: data['user'],
              error: data['error'],
            );
            notifyListeners();
          } catch (e) {
            print('Error parsing message: $e');
            _lastResponse = DetectionResponse(
              status: 'error',
              error: 'Failed to parse server response',
            );
            notifyListeners();
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _lastResponse = DetectionResponse(
            status: 'error',
            error: 'WebSocket connection error',
          );
          _isDetecting = false;
          notifyListeners();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isDetecting = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _lastResponse = DetectionResponse(
        status: 'error',
        error: 'Failed to connect to server',
      );
      _isDetecting = false;
      notifyListeners();
    }
  }

  void stopDetection() {
    if (!_isDetecting) return;

    try {
      // Send stop command before closing
      _channel?.sink.add(json.encode({"action": "stop"}));

      // Close the WebSocket connection
      _channel?.sink.close();
      _channel = null;
      _isDetecting = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping detection: $e');
      _lastResponse = DetectionResponse(
        status: 'error',
        error: 'Failed to stop detection',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopDetection();
    super.dispose();
  }
}
