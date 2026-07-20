import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/user_profile.dart';
import 'package:spentree/screens/main_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import 'package:spentree/core/user_data.dart';

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
    _startLoadingSequence();
    _syncData();
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
        .from('users').select('id, name, legal_consent').eq('id', user.id).maybeSingle();

    final Map<String, dynamic> payload = {'id': user.id};

    final existingName = existing?['name'] as String?;
    if (existingName == null || existingName.trim().isEmpty) {
      payload['name'] = user.userMetadata?['full_name'] ?? 'New User';
    }

    final existingConsent = existing?['legal_consent'] as bool?;
    if (existingConsent != true) {
      payload['legal_consent'] = true;
      payload['legal_consent_at'] = DateTime.now().toUtc().toIso8601String();
      payload['legal_version'] = 'v1.0';
    }

    await Supabase.instance.client.from('users').upsert(payload);

    // --- NEW: restore encrypted profile fields from cloud, cloud always wins ---
    final decryptedFields = await AuthHelper.fetchDecryptedUserFields();
    final hasCloudProfile = decryptedFields != null &&
        (decryptedFields['daily_limit'] != null ||
         decryptedFields['goal'] != null ||
         decryptedFields['category_preference'] != null);

    if (hasCloudProfile) {
      // Existing account — cloud is authoritative. Restore locally,
      // skip pushing any locally-cached questionnaire/default values up.
      final cloudLimit = decryptedFields['daily_limit'] as String?;
      final cloudGoal = decryptedFields['goal'] as String?;
      final cloudCategory = decryptedFields['category_preference'] as String?;

      await UserData.saveQuestionnaireData(
        dailyLimitValue: cloudLimit ?? UserData.dailyLimit,
        category: cloudCategory ?? UserData.spendingCategory,
        goal: cloudGoal ?? UserData.spendingGoal,
      );
      if (cloudLimit != null) {
        final parsed = int.tryParse(cloudLimit);
        if (parsed != null) await prefs.setInt('daily_expense_limit', parsed);
      }
      await prefs.setBool('questionnaire_sync_pending', false); // never push local over cloud

      final imageUrl = decryptedFields['profile_image_url'] as String?;
      if (imageUrl != null) {
        try {
          final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            await userProfileNotifier.updateImage(response.bodyBytes);
          }
        } catch (e) {
          debugPrint("Couldn't restore profile image: $e");
        }
      }
    } else if (pendingSync) {
      // Genuinely brand-new — push local questionnaire answers up as before.
      try {
        await Supabase.instance.client.functions.invoke('encrypt-user-fields', body: {
          'daily_limit': UserData.dailyLimit,
          'category_preference': UserData.spendingCategory,
          'goal': UserData.spendingGoal,
        }).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Couldn't sync encrypted questionnaire fields: $e");
      }
      await prefs.setBool('questionnaire_sync_pending', false);
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
