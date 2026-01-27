import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand Color
  static const Color primaryGreen = Color(0xFF34C759);

  // Text Colors
  static const Color textMain = Color(0xFF2D2B2E);
  static const Color textGrey = Color(0xFF8E8E93);

  // UI Element Colors
  static const Color inactiveGrey = Color(0xFFE5E5EA); // Progress bar inactive
  static const Color inputFill = Color(0xFFF2F2F7); // Text field background
  static const Color borderGrey = Color(0xFFE5E5EA); // Card borders
}

class AppTextStyles {
  // Headings (Montserrat SemiBold)
  static TextStyle title = GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
    height: 1.2,
  );

  // Body Text (Montserrat Regular)
  static TextStyle body = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    height: 1.5,
  );

  // Button Text
  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
