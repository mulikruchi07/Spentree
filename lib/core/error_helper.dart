import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> checkInternetConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result.any((r) => r != ConnectivityResult.none);
}

String mapAuthError(Object e) {
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return "No account found with that email and password.";
    }
    if (msg.contains('password')) {
      return "Password must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a symbol.";
    }
    if (msg.contains('confirmation') ||
        msg.contains('sending') ||
        e.code == 'unexpected_failure') {
      return "We couldn't send the verification email right now. Please try again in a moment.";
    }
    if (msg.contains('rate limit') || msg.contains('security')) {
      return "Too many attempts. Please wait a moment and try again.";
    }
    return "Something went wrong. Please try again.";
  }
  return "Something went wrong. Please try again.";
}
