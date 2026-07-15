// lib/screens/profile/terms_screen.dart
// Change: added SystemUIService.applyNavBarStyle()

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart'; // NEW

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        return Scaffold(
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
                    "Terms of Service",
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _dateText("Effective Date: 1st August 2026"),
                  const SizedBox(height: 16),
                  _buildBodyText(
                    "Welcome to Spentree (\"we,\" \"our,\" or \"us\"). By accessing or using our mobile application, website, or services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.",
                  ),
                  _buildSection(
                    "1. Nature of the Service",
                    "Spentree is a gamified personal finance and expense-tracking application. We provide you with tools to visualize your spending, earn achievements, and manage your financial habits through a virtual ecosystem.",
                  ),
                  _buildBoldText(
                    "Important Disclaimer: Spentree is not a bank, financial institution, investment advisor, or NBFC (Non-Banking Financial Company). We do not provide financial advice. Our app is a tracking and management tool only. Any decisions you make based on the data displayed in the app are your sole responsibility. We are not liable for any financial losses, errors in data interpretation, or inaccuracies in automated SMS parsing.",
                  ),
                  _buildSection(
                    "2. Eligibility & Age Requirements",
                    "Spentree is designed for individuals of all backgrounds striving to improve their financial habits.",
                  ),
                  _buildBodyText(
                    "By using Spentree, you represent that you are authorized to enter into this legal agreement.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "If you are under the age of 18, you represent and warrant that you have obtained the consent of your parent or legal guardian to use Spentree and agree to these Terms on your behalf.",
                  ),
                  _buildSection(
                    "3. Waitlist Terms",
                    "Joining the Spentree waitlist signifies your interest in early access.",
                  ),
                  _buildBodyText(
                    "Waitlist participants may receive early-bird benefits, exclusive rewards, or priority access, the specifics of which are determined solely at our discretion.\nParticipation in the waitlist does not guarantee immediate app access or success in receiving promotional rewards.\nWe reserve the right to modify or cancel waitlist rewards at any time.",
                  ),
                  _buildSection(
                    "4. User Account Rules",
                    "Account Security: You are responsible for maintaining the confidentiality of your account credentials. To enhance account security, Spentree currently permits only one active authenticated session per account. Signing in on another device may automatically terminate the previous session.",
                  ),
                  _buildBoldText("Prohibited Conduct: You agree not to:"),
                  _buildBodyText(
                    "• Use the app for any illegal or unauthorized purpose.\n• Reverse engineer, decompile, or attempt to extract our source code.\n• Attempt to manipulate our gamification system (e.g., fraudulent milestone claims or exploiting the seed/level system).",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Termination: We reserve the right to suspend or terminate your account at any time if we suspect you are violating these terms or using the app in a way that harms the community.",
                  ),
                  _buildSection(
                    "5. SMS Parsing & Data Disclaimer",
                    "Spentree uses automated technology to parse financial SMS messages.",
                  ),
                  _buildBodyText(
                    "Accuracy: While we strive for accuracy, SMS parsing can be affected by variations in bank formats and network issues. You are encouraged to manually verify your transactions.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "User Responsibility: You acknowledge that our SMS parsing is provided \"as-is.\" We are not responsible for any missed, miscategorized, or incorrectly parsed transactions.",
                  ),
                  _buildSection(
                    "6. Intellectual Property",
                    "All content, design elements (including our virtual \"Forest\" ecosystem), logo, and source code are the intellectual property of Spentree. You are granted a limited, non-exclusive license to use the app for personal, non-commercial purposes. You may not copy or redistribute our assets without written permission.",
                  ),
                  _buildSection(
                    "7. Limitation of Liability",
                    "To the maximum extent permitted by law, Spentree shall not be liable for any indirect, incidental, or consequential damages resulting from:",
                  ),
                  _buildBodyText(
                    "• Your use or inability to use the service.\n• Any unauthorized access to your account (provided we have maintained reasonable security).\n• Financial decisions made based on the information provided in the app.",
                  ),
                  _buildSection(
                    "8. Updates to Terms",
                    "We may update these Terms of Service from time to time. We will provide notice of significant changes via email or an in-app alert. Your continued use of the app after such changes constitutes your acceptance of the updated terms.",
                  ),
                  _buildSection(
                    "9. Governing Law & Dispute Resolution",
                    "These terms shall be governed by and construed in accordance with the laws of India. Any disputes arising out of these terms shall be subject to the exclusive jurisdiction of the courts in Mumbai, Maharashtra.",
                  ),
                  _buildSection(
                    "10. Contact Us",
                    "If you have any questions regarding these Terms, please contact our support team at:",
                  ),
                  _buildBoldText("team.spentree@gmail.com"),
                  const SizedBox(height: 32),
                  // _buildAgreeButton(context),
                  // const SizedBox(height: 48),
                  _buildFooter(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ), // SafeArea
        );
      },
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.colblack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: AppColors.colblack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 14,
      height: 1.5,
      color: AppColors.colblack,
    ),
  );
  Widget _dateText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 14,
      height: 1.5,
      color: AppColors.divider,
    ),
  );
  Widget _buildBoldText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: AppColors.colblack,
    ),
  );

  // Widget _buildAgreeButton(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 55,
  //     child: ElevatedButton(
  //       onPressed: () => Navigator.pop(context),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: AppColors.primaryGreen,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         elevation: 0,
  //       ),
  //       child: Text("I agree", style: GoogleFonts.montserrat(color: AppColors.colwhite, fontWeight: FontWeight.w600, fontSize: 16)),
  //     ),
  //   );
  // }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.white500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("https://in.linkedin.com/in/pranav-phanse-8b4bbb318"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(text: "Designed by "),
                TextSpan(
                  text: "Designer",
                  style: GoogleFonts.poppins(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w200,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/ruchi-mulik-816a2b295"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(text: "Developed by "),
                TextSpan(
                  text: "Developer",
                  style: GoogleFonts.poppins(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w200,
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
