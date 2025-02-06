import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_app/provider/detection_provider.dart';
import 'package:security_app/services/api_services.dart';

class DetectionDisplay extends StatelessWidget {
  const DetectionDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ApiService _apiservice = ApiService();
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _apiservice.startRecognition,
                    child: Text("Start"))
              ],
            ),
          )
        ],
      ),
    );
  }
}
