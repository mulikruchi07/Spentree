import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/device_identity.dart';
import 'package:spentree/core/notification_service.dart';
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
      final myDeviceId = await DeviceIdentity.getDeviceId();
      _watchForRemoteLogout(session.user.id, myDeviceId);
      final userId = session.user.id;
      final prefs = await SharedPreferences.getInstance();
      final hasDecidedSms = prefs.containsKey(
        _smsPermissionDecisionKey(userId),
      );
      final hasCompletedSync =
          prefs.getBool(_onboardingSyncCompleteKey(userId)) ?? false;

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) {
            if (!hasDecidedSms) {
              return const SmsPermissionScreen(isOnboarding: true);
            }
            if (!hasCompletedSync) {
              return const LoadingScreen(isAuthFlow: true);
            }
            return const MainWrapper();
          },
        ),
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

    if (!hasDecidedSms) {
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

// import 'package:flutter/material.dart';
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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
//               PhosphorIconsRegular.lockKey(),
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
//testing
// import 'package:flutter/material.dart';
// import 'package:spentree/screens/dashboard/dashboard_screen.dart';
// import 'package:spentree/screens/main_wrapper.dart';
// import 'screens/subscription/payment_successful_screen.dart';
// import 'core/app_style.dart';
// import 'screens/forest/spentwrap_intro_screen.dart';
// import 'core/transaction_service.dart';
// import 'screens/achievements/deals_screen.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Start fetching SMS in the background immediately
//   await TransactionService().initService();
//   runApp(const MyApp(startScreen: SizedBox()));
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key, required SizedBox startScreen});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, currentMode, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'SpenTree',
//           themeMode: currentMode,

//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite,
//           ),

//           darkTheme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite,
//           ),

//           home: const MainWrapper(initialIndex: 0),
//           // home: const DealsScreen(),
//           // home: const PaymentSuccessfulScreen(),
//         );
//       },
//     );
//   }
// }

//widget 1 todays_tree_card
// import 'package:flutter/material.dart';
// import 'widgets/todays_tree_card.dart';
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: TodaysTreeCard(
//             todayExpense: 1000,
//             dailyLimit: 500,
//             onGoToDashboard: () {},
//           ),
//         ),
//       ),
//     );
//   }
// }

//widget 2 mini_tree_card
// import 'package:flutter/material.dart';
// import 'widgets/mini_tree_card.dart'; // Adjust path if needed
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         body: Center(
//           child: SizedBox(
//             width: 168,
//             child: MiniTreeCard(
//               todayExpense: 4000.0,
//               dailyLimit: 500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//wdiget 3 add_expense_card
// import 'package:flutter/material.dart';
// import 'widgets/add_expense_card.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: SizedBox(
//             width: 168,
//             child: AddExpenseCard(
//               onTap: () {
//                 debugPrint('Card tapped');
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

//widget 4 todays_expenses_card.dart
// import 'package:flutter/material.dart';
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

// import 'widgets/todays_expenses_card.dart';
// import 'core/transaction_service.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final transactions = [
//       Transaction(
//         id: '1',
//         title: 'Swiggy',
//         category: 'Food & Beverages',
//         amount: 450,
//         date: DateTime.now(),
//         time: const TimeOfDay(hour: 12, minute: 30),
//         icon: PhosphorIconsRegular.bowlSteam(),
//         isManual: false,
//       ),
//       Transaction(
//         id: '2',
//         title: 'Uber',
//         category: 'Transport',
//         amount: 220,
//         date: DateTime.now(),
//         time: const TimeOfDay(hour: 14, minute: 15),
//         icon: PhosphorIconsRegular.car(),
//         isManual: true,
//       ),
//       Transaction(
//         id: '3',
//         title: 'Amazon',
//         category: 'Shopping',
//         amount: 1299,
//         date: DateTime.now(),
//         time: const TimeOfDay(hour: 16, minute: 45),
//         icon: PhosphorIconsRegular.tShirt(),
//         isManual: false,
//       ),
//       Transaction(
//         id: '4',
//         title: 'Jio Recharge',
//         category: 'Bills & Subscriptions',
//         amount: 299,
//         date: DateTime.now(),
//         time: const TimeOfDay(hour: 18, minute: 20),
//         icon: PhosphorIconsRegular.simCard(),
//         isManual: false,
//       ),
//     ];

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(0),
//             child: TodaysExpensesCard(
//               transactions: transactions, //const[], //nullstate
//               onGoToAnalytics: () {
//                 debugPrint('Analytics tapped');
//               },
//               onSwapTap: () {
//                 debugPrint('Swap tapped');
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// widget 5 greeting_summary_card.dart
// import 'package:flutter/material.dart';
// import 'widgets/greeting_summary_card.dart';
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(0),
//             child: GreetingSummaryCard(
//               userName: 'Ruchi',
//               todayExpense: 1050.0,
//               dailyLimit: 500,
//               onArrowTap: () {
//                 debugPrint('Arrow tapped');
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// widget 6 calendar_card.dart
// import 'package:flutter/material.dart';
// import 'widgets/calendar_card.dart';
// import 'widgets/todays_expenses_card.dart';
// import 'core/transaction_service.dart';
// void main() {
//   runApp(const MyApp());
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: WidgetTestScreen(),
//     );
//   }
// }
// class WidgetTestScreen extends StatefulWidget {
//   const WidgetTestScreen({super.key});
//   @override
//   State<WidgetTestScreen> createState() => _WidgetTestScreenState();
// }
// class _WidgetTestScreenState extends State<WidgetTestScreen> {
//   bool showCalendar = true;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(0),
//           child: showCalendar
//               ? DynamicCalendarCard(
//                   dailyLimit: 500,
//                   onSwapTap: () {
//                     setState(() {
//                       showCalendar = false;
//                     });
//                   },
//                 )
//               : TodaysExpensesCard(
//                   transactions: const [],
//                   onGoToAnalytics: () {},
//                   onSwapTap: () {
//                     setState(() {
//                       showCalendar = true;
//                     });
//                   },
//                 ),
//         ),
//       ),
//     );
//   }
// }

//swap toggel
// import 'package:flutter/material.dart';
// import 'screens/widget_test_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: WidgetTestScreen(),
//     );
//   }
// }

// android home screen widgets rendering test
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:spentree/screens/analytics/analytics_screen.dart';
// import 'package:spentree/screens/dashboard/dashboard_screen.dart';
// import 'package:spentree/screens/main_wrapper.dart';
// import 'core/app_style.dart';
// import 'core/transaction_service.dart';
// import 'package:flutter/services.dart';
// import 'package:home_widget/home_widget.dart';

// @pragma('vm:entry-point')
// Future<void> backgroundCallback(Uri? uri) async {
//   if (uri?.host == 'sms_received') {
//     await TransactionService().initService(); // re-parses SMS + calls syncWidget()
//   }
// }

// void main() async {
//   HomeWidget.registerInteractivityCallback(backgroundCallback);
//   WidgetsFlutterBinding.ensureInitialized();

//   await TransactionService().initService();

//   const platform = MethodChannel('spentree_widget_channel');
//   platform.setMethodCallHandler((call) async {
//     if (call.method == "themeChanged") {
//       await TransactionService().syncWidget();
//     }
//   });
//   String? action;
//   try {
//     action = await platform.invokeMethod('getWidgetAction');
//   } catch (e) {
//     debugPrint("Failed to get widget action: $e");
//   }

//   // If action is OPEN_ADD_EXPENSE, jump to Tab 1 (Analytics). Otherwise, Tab 0 (Dashboard)
//   int startTab = 0;
//   if (action == "OPEN_ADD_EXPENSE") {
//     startTab = 1; // Tab 1
//     AnalyticsScreen.triggerOpenForm.value = true; // Tell form to open!
//   } else if (action == "OPEN_DASHBOARD") {
//     startTab = 0; // Tab 0
//   }

//   // Pass the startTab to MainWrapper
//   runApp(MyApp(startScreen: MainWrapper(initialIndex: startTab)));
// }

// class MyApp extends StatelessWidget {
//   final Widget startScreen; // Updated to accept the dynamic start screen
//   const MyApp({super.key, required this.startScreen});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, currentMode, child) {
//         return MaterialApp(
//           debugShowCheckedModeBanner: false,
//           title: 'SpenTree',
//           themeMode: currentMode,
//           theme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.light,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite,
//           ),
//           darkTheme: ThemeData(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: AppColors.primaryGreen,
//               brightness: Brightness.dark,
//             ),
//             useMaterial3: true,
//             scaffoldBackgroundColor: AppColors.bgWhite,
//           ),
//           home: startScreen, // Uses the dynamic start screen!
//         );
//       },
//     );
//   }
// }
