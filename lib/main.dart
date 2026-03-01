// import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'screens/onboarding/splash_onboarding_screen.dart'; // UPDATED IMPORT
// import 'screens/main_wrapper.dart';
// import 'core/biometric_service.dart';
// import '../../core/app_style.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final prefs = await SharedPreferences.getInstance();
//   final savedTheme = prefs.getString('app_theme') ?? 'System';
//   if (savedTheme == 'Light mode') {
//     themeNotifier.value = ThemeMode.light;
//   } else if (savedTheme == 'Dark mode') {
//     themeNotifier.value = ThemeMode.dark;
//   } else {
//     themeNotifier.value = ThemeMode.system;
//   }

//   // 1. Check if it's the first time launch
//   bool isOnboarded = prefs.getBool('isOnboarded') ?? false;

//   // 2. Retrieve the saved lock state
//   bool isLockEnabled = prefs.getBool('isFaceIdEnabled') ?? false;

//   Widget startScreen;

//   if (!isOnboarded) {
//     // CONDITION 1: New User -> Show Green Splash Animation
//     startScreen = const SplashOnboardingScreen();
//   } else {
//     // CONDITION 2: Returning User -> Check Biometrics
//     if (isLockEnabled) {
//       // Force biometric popup before the app opens
//       bool authenticated = await BiometricService.authenticateUser();

//       if (authenticated) {
//         startScreen = const MainWrapper();
//       } else {
//         // Show fallback if they cancel/fail verification
//         startScreen = const AppLockedScreen();
//       }
//     } else {
//       // If lock is disabled, proceed to Dashboard
//       startScreen = const MainWrapper();
//     }
//   }

//   runApp(MyApp(startScreen: startScreen));
// }

// class MyApp extends StatelessWidget {
//   final Widget startScreen;
//   const MyApp({super.key, required this.startScreen});

//   @override
//   Widget build(BuildContext context) {
//     // --- THEME LISTENER ---
//     // This rebuilds the entire app instantly when themeNotifier changes
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, currentMode, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'SpenTree',
//           themeMode: currentMode,
//           // Light Theme Setup
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite, // Uses dynamic getter
//           ),
//           // Dark Theme Setup
//           darkTheme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite, // Uses dynamic getter
//           ),
//           home: startScreen,
//         );
//       },
//     );
//   }
// }

// // A simple fallback screen if authentication fails or is cancelled
// class AppLockedScreen extends StatelessWidget {
//   const AppLockedScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgWhite,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Updated to Phosphor Icon for consistency
//             PhosphorIcon(
//               PhosphorIcons.lockKey(),
//               size: 64,
//               color: AppColors.primaryGreen,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "SpenTree is Locked",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.textMain, // Dynamic text color
//               ),
//             ),
//             TextButton(
//               onPressed: () => main(), // Restart the auth process
//               child: const Text(
//                 "Tap to Unlock",
//                 style: TextStyle(color: AppColors.primaryGreen),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'core/app_style.dart';
import 'screens/forest/spentwrap_intro_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
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
            scaffoldBackgroundColor: AppColors.bgWhite,
          ),

          home: const SpentWrapScreen(),
        );
      },
    );
  }
}
