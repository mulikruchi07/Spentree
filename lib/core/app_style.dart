import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand Color
  static const Color primaryGreen = Color(0xFF34C759);
  static const Color textMain = Color(0xFF161616);

  static const Color colwhite = Color(0xFF000000);
  static const Color colblack = Color(0xFFFFFFFF);

  // Background Color
  static const Color bgWhite = Color(0xFF161616);
  // static const Color bgWhite = Color(0xFFFFFFFF);

  // Specific Greys
  static const Color textGrey = Color(0xFF8E8E93); // darktheme same
  static const Color grey700 = Color(0xFF61677D); // darktheme same
  // static const Color grey800 = Color(0xFF424242);
  static const Color grey800 = Color(0xFFD0D1D0);
  static const Color grey600 = Color(0xFF7C8BA0); // darktheme same

  // Specific Whites
  static const Color white500 = Color(0xFF999999);
  // static const Color white500 = Color(0xFF606060);
  static const Color white600 = Color(0xFFAEAEAE); // darktheme same

  static const Color subtext = Color(0xFF9B9B9B); // darktheme same
  static const Color desctext = Color(
    0xFFABABAB,
  ); //profile, data privacy, Icons.chevron_right(profile, account & data privacy page) // darktheme same
  static const Color inactiveGrey = Color(0xFFE0E5EC);
  // static const Color inputFill = Color(0xFFF1F1F1);
  static const Color inputFill = Color(0xFF343434);
  static const Color borderGrey = Color(0xFFE5E5EA);
  // static const Color colIconBg = Color(0xFFB8F0C9);
  static const Color colIconBg = Color(0xFF161616);
  static const Color divider = Color(0xFF808080); // darktheme same
  // static const Color iconbox = Color(0xFFFFFFFF);
  static const Color iconbox = Color(0xFF555555);
  // static const Color datebox = Color(0xFFD7D8D6);
  static const Color datebox = Color(0xFF666666);
  // static const Color datenum = Color(0xFF797979);
  static const Color datenum = Color(0xFF999999);

  // Error Color
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color destructiveRed = Color(0xFFFF383C); //popups

  // Dark Mode Colors

  // static const Color colwhite = Color(0xFF000000);
  // static const Color colblack = Color(0xFFFFFFFF);

  // // Background Color
  // static const Color bgWhite = Color(0xFF161616);
  // static const Color bgGrey = Color(0xFF161616);

  // // Specific Greys
  // static const Color textGrey = Color(0xFF8E8E93);
  // static const Coor grey700 = Color(0xFF61677D);
  // static const Color grey800 = Color(0xFFD0D1D0);
  // static const Color grey600 = Color(0xFF7C8BA0);

  // // Specific Whites
  // static const Color white500 = Color(0xFF797979);
  // static const Color white600 = Color(0xFFAEAEAE);

  // static const Color subtext = Color(0xFF9B9B9B);
  // static const Color desctext = Color(0xFFABABAB); //profile, data privacy
  // static const Color inactiveGrey = Color(0xFFE0E5EC);
  // static const Color inputFill = Color(0xFF343434);
  // static const Color borderGrey = Color(0xFFE5E5EA);
  // static const Color colIconBg = Color(0xFF161616); //profile, account, data privacy

  // static const Color divider = Color(0xFF808080);
  // static const Color iconbox = Color(0xFF555555);
  // static const Color datebox = Color(0xFF606060);
  // static const Color datenum = Color(0xFF999999);
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
    color: AppColors.colwhite,
  );

  // NEW: Error Text Style
  static TextStyle error = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.errorRed,
  );
}
