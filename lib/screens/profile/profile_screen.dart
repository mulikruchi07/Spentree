import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/biometric_service.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/profile/account_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import '../../core/user_data.dart';
import 'data_privacy_screen.dart';
import 'helpdesk_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  // --- NEW FLOATING POPUP WITH BLUR ---
  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Background Blur
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(
                  28,
                ), // Floating rounded look
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red Circular Icon at Top
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.destructiveRed, // Design Red
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.colwhite, size: 32),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.desctext,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Confirm Button (Red)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructiveRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colwhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button (Grey)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputFill,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              AppColors.destructiveRed, // Red text for cancel
                        ),
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

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        String initial = UserData.userName.isNotEmpty
            ? UserData.userName[0].toUpperCase()
            : "?";

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  // ... Header Code ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.colblack,
                            ),
                          ),
                          Text(
                            "Profile",
                            style: GoogleFonts.montserrat(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colblack,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Icon(
                          PhosphorIcons.trophy,
                          size: 32,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ... User Card ...
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: AppColors.primaryGreen,
                          child: Text(
                            initial,
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.colblack,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              UserData.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colblack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Planting since January 2025",
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings List
                  _buildSettingsItem(
                    PhosphorIcons.user,
                    "My Account",
                    "Make changes to your account",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountScreen(),
                        ),
                      );
                    },
                  ),

                  _buildSettingsItem(
                    PhosphorIcons.shieldCheck,
                    "Data & Privacy",
                    "Manage your data & privacy",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataPrivacyScreen(),
                        ),
                      );
                    },
                  ),
                  // Logout Item
                  _buildSettingsItem(
                    PhosphorIcons.signOut,
                    "Log out",
                    "Further secure your account for safety",
                    () {
                      // SHOW CUSTOM LOGOUT DIALOG
                      _showConfirmationDialog(
                        title: "Logout",
                        message: "Are you sure you want to logout?",
                        confirmText: "Yes, Logout",
                        icon: PhosphorIcons.signOut,

                        onConfirm: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      );
                    },
                  ),
                  _buildSettingsItem(
                    PhosphorIcons.question,
                    "Helpdesk & FAQ",
                    "Further secure your account for safety",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpdeskScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    PhosphorIcons.info,
                    "About Us",
                    "Further secure your account for safety",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    PhosphorIcons.envelopeSimple,
                    "Contact Us",
                    "Further secure your account for safety",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ), // "Reduce gap distance between tip and divide line"
                  Divider(color: AppColors.divider, thickness: 1),

                  const SizedBox(height: 20),

                  // --- 7. Footer ---
                  Center(
                    child: Text(
                      "Planted with love in Mumbai, India",
                      // Poppins, Medium 13
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String t,
    String s,
    VoidCallback tap,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.colIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppColors.colblack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.desctext,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.desctext),
          ],
        ),
      ),
    ),
  );
}
