// lib/core/system_ui_service.dart
//
// REVISED APPROACH (Android 12+ / One UI 6 compatible)
//
// Why the old approach failed:
//   systemNavigationBarColor is ignored on Android 12+ (API 31+). Google
//   deprecated its visual effect and Samsung One UI 6 enforces this strictly
//   — the color call is silently dropped.
//
// New strategy:
//   1. Keep the nav bar TRANSPARENT at the native layer (done in MainActivity.kt).
//   2. Use Flutter's SystemUiOverlayStyle only for ICON BRIGHTNESS (light/dark icons).
//   3. The Scaffold's backgroundColor naturally fills behind the nav bar because
//      the window is edge-to-edge — making it LOOK opaque with no color API needed.
//
// What each screen must do:
//   - StatefulWidget  → call applyNavBarStyle(context) in didChangeDependencies()
//   - StatelessWidget → call applyNavBarStyle(context) at the top of build()
//   Both also call it again inside their ValueListenableBuilder for theme changes.
//
// Screens that use a green/dark background (WelcomeScreen, etc.) will
// automatically show green behind the nav keys — no extra work needed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIService {
  /// Sets nav bar ICON brightness to match the current theme.
  /// The background color is transparent (set in MainActivity.kt) so the
  /// Scaffold's own background fills the nav bar area naturally.
  static void applyNavBarStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // ── Android navigation bar ───────────────────────────────────────
        // Color is intentionally transparent — MainActivity.kt handles this
        // at the native level. Setting it here would be ignored on API 31+
        // anyway. We only control icon brightness.
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false, // critical for Samsung
        // ── Status bar ───────────────────────────────────────────────────
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}