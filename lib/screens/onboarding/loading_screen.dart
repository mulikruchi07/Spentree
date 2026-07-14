import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/device_identity.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/user_profile.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/main_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import 'package:spentree/core/user_data.dart';
import '../auth/sign_up_screen.dart';

class LoadingScreen extends StatefulWidget {
  final bool isAuthFlow;
  const LoadingScreen({super.key, required this.isAuthFlow});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  int _textIndex = 0;
  late Timer _timer;
  late AnimationController _rotationController;

  final List<String> _loadingTexts = [
    "Personalizing your forest...",
    "Syncing your spending...",
    "Growing your progress...",
    "Preparing your insights...",
    "Almost there...",
  ];

  @override
void initState() {
  super.initState();
  _rotationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();
  _initFlow();
}

Future<void> _initFlow() async {
  if (widget.isAuthFlow) {
    final canProceed = await _checkSingleDeviceSession();
    if (!canProceed) return; // dialog cancelled — already navigated to SignInScreen
  }
  _startLoadingSequence();
  _syncData();
}

Future<bool> _checkSingleDeviceSession() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return true;
  final deviceId = await DeviceIdentity.getDeviceId();

  try {
    final row = await Supabase.instance.client
        .from('users').select('active_device_id').eq('id', user.id).maybeSingle()
        .timeout(const Duration(seconds: 8));
    final existingDeviceId = row?['active_device_id'] as String?;

    if (existingDeviceId != null && existingDeviceId != deviceId) {
      if (!mounted) return false;
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSingleDeviceDialog(),
      );

      if (shouldContinue != true) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
        return false;
      }
      await Supabase.instance.client.auth
          .signOut(scope: SignOutScope.others)
          .timeout(const Duration(seconds: 10));
    }

    await Supabase.instance.client.from('users').update({
      'active_device_id': deviceId,
      'active_device_updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id).timeout(const Duration(seconds: 8));

    return true;
  } catch (e) {
    debugPrint("Single-device check skipped (offline?): $e");
    return true; // fail open — never block a legitimate login just because of a network hiccup
  }
}

Widget _buildSingleDeviceDialog() {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.bgWhite, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.devices, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 18),
            Text("Signed In Elsewhere", style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.colblack)),
            const SizedBox(height: 8),
            Text(
              "Your account is currently signed in on another device.\n\nContinuing will sign you out from that device.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.grey700, height: 1.5),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.inputFill, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.destructiveRed)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text("Continue", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.colwhite)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _syncData() async {
    // 1. If this is an auth flow, ensure the user row exists
    if (widget.isAuthFlow) {
      final user = Supabase.instance.client.auth.currentUser;
      await _ensureUserExistsInDatabase(user);
    }

    // 2. Initialize sync engine
    await userProfileNotifier
        .initialize(); // ← ADD THIS — refresh name for whoever just signed in
    await TransactionService().resetForNewUser();

    final prefs = await SharedPreferences.getInstance();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await prefs.setBool('onboarding_sync_complete_$userId', true);
    }
  }

  Future<void> _ensureUserExistsInDatabase(User? user) async {
    if (user == null) return;
    try {
      await UserData.loadQuestionnaireData();
      final prefs = await SharedPreferences.getInstance();
      final pendingSync = prefs.getBool('questionnaire_sync_pending') ?? false;

      final existing = await Supabase.instance.client
          .from('users')
          .select('id, name')
          .eq('id', user.id)
          .maybeSingle();

      final Map<String, dynamic> payload = {'id': user.id};

      final existingName = existing?['name'] as String?;
      if (existingName == null || existingName.trim().isEmpty) {
        payload['name'] = user.userMetadata?['full_name'] ?? 'New User';
      }

      final existingConsent = existing?['legal_consent'] as bool?;
      if (existingConsent != true) {
        payload['legal_consent'] = true;
        payload['legal_consent_at'] =
            DateTime.now().toUtc().toIso8601String();
        payload['legal_version'] = 'v1.0';
      }

      // Only push questionnaire answers if they were captured this session
      // and haven't been synced yet — prevents overwriting a returning
      // user's real data with local defaults on a fresh install/device.
      if (pendingSync) {
        payload['daily_limit'] = int.tryParse(UserData.dailyLimit) ?? 5000;
        payload['category_preference'] = UserData.spendingCategory;
        payload['goal'] = UserData.spendingGoal;
      }

      await Supabase.instance.client.from('users').upsert(payload);
      final userRow = await Supabase.instance.client
          .from('users')
          .select('is_active, deactivated_at')
          .eq('id', user.id)
          .maybeSingle();
      if (userRow != null &&
          userRow['is_active'] == false &&
          userRow['deactivated_at'] != null) {
        final deactivatedAt = DateTime.parse(userRow['deactivated_at']);
        if (DateTime.now().toUtc().difference(deactivatedAt).inDays <= 30) {
          await Supabase.instance.client
              .from('users')
              .update({'is_active': true, 'deactivated_at': null})
              .eq('id', user.id);
        }
      }

      if (pendingSync) {
        await prefs.setBool('questionnaire_sync_pending', false);
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  void _startLoadingSequence() {
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (timer) {
      if (_textIndex < _loadingTexts.length - 1) {
        setState(() {
          _textIndex++;
        });
      } else {
        _timer.cancel();
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() async {
    // Wait for the sync engine to finish if it's still running
    await TransactionService().initService();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- CUSTOM ROTATING WHEEL ---
                  RotationTransition(
                    turns: _rotationController,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: 0.25, // Static 75% Arc (Creates the "C" shape)
                        strokeWidth: 8, // Thicker stroke
                        strokeCap: StrokeCap.round, // Curved edges
                        color: AppColors.primaryGreen,
                        backgroundColor:
                            AppColors.inputFill, // Light grey track behind
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- ANIMATED TEXT ---
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Text(
                      _loadingTexts[_textIndex],
                      key: ValueKey<String>(_loadingTexts[_textIndex]),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
