// lib/core/auth_helper.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthHelper {
  // serverClientId MUST be the WEB client ID (same one already configured
  // in Supabase's Google provider) — this is what makes the native idToken's
  // audience match what Supabase expects, with zero Supabase-side changes.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
  );

  /// Triggers the native OS account picker — no browser involved at all.
  static Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null)
        return; // user dismissed the picker — not an error

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint("Google Sign-In: no ID token returned");
        return;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      // No manual navigation here — your existing onAuthStateChange
      // listener in main.dart handles routing exactly like every other
      // sign-in method already does (SMS screen → Loading → Dashboard,
      // single-device check, everything stays intact).
    } catch (e) {
      debugPrint("Native Google Sign-In error: $e");
    }
  }

  /// Use this everywhere instead of calling Supabase's signOut() directly.
  /// Without clearing the native Google session too, a Google-linked
  /// account can silently auto-reselect on the next "Continue with
  /// Google" tap instead of showing the picker again.
  static Future<void> _clearActiveDevice() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'active_device_id': null, 'active_device_updated_at': null})
          .eq('id', user.id)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint("Couldn't clear active device on logout: $e");
    }
  }

  static Future<void> signOutEverywhere({
    SignOutScope scope = SignOutScope.local,
  }) async {
    await _clearActiveDevice(); // must run BEFORE signOut, while we still have a valid session/uid
    try {
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google native sign-out skipped: $e");
    }
    await Supabase.instance.client.auth.signOut(scope: scope);
  }
}
