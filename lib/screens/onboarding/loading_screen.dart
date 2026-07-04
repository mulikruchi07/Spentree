import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/user_profile.dart';
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

    // 1. Setup Rotation Animation (Slower & Smoother)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // 2 Seconds for full rotation
    )..repeat(); // Loop forever

    // 2. Start Text Sequence
    _startLoadingSequence();
    _syncData(); // Trigger sync
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
  }

  Future<void> _ensureUserExistsInDatabase(User? user) async {
    if (user == null) return;
    try {
      await UserData.loadQuestionnaireData();
      final prefs = await SharedPreferences.getInstance();
      final pendingSync = prefs.getBool('questionnaire_sync_pending') ?? false;

      final Map<String, dynamic> payload = {
        'id': user.id,
        'name': user.userMetadata?['full_name'] ?? 'New User',
      };

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
