import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/biometric_service.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/profile/account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'data_privacy_screen.dart';
import 'helpdesk_screen.dart';
import '../../core/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _plantingSince = "";

  @override
  void initState() {
    super.initState();
    _loadPlantingSince();
  }

  void _loadPlantingSince() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final created = DateTime.parse(user.createdAt).toLocal();

    setState(() {
      _plantingSince =
          "Planting since ${_monthName(created.month)} ${created.year}";
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.destructiveRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.colwhite, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          color: AppColors.destructiveRed,
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

    // ValueListenableBuilder<ThemeMode> ensures the entire screen rebuilds
    // whenever the theme changes — this is what was missing before and caused
    // the profile screen to stay stuck on the old theme.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
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

                  // ── Header ───────────────────────────────────────────────
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
                        // child: Icon(
                        //   PhosphorIconsRegular.trophy,
                        //   size: 32,
                        //   color: AppColors.colblack,
                        // ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── User Card ────────────────────────────────────────────
                  // ValueListenableBuilder<UserProfile> rebuilds just this
                  // card when name or profile image changes in AccountScreen,
                  // giving instant sync with zero restart required.
                  ValueListenableBuilder<UserProfile>(
                    valueListenable: userProfileNotifier,
                    builder: (context, profile, _) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // Profile image if set, otherwise initial letter
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.inputFill,
                                border: Border.all(
                                  color: const Color.fromARGB(
                                    255,
                                    182,
                                    181,
                                    181,
                                  ).withOpacity(0.5), // Adjust color as needed
                                  width: 1.0, // "Thin" border
                                ), // Background behind the icon
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: profile.imageBytes != null
                                  ? Image.memory(
                                      profile.imageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Icon(
                                        PhosphorIconsRegular
                                            .user, // Unfilled icon as requested
                                        size: 35,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              // CHANGED: Expanded on the Column itself,
                              child: Column(
                                // not Flexible on the Text inside it.
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.firstName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.colblack,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _plantingSince,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Settings List ────────────────────────────────────────
                  _buildSettingsItem(
                    PhosphorIconsRegular.user,
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
                    PhosphorIconsRegular.shieldCheck,
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
                  _buildSettingsItem(
                    PhosphorIconsRegular.signOut,
                    "Log out",
                    "Further secure your account for safety",
                    () {
                      _showConfirmationDialog(
                        title: "Logout",
                        message: "Are you sure you want to logout?",
                        confirmText: "Yes, Logout",
                        icon: PhosphorIconsRegular.signOut,
                        onConfirm: () async {
                          await AuthHelper.signOutEverywhere();
                          final prefs = await SharedPreferences.getInstance();
                          final keepOnboardingFlag =
                              prefs.getBool('has_completed_onboarding') ?? true;
                          final deviceId = prefs.getString(
                            'device_id',
                          ); // preserve before wipe
                          await prefs.clear();
                          await prefs.setBool(
                            'has_completed_onboarding',
                            keepOnboardingFlag,
                          );
                          if (deviceId != null)
                            await prefs.setString('device_id', deviceId);
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
                    PhosphorIconsRegular.question,
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
                    PhosphorIconsRegular.info,
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
                    PhosphorIconsRegular.envelopeSimple,
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

                  const SizedBox(height: 20),
                  Divider(color: AppColors.divider, thickness: 1),
                  const SizedBox(height: 20),

                  // ── Footer ───────────────────────────────────────────────
                  Center(
                    child: Text(
                      "Planted with love in Mumbai, India",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
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
