import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/splash_onboarding_screen.dart'; // UPDATED IMPORT
import 'screens/main_wrapper.dart';
import 'core/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 1. Check if it's the first time launch
  bool isOnboarded = prefs.getBool('isOnboarded') ?? false;

  // 2. Retrieve the saved lock state
  bool isLockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;

  Widget startScreen;

  if (!isOnboarded) {
    // CONDITION 1: New User -> Show Green Splash Animation
    startScreen = const SplashOnboardingScreen();
  } else {
    // CONDITION 2: Returning User -> Check Biometrics
    if (isLockEnabled) {
      // Force biometric popup before the app opens
      bool authenticated = await BiometricService.authenticateUser();

      if (authenticated) {
        startScreen = const MainWrapper();
      } else {
        // Show fallback if they cancel/fail verification
        startScreen = const AppLockedScreen();
      }
    } else {
      // If lock is disabled, proceed to Dashboard
      startScreen = const MainWrapper();
    }
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpenTree',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34C759)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: startScreen,
    );
  }
}

// A simple fallback screen if authentication fails or is cancelled
class AppLockedScreen extends StatelessWidget {
  const AppLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF34C759)),
            const SizedBox(height: 20),
            const Text(
              "SpenTree is Locked",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => main(), // Restart the auth process
              child: const Text(
                "Tap to Unlock",
                style: TextStyle(color: Color(0xFF34C759)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
