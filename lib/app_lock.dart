import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_style.dart';
import 'core/biometric_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lock state machine — single source of truth for the entire app.
//
//  unlocked       → content visible, all interaction enabled
//  locked         → blur overlay showing, awaiting user tap to trigger auth
//  authenticating → auth dialog is open, overlay stays, taps absorbed
// ─────────────────────────────────────────────────────────────────────────────
enum AppLockState { unlocked, locked, authenticating }

// ---------------------------------------------------------------------------
// Global notifier — readable from anywhere, mutated only by AppLockController.
// ---------------------------------------------------------------------------
final ValueNotifier<AppLockState> appLockNotifier =
    ValueNotifier(AppLockState.locked); // pessimistic until prefs load

// ---------------------------------------------------------------------------
// AppLockController — thin static façade so callers never touch the notifier
// directly and don't need to hold a reference to the widget tree.
// ---------------------------------------------------------------------------
class AppLockController {
  AppLockController._();

  static bool _lockEnabled = false;

  // Tracks whether the PREVIOUS lifecycle transition was a genuine background
  // event (as opposed to the biometric dialog itself causing `inactive`).
  static bool _wentToBackground = false;

  /// Must be called once at startup before runApp.
  /// Reads SharedPreferences and sets the initial lock state.
  /// Pessimistic default (locked) is already set on the notifier declaration.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;

    if (!_lockEnabled) {
      appLockNotifier.value = AppLockState.unlocked;
    }
    // If enabled, stay locked — AppLockWrapper triggers auth on first frame.
  }

  static bool get lockEnabled => _lockEnabled;

  /// Called by AccountScreen when the user toggles the Face ID switch.
  /// Writes to SharedPreferences AND updates the global notifier atomically.
  static Future<void> setLockEnabled(bool enabled) async {
    _lockEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFaceIdEnabled', enabled);
    if (!enabled) {
      appLockNotifier.value = AppLockState.unlocked;
    }
  }

  /// Re-reads the preference from disk (e.g. after returning from settings).
  static Future<void> reloadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
    if (!_lockEnabled) {
      appLockNotifier.value = AppLockState.unlocked;
    }
  }

  // ── Lifecycle hooks — called from AppLockWrapper's observer ────────────

  static void onAppInactive() {
    // `inactive` fires for both "app going to background" AND "biometric
    // dialog appeared". We only lock if we were previously unlocked.
    if (_lockEnabled && appLockNotifier.value == AppLockState.unlocked) {
      appLockNotifier.value = AppLockState.locked;
      _wentToBackground = true;
    }
  }

  static void onAppPaused() {
    // `paused` is the definitive "app is in background" signal.
    // Lock here too so the recents snapshot is always protected.
    if (_lockEnabled && appLockNotifier.value == AppLockState.unlocked) {
      appLockNotifier.value = AppLockState.locked;
    }
    _wentToBackground = true;
  }

  static Future<void> onAppResumed() async {
    await reloadPreference();

    if (_lockEnabled &&
        _wentToBackground &&
        appLockNotifier.value == AppLockState.locked) {
      _wentToBackground = false;
      await _triggerAuth();
    } else if (!_lockEnabled) {
      appLockNotifier.value = AppLockState.unlocked;
      _wentToBackground = false;
    } else {
      _wentToBackground = false;
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────

  /// Triggers a single authentication attempt. No-ops if already authenticating.
  static Future<void> triggerAuth() => _triggerAuth();

  static Future<void> _triggerAuth() async {
    if (appLockNotifier.value == AppLockState.authenticating) return;
    appLockNotifier.value = AppLockState.authenticating;

    // Reset background flag BEFORE the dialog opens so the `inactive` event
    // the dialog causes does not re-lock us.
    _wentToBackground = false;

    final result = await BiometricService.authenticate();

    if (result == AuthResult.success) {
      appLockNotifier.value = AppLockState.unlocked;
    } else {
      // Failure / cancel → stay locked, user taps to retry.
      appLockNotifier.value = AppLockState.locked;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLockWrapper
//
// Wraps the child passed by MaterialApp's `builder` parameter in a Stack.
// The lock overlay sits at the TOP of that stack, above every route,
// dialog, bottom sheet, and popup — because it is outside the Navigator.
//
// Placement in main.dart:
//   builder: (context, child) => AppLockWrapper(child: child!)
//
// The `builder` layer sits above the Navigator so showDialog / showModalBottomSheet
// overlays are also covered. No screen or popup can slip through.
// ─────────────────────────────────────────────────────────────────────────────
class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Trigger auth on first frame if lock is enabled (cold launch).
    if (AppLockController.lockEnabled &&
        appLockNotifier.value == AppLockState.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppLockController.triggerAuth();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        AppLockController.onAppInactive();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        AppLockController.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        AppLockController.onAppResumed();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLockState>(
      valueListenable: appLockNotifier,
      builder: (context, lockState, _) {
        final isLocked = lockState != AppLockState.unlocked;
        return Stack(
          children: [
            // ── Full app content (entire navigator + all routes) ─────────
            widget.child,

            // ── Global lock overlay ──────────────────────────────────────
            // Sits ABOVE widget.child which is the full MaterialApp navigator,
            // covering routes, dialogs, sheets, and popups alike.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLocked
                  ? _GlobalLockOverlay(
                      key: const ValueKey('lock'),
                      onTapUnlock: lockState == AppLockState.locked
                          ? AppLockController.triggerAuth
                          : null, // absorb taps while dialog is open
                    )
                  : const SizedBox.shrink(key: ValueKey('unlocked')),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlobalLockOverlay
//
// Covers the full screen including system navigation bar area because it
// lives outside Scaffold. Visually identical to the old _LockOverlay.
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalLockOverlay extends StatelessWidget {
  /// Called when user taps to unlock. Null during active auth (taps absorbed).
  final VoidCallback? onTapUnlock;

  const _GlobalLockOverlay({super.key, this.onTapUnlock});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    final overlayColor = isDark
        ? const Color(0xFF121212).withOpacity(0.92)
        : Colors.white.withOpacity(0.88);

    return PopScope(
      // Prevent back button/gesture from dismissing the lock screen
      canPop: false,
      child: GestureDetector(
        // Tap anywhere on overlay to retry auth
        onTap: onTapUnlock,
        child: AbsorbPointer(
          absorbing: true,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: overlayColor,
              child: SafeArea(
                child: Center(
                  child: Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}