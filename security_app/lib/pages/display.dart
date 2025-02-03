import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:security_app/provider/detection_provider.dart';

class DetectionDisplay extends StatelessWidget {
  const DetectionDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        final response = provider.lastResponse;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.isDetecting)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () => provider.startDetection(),
                child: const Text('Start Detection'),
              ),
            if (provider.isDetecting)
              ElevatedButton(
                onPressed: () => provider.stopDetection(),
                child: const Text('Stop Detection'),
              ),
            if (response != null) ...[
              const SizedBox(height: 20),
              Text(
                'Status: ${response.status}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (response.user != null)
                Text(
                  'User: ${response.user}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (response.error != null)
                Text(
                  'Error: ${response.error}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}