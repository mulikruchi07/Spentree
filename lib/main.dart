import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_wrapper.dart';
import 'core/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Retrieve the saved toggle state; default to false if not found
  bool isLockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;

  // Decide the starting screen
  Widget startScreen = const OnboardingScreen();

  if (isLockEnabled) {
    // 4. Force biometric popup before the app even opens
    bool authenticated = await BiometricService.authenticateUser();

    if (authenticated) {
      startScreen = const MainWrapper();
    } else {
      // Show a fallback screen if they cancel or fail verification
      startScreen = const AppLockedScreen();
    }
  } else {
    // If lock is disabled, proceed as normal
    startScreen = const MainWrapper();
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
        primarySwatch: Colors.green,
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
            const Icon(Icons.lock_outline, size: 64, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "SpenTree is Locked",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => main(), // Restart the auth process
              child: const Text("Tap to Unlock"),
            ),
          ],
        ),
      ),
    );
  }
}
