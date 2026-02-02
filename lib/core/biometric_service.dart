import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
// REMOVED the specific android/ios imports that were causing errors

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateUser() async {
    try {
      // Check if hardware is available
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Please verify to enable Spentree App Lock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Fallback to PIN/Pattern if FaceID fails
        ),
        // Simplified messages to avoid dependency errors
      );
    } catch (e) {
      debugPrint("Biometric Error: $e");
      return false;
    }
  }
}
