import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/biometric_service.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import '../../core/user_data.dart';
import 'helpdesk_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFaceIdEnabled = false;

  // Colors based on your requirements
  final Color colBlack = const Color(0xFF000000);
  final Color colGrey80 = const Color(0xFF808080);
  final Color colGreyArrow = const Color(0xFFABABAB); // Figma Arrow Color
  final Color colBoxBg = const Color(0xFFF1F1F1);
  final Color colIconBg = const Color(0xFFB8F0C9); // Figma Icon Circle Color

  @override
  void initState() {
    super.initState();
    _loadLockPreference(); // Load the saved state when the page opens
  }

  // Fetch the saved value from SharedPreferences
  Future<void> _loadLockPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFaceIdEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
    });
  }

  // Confirmation Dialog with Blur
  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF34C759),
                ),
                child: Text("Confirm", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the first initial of the user's name
    String initial = UserData.userName.isNotEmpty
        ? UserData.userName[0].toUpperCase()
        : "?";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),

              // --- 1. Header (Aligned strictly in line) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Align bottom of text/icon
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colBlack,
                        ),
                      ),
                      Text(
                        "Profile",
                        style: GoogleFonts.montserrat(
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          color: colBlack,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 32,
                      color: colBlack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- 2. User Info Card (Increased height) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colBoxBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    // Profile Circle with Initial Letter
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF34C759), // Primary Green
                      child: Text(
                        initial,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                            color: colBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Planting since January 2025",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colGrey80,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- 3. Settings List ---
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: colBoxBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      Icons.person_2_outlined,
                      "My Account",
                      "Make changes to your account",
                    ),
                    _buildSettingsItem(
                      Icons.fingerprint,
                      "Face ID / Touch ID",
                      "Manage your device security",
                      trailing: Switch.adaptive(
                        value: _isFaceIdEnabled,
                        activeColor: const Color(0xFF34C759),
                        onChanged: (val) async {
                          if (val) {
                            // Single verification to enable
                            bool auth =
                                await BiometricService.authenticateUser();
                            if (auth) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('isFaceIdEnabled', true);
                              setState(() => _isFaceIdEnabled = true);
                            }
                          } else {
                            // Show blur dialog to disable
                            _showConfirmationDialog(
                              title: "Disable Lock?",
                              message:
                                  "Are you sure you want to remove app security?",
                              onConfirm: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('isFaceIdEnabled', false);
                                setState(() => _isFaceIdEnabled = false);
                              },
                            );
                          }
                        },
                      ),
                    ),
                    _buildSettingsItem(
                      Icons.logout_rounded,
                      "Log out",
                      "Further secure your account for safety",
                      onTap: () => _showConfirmationDialog(
                        title: "Log Out",
                        message: "Do you really want to sign out?",
                        onConfirm: () async {
                          // 1. Clear the login state so the app doesn't auto-login next time
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            'isLoggedIn',
                            false,
                          ); // Or your specific login key

                          // 2. Redirect to Sign-in and clear the entire navigation stack
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ), // Replace with your actual Sign-in class
                              (route) =>
                                  false, // This removes all previous routes from memory
                            );
                          }
                        },
                      ),
                    ),
                    _buildSettingsItem(
                      Icons.help_outline,
                      "Helpdesk & FAQ",
                      null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpdeskScreen(),
                        ),
                      ),
                    ),
                    _buildSettingsItem(
                      Icons.info_outline,
                      "About Us",
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      Icons.mail_outline,
                      "Contact Us",
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Divider(color: colBlack, thickness: 0.5),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  "Planted with love in Mumbai, India",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colGrey80,
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String? subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        15,
      ), // Optional: adds a ripple effect inside the box radius
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colIconBg, // B8F0C9
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: colBlack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colBlack,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: colGrey80,
                      ),
                    ),
                ],
              ),
            ),
            // Figma styled arrow
            trailing ??
                Icon(Icons.chevron_right, color: colGreyArrow, size: 24),
          ],
        ),
      ),
    );
  }
}
