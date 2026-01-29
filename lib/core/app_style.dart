import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand Color
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color textMain = Color(0xFF2D2B2E);

  // Specific Greys
  static const Color textGrey = Color(0xFF8E8E93); // Standard Grey
  static const Color grey700 = Color(0xFF616161); // Description Text
  static const Color grey800 = Color(0xFF424242); // Bottom Link Text

  static const Color inactiveGrey = Color(0xFFE5E5EA);
  static const Color inputFill = Color(0xFFF2F2F7);
  static const Color borderGrey = Color(0xFFE5E5EA);

  // NEW: Error Color
  static const Color errorRed = Color(0xFFFF3B30);
}

class AppTextStyles {
  // Headings (poppins SemiBold)
  static TextStyle title = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
    height: 1.2,
  );

  // Body Text (poppins Regular)
  static TextStyle body = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.5,
  );

  // Button Text
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // NEW: Error Text Style
  static TextStyle error = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.errorRed,
  );
}
