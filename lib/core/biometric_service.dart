import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Result of an authentication attempt.
/// Distinguishes success from failure vs. unavailability so callers
/// can make nuanced decisions without catching exceptions.
enum AuthResult { success, failed, unavailable }

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns whether the device has any enrolled authentication method
  /// (biometric or device credential: PIN, pattern, password).
  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Triggers a single authentication prompt.
  /// Does NOT retry — the caller decides retry policy.
  static Future<AuthResult> authenticate() async {
    try {
      final available = await isAvailable();
      if (!available) return AuthResult.unavailable;

      final success = await _auth.authenticate(
        localizedReason: 'Verify your identity to open Spentree',
        options: const AuthenticationOptions(
          stickyAuth: true,     // Keeps dialog alive if user switches app mid-auth
          biometricOnly: false, // Allows PIN/pattern fallback
          useErrorDialogs: true,
        ),
      );
      return success ? AuthResult.success : AuthResult.failed;
    } catch (e) {
      debugPrint('BiometricService error: $e');
      return AuthResult.failed;
    }
  }

  /// Cancels any in-progress authentication.
  static Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}