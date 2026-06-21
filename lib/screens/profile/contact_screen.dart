// lib/screens/profile/contact_screen.dart
// Change: added SystemUIService.applyNavBarStyle() — same fix as about_screen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart'; // NEW

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    SystemUIService.applyNavBarStyle(context); // NEW

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        SystemUIService.applyNavBarStyle(context);
        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 70),
                    Text(
                      "Contact",
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      "SpenTree",
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPoppinsText(
                      "We'd love to hear from you. Whether you have feedback, questions, or just an idea to make Spentree better — we're listening.",
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeading("Need Help?"),
                    _buildPoppinsText(
                      "Having trouble with the app? Not sure how something works?\nReach out and we'll do our best to help you quickly.",
                    ),
                    Text(
                      "Email: support@spentree.app",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeading("Share Feedback"),
                    _buildPoppinsText(
                      "Have a feature idea? Found something we can improve?\nSpentree grows with your input.",
                    ),
                    Text(
                      "Feedback: feedback@spentree.app",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeading("Report a Bug"),
                    _buildPoppinsText(
                      "If something isn't working right, let us know with details like:\n• What happened\n• What you expected\n• Your device model (if possible)",
                    ),
                    _buildPoppinsText("This helps us fix things faster."),
                    const SizedBox(height: 16),
                    _buildSectionHeading("Stay Kind, Stay Growing"),
                    _buildPoppinsText(
                      "We're building Spentree to be a calm and helpful space for better money habits. Your thoughts help us make it even better.",
                    ),
                    const SizedBox(height: 12),
                    _buildPoppinsText("Thanks for being part of the journey."),
                    const SizedBox(height: 12),
                    _buildFooter(context),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ), // SafeArea
          ),
        );
      },
    );
  }

  Widget _buildSectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.colblack,
        ),
      ),
    );
  }

  Widget _buildPoppinsText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: AppColors.colblack,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.white500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/pranav-phanse-8b4bbb318"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(
                  text: "Designed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ),
                ),
                TextSpan(
                  text: "Designer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("www.linkedin.com/in/ruchi-mulik-816a2b295"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(
                  text: "Developed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ),
                ),
                TextSpan(
                  text: "Developer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
