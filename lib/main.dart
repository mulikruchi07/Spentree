import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/device_identity.dart';
import 'package:spentree/core/notification_service.dart';
import 'package:spentree/screens/onboarding/set_daily_limit_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/core/database/local_database_service.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/screens/main_wrapper.dart';
import 'package:spentree/screens/onboarding/loading_screen.dart';
import 'package:spentree/screens/onboarding/splash_onboarding_screen.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'app_lock.dart';
import 'core/user_profile.dart';
import 'core/app_style.dart';
import 'package:spentree/screens/onboarding/sms_permission_screen.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'sms_received') {
    await TransactionService().initService();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String _smsPermissionDecisionKey(String userId) {
  return 'sms_permission_decision_$userId';
}

String _onboardingSyncCompleteKey(String userId) {
  return 'onboarding_sync_complete_$userId';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      final canProceed = await _checkSingleDeviceSession(null);
      if (!canProceed) return;

      final myDeviceId = await DeviceIdentity.getDeviceId();
      _watchForRemoteLogout(session.user.id, myDeviceId);

      final prefs = await SharedPreferences.getInstance();
      final hasDecidedSms =
          prefs.getBool('has_seen_sms_permission_screen_${session.user.id}') ??
          false;
      final nextAfterLimit = hasDecidedSms
          ? const LoadingScreen(isAuthFlow: true)
          : const SmsPermissionScreen(isOnboarding: true);

      final needsLimit = await _needsSetDailyLimit();

      navigatorKey.currentState?.pushAndRemoveUntil(
        needsLimit
            ? MaterialPageRoute(
                builder: (context) =>
                    SetDailyLimitScreen(nextScreen: nextAfterLimit),
              )
            : MaterialPageRoute(builder: (context) => nextAfterLimit),
        (route) => false,
      );
    } else if (event == AuthChangeEvent.signedOut) {
      _deviceWatchChannel?.unsubscribe();
      _deviceWatchChannel = null;
    }
  });

  await LocalDatabaseService.initialize();
  await AppLockController.initialize();
  await loadSavedTheme();
  await userProfileNotifier.initialize();

  if (!kIsWeb) {
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    await TransactionService().initService();
    const platform = MethodChannel('spentree_widget_channel');
    platform.setMethodCallHandler((call) async {
      if (call.method == "themeChanged") {
        await TransactionService().syncWidget();
      }
    });
  }

  // Decide the start screen: signed in -> app; signed out but has used the
  // app before -> sign in directly; brand new device -> onboarding/splash.
  final session = Supabase.instance.client.auth.currentSession;
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      prefs.getBool('has_completed_onboarding') ?? false;

  Widget startScreen;
  if (session != null) {
    final userId = session.user.id;
    final hasDecidedSms = prefs.containsKey(_smsPermissionDecisionKey(userId));
    final hasCompletedSync =
        prefs.getBool(_onboardingSyncCompleteKey(userId)) ?? false;
    final needsLimit = await _needsSetDailyLimit();

    if (needsLimit) {
      final nextAfterLimit = hasDecidedSms
          ? const LoadingScreen(isAuthFlow: true)
          : const SmsPermissionScreen(isOnboarding: true);
      startScreen = SetDailyLimitScreen(nextScreen: nextAfterLimit);
    } else if (!hasDecidedSms) {
      startScreen = const SmsPermissionScreen(isOnboarding: true);
    } else if (!hasCompletedSync) {
      startScreen = const LoadingScreen(isAuthFlow: true);
    } else {
      startScreen = const MainWrapper();
    }
  } else if (hasCompletedOnboarding) {
    startScreen = const SignInScreen();
  } else {
    startScreen = const SplashOnboardingScreen();
  }
  await NotificationService.initialize();

  runApp(MyApp(startScreen: startScreen));
}

RealtimeChannel? _deviceWatchChannel;

void _watchForRemoteLogout(String userId, String myDeviceId) {
  _deviceWatchChannel?.unsubscribe();
  _deviceWatchChannel = Supabase.instance.client
      .channel('user-device-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) async {
          final newDeviceId = payload.newRecord['active_device_id'] as String?;
          if (newDeviceId != null && newDeviceId != myDeviceId) {
            await Supabase.instance.client.auth.signOut(
              scope: SignOutScope.local,
            );
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const SignInScreen()),
              (route) => false,
            );
          }
        },
      )
      .subscribe();
}

Future<bool> _checkSingleDeviceSession(BuildContext? navContext) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return true;
  final deviceId = await DeviceIdentity.getDeviceId();

  try {
    final row = await Supabase.instance.client
        .from('users')
        .select('active_device_id')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));
    final existingDeviceId = row?['active_device_id'] as String?;

    if (existingDeviceId != null && existingDeviceId != deviceId) {
      final context = navContext ?? navigatorKey.currentContext;
      if (context == null) return true;
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSingleDeviceDialog(context),
      );
      if (shouldContinue != true) {
        await AuthHelper.signOutEverywhere();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
        return false;
      }
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.others);
    }

    await Supabase.instance.client
        .from('users')
        .upsert({
          'id': user.id,
          'active_device_id': deviceId,
          'active_device_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(const Duration(seconds: 8));

    return true;
  } catch (e) {
    debugPrint("Single-device check skipped (offline?): $e");
    return true;
  }
}

Future<bool> _needsSetDailyLimit() async {
  final prefs = await SharedPreferences.getInstance();

  // Flow 1 signal — questionnaire was just completed locally, this
  // session, and hasn't synced to the cloud yet. This is authoritative:
  // never show Set Daily Limit here, regardless of what the cloud
  // currently has (it hasn't been written yet, by design).
  final questionnairePending =
      prefs.getBool('questionnaire_sync_pending') ?? false;
  if (questionnairePending) return false;

  // No pending local questionnaire — safe to check the cloud now.
  final fields = await AuthHelper.fetchDecryptedUserFields();
  final hasCloudLimit = fields != null && fields['daily_limit'] != null;
  if (hasCloudLimit) return false;

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return true;
  final answeredLocally =
      prefs.getBool('questionnaire_answered_${user.id}') ?? false;
  return !answeredLocally;
}

Widget _buildSingleDeviceDialog(BuildContext context) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.devices, color: AppColors.colwhite, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              "Signed In Elsewhere",
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your account is currently signed in on another device.\n\nContinuing will sign you out from that device.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputFill,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.destructiveRed,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Continue",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colwhite,
                        ),
                      ),
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

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'SpenTree',
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryGreen,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.bgWhite,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryGreen,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: startScreen,
          onGenerateRoute: (settings) => null,
          onUnknownRoute: (settings) =>
              MaterialPageRoute(builder: (_) => startScreen),
          builder: (context, child) {
            return AppLockWrapper(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
