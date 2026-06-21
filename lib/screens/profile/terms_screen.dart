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
                Text("Terms & Conditions", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.colblack)),
                const SizedBox(height: 24),
                _buildBodyText("Welcome to Spentree. By using this app, you agree to the following terms."),
                _buildSection("1. Purpose of the App", "Spentree is a personal finance habit-building app that helps users track daily spending and build better money awareness through visual tools like trees and forests."),
                _buildBoldText("Spentree does not provide financial, investment, tax, or legal advice."),
                _buildSection("2. Personal Responsibility", "You are responsible for:"),
                _buildBodyText("• The financial decisions you make\n• Verifying your transactions and data\n• Setting realistic daily spending limits"),
                const SizedBox(height: 8),
                _buildBodyText("Spentree provides insights and visual tracking only and cannot guarantee financial outcomes."),
                _buildSection("3. Transaction Tracking", "Spentree may help you track expenses by:"),
                _buildBodyText("• Reading transaction-related SMS messages (on supported devices)\n• Allowing manual expense entry\n• Allowing editing or splitting of transactions"),
                const SizedBox(height: 8),
                _buildBoldText("The app does not connect directly to your bank account or perform any financial transactions on your behalf."),
                _buildSection("4. Accuracy of Data", "While Spentree attempts to detect and categorize expenses accurately, SMS formats and merchant names can vary. You are responsible for reviewing and correcting any transaction data inside the app."),
                _buildSection("5. User Conduct", "You agree not to:"),
                _buildBodyText("• Attempt to reverse engineer or misuse the app\n• Use the app for unlawful purposes\n• Share misleading financial data with others through the app"),
                _buildSection("6. Limitation of Liability", "Spentree is provided \"as is.\" We are not responsible for:"),
                _buildBodyText("• Financial losses\n• Incorrect expense categorization\n• Missed payments or budgeting decisions\nUse of the app is at your own discretion and risk."),
                _buildSection("7. Changes to the Service", "We may update features, visuals, or systems of Spentree at any time to improve the experience."),
                _buildSection("8. Contact", "For support or questions, contact:"),
                _buildBoldText("support@spentree.in"),
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
          Text(title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.colblack)),
          const SizedBox(height: 8),
          Text(body, style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.colblack)),
        ],
      ),
    );
  }

  Widget _buildBodyText(String text) => Text(text, style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: AppColors.colblack));
  Widget _buildBoldText(String text) => Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.colblack));

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
        Text("Planted with love in Mumbai, India", style: GoogleFonts.poppins(fontSize: 13, color: AppColors.white500)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
              children: [
                TextSpan(text: "Designed by "),
                TextSpan(text: "Designer", style: GoogleFonts.poppins(fontStyle: FontStyle.italic, fontWeight: FontWeight.w200, color: AppColors.white500)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
              children: [
                TextSpan(text: "Developed by "),
                TextSpan(text: "Developer", style: GoogleFonts.poppins(fontStyle: FontStyle.italic, fontWeight: FontWeight.w200, color: AppColors.white500)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}