import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> checkBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      final isAvailable = await checkBiometrics();
      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometrics not available on this device')),
        );
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to register your face',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error authenticating: $e');
      return false;
    }
  }

  void showAuthenticationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Biometric authentication failed')),
    );
  }
}
