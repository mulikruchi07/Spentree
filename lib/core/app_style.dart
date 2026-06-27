import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. GLOBAL THEME NOTIFIER ---
// This listens for theme changes and instantly rebuilds the app
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

/// Call this in main() BEFORE runApp to restore the user's saved theme.
/// Defaults to ThemeMode.system on a fresh install — correct behavior.
Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('app_theme');
  if (saved == 'Light mode') {
    themeNotifier.value = ThemeMode.light;
  } else if (saved == 'Dark mode') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system; // null key → fresh install → System ✓
  }
}

// Helper to check if the current active mode is dark
bool get isDarkMode {
  if (themeNotifier.value == ThemeMode.system) {
    return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }
  return themeNotifier.value == ThemeMode.dark;
}

// --- 2. DYNAMIC IMAGES ---
class AppImages {
  static String get appName =>
      isDarkMode ? 'assets/dappname.png' : 'assets/appname.png';
  static String get logoName =>
      isDarkMode ? 'assets/dlogo-name.png' : 'assets/logo-name.png';
  static String get navbg =>
      isDarkMode ? 'assets/icons/dnavbg.png' : 'assets/icons/navbg.png';
}

// --- 3. DYNAMIC COLORS ---
class AppColors {
  // Static colors (same in both themes)
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color grey700 = Color(0xFF61677D);
  static const Color grey600 = Color(0xFF7C8BA0);
  static const Color white600 = Color(0xFFAEAEAE);
  static const Color subtext = Color(0xFF9B9B9B);
  static const Color desctext = Color(0xFFABABAB);
  static const Color inactiveGrey = Color(0xFFE0E5EC);
  static const Color borderGrey = Color(0xFFE5E5EA);
  static const Color divider = Color(0xFF808080);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color destructiveRed = Color(0xFFFF383C);

  // Dynamic colors (Changes based on isDarkMode)
  static Color get textMain =>
      isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF161616);

  // Note: Based on your commented code, colwhite/colblack mapped exactly as intended
  static Color get colwhite =>
      isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get colblack =>
      isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  
  static Color get navbar =>
      isDarkMode ? const Color(0xFF343434) : const Color(0xFFFFFFFF);
  static Color get renavbar =>
      isDarkMode ? const Color(0xFF252525) : const Color(0xFFFFFFFF);

  static Color get bgWhite =>
      isDarkMode ? const Color(0xFF161616) : const Color(0xFFFFFFFF);
  static Color get grey800 =>
      isDarkMode ? const Color(0xFFD0D1D0) : const Color(0xFF424242);
  static Color get white500 =>
      isDarkMode ? const Color(0xFF999999) : const Color(0xFF606060);
  static Color get inputFill =>
      isDarkMode ? const Color(0xFF343434) : const Color(0xFFF1F1F1);
  static Color get colIconBg =>
      isDarkMode ? const Color(0xFF161616) : const Color(0xFFB8F0C9);
  static Color get iconbox =>
      isDarkMode ? const Color(0xFF555555) : const Color(0xFFFFFFFF);
  static Color get datebox =>
      isDarkMode ? const Color(0xFF666666) : const Color(0xFFD7D8D6);
  static Color get datenum =>
      isDarkMode ? const Color(0xFF999999) : const Color(0xFF797979);
  static Color get unlockst =>
      isDarkMode ? const Color(0xFFC0C0C0) : const Color(0xFF000000);
  static Color get redirctcircle =>
      isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFD9D9D9);
  static Color get specialcode =>
      isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1);
  static Color get toggle =>
      isDarkMode ? const Color(0xFF676767) : const Color(0xFFE8E8E8);
  static Color get toggledot =>
      isDarkMode ? const Color(0xFFF2F2F2) : const Color(0xFFABABAB);
  static Color get claimcard =>
      isDarkMode ? const Color(0xFF222222) : const Color(0xFFFFFFFF);
      static Color get smclaimcard =>
      isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
}

// --- 4. DYNAMIC TEXT STYLES ---
class AppTextStyles {
  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain, // Automatically fetches correct color
    height: 1.2,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.5,
  );

  static TextStyle get button => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.colwhite, // Automatically fetches correct color
  );

  static TextStyle get error => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.errorRed,
  );
}

// Reusable Custom Toasts ---
class CustomToasts {
  static void showSuccessToast(BuildContext context, String message) {
    // Dynamically gets the height of the device's bottom navigation keys
    final double bottomNavHeight = MediaQuery.of(context).padding.bottom;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        // Removed 'const' from EdgeInsets and added bottomNavHeight
        margin: EdgeInsets.only(
          bottom: 20 + bottomNavHeight,
          left: 24,
          right: 24,
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFDAF0D6), // Light green background
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryGreen, // Green text
            ),
          ),
        ),
      ),
    );
  }

  static void showErrorToast(BuildContext context, String message) {
    // Dynamically gets the height of the device's bottom navigation keys
    final double bottomNavHeight = MediaQuery.of(context).padding.bottom;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        // Removed 'const' from EdgeInsets and added bottomNavHeight
        margin: EdgeInsets.only(
          bottom: 20 + bottomNavHeight,
          left: 24,
          right: 24,
        ),
        content: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0D6D6), // Light red background
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.destructiveRed, // Red text
            ),
          ),
        ),
      ),
    );
  }
}
