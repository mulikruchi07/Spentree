import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            Text(
              "Privacy Policy",
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
              ),
            ),
            const SizedBox(height: 24),
            _buildBodyText(
              "Your privacy is important to us. This policy explains what data Spentree collects and how it is used.",
            ),

            _buildSection(
              "1. Information We Access",
              "To help track expenses automatically, Spentree may request permission to read transaction-related SMS messages on your device. We only look for messages that contain debit/credit details, merchant names, amounts, and dates.",
            ),
            _buildBoldText(
              "We do not read personal conversations, OTP messages, or unrelated texts.",
            ),

            _buildSection(
              "2. How SMS Data Is Used",
              "Transaction details extracted from SMS are used only to detect expenses/income, show analysis, and update your forest. This processing happens locally on your device.",
            ),

            _buildSection(
              "3. Data Storage",
              "Your financial data, including transactions, limits, and forest progress, is stored securely on your device.",
            ),
            _buildBoldText("Spentree does not sell your data."),

            _buildSection(
              "4. Data Sharing",
              "We do not share your personal financial data with advertisers or third parties. If cloud backup is added later, users will be given full control.",
            ),

            _buildSection("5. Permissions We May Request", ""),
            _buildBoldText("SMS Access:"),
            _buildBodyText(
              "To detect transaction messages for expense tracking.",
            ),
            _buildBoldText("\nNotifications:"),
            _buildBodyText(
              "To alert you when you approach your spending limit.",
            ),

            _buildSection("6. Your Control", "You can:"),
            _buildBodyText(
              "• Edit or delete transactions\n• Turn off SMS tracking\n• Reset your data inside the app\nYou are always in control of your information.",
            ),

            _buildSection(
              "7. Security",
              "We use standard device-level security practices to protect your data. However, no system can be guaranteed 100% secure.",
            ),

            _buildSection(
              "8. Children’s Privacy",
              "Spentree is not intended for children under 16. We do not knowingly collect data from children.",
            ),

            _buildSection(
              "9. Changes to This Policy",
              "We may update this Privacy Policy to reflect improvements. Users will be notified of significant changes.",
            ),

            _buildSection(
              "10. Contact",
              "If you have questions about privacy or data use, contact:",
            ),
            _buildBoldText("support@spentree.in"),

            const SizedBox(height: 32),
            _buildAgreeButton(context),
            const SizedBox(height: 48),
            _buildFooter(),
            const SizedBox(height: 50),
          ],
        ),
      ),
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
              fontSize: 16,
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

  Widget _buildBoldText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      color: AppColors.colblack,
    ),
  );

  Widget _buildAgreeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          "I agree",
          style: GoogleFonts.montserrat(
            color: AppColors.colwhite,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com"),
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
          onTap: () => _launchURL("https://linkedin.com"),
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
