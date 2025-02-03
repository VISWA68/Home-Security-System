import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:security_app/model/recognition_response.dart';
import 'package:security_app/services/api_services.dart';

class DetectionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  RecognitionResponse? _lastResponse;
  bool _isDetecting = false;

  RecognitionResponse? get lastResponse => _lastResponse;
  bool get isDetecting => _isDetecting;

  void startDetection() {
    _isDetecting = true;
    _apiService.startRecognition((message) {
      try {
        final Map<String, dynamic> jsonResponse = jsonDecode(message);
        _lastResponse = RecognitionResponse.fromJson(jsonResponse);
        notifyListeners();
      } catch (e) {
        _lastResponse = RecognitionResponse(
          status: 'Error',
          error: e.toString(),
        );
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stopDetection() {
    _isDetecting = false;
    _apiService.closeConnection();
    notifyListeners();
  }

  @override
  void dispose() {
    stopDetection();
    super.dispose();
  }
}