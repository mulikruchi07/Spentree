import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';

class HelpdeskScreen extends StatelessWidget {
  const HelpdeskScreen({super.key});

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

            // --- Header ---
            Text(
              "Helpdesk",
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
              "Welcome to Spentree Help\nHere you’ll find answers to common questions about how the app works.",
            ),

            const SizedBox(height: 12),

            // --- FAQ Expansion List ---
            _buildExpansionRow(
              "What is Spentree?",
              "Spentree is a personal finance habit-building app that helps users track daily spending and build better money awareness through visual tools like trees and forests.",
            ),

            _buildExpansionRow(
              "How does the daily limit work?",
              "You set a daily spending limit in your profile. As you spend during the day, Spentree tracks how much of your limit you’ve used. Your tree changes based on how close you are to your limit. At midnight, your daily tree resets for a fresh start.",
            ),

            _buildExpansionRow(
              "How do I grow my forest?",
              "Every day you stay within your limit, a healthy tree is added to your permanent forest. Over time, your consistency builds a lush landscape representing your financial health.",
            ),

            _buildExpansionRow(
              "Can I add expenses manually?",
              "Yes. While Spentree can detect transaction SMS, you can always use the '+' button on the dashboard to log cash expenses or manual entries.",
            ),

            _buildExpansionRow(
              "How do I split an expense with friends?",
              "Tap on any transaction in your history and select the 'Split' option. You can enter the number of people to divide the cost and track your share accurately.",
            ),

            _buildExpansionRow(
              "Can I edit or delete a transaction?",
              "Absolutely. Swipe left on any transaction in your history to reveal the Edit and Delete options. This ensures your forest data remains accurate.",
            ),

            _buildExpansionRow(
              "Why am I getting spending alerts?",
              "Spending alerts are designed to keep you mindful. You will receive notifications as you approach 80% and 100% of your daily limit.",
            ),

            _buildExpansionRow(
              "Is my data safe?",
              "Your privacy is a priority. All transaction processing happens locally on your device, and we do not sell your personal financial data to third parties.",
            ),

            _buildExpansionRow(
              "I overspent today. What happens?",
              "If you exceed your limit, your tree for the day will appear withered in your history. However, every day is a fresh start to try again!",
            ),

            const SizedBox(height: 16),

            // --- Contact Section ---
            Text(
              "Still need help?",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
              ),
            ),
            const SizedBox(height: 8),
            _buildPoppinsText("We’re here for you."),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.colblack,
                ),
                children: [
                  const TextSpan(text: "Contact us at: "),
                  TextSpan(
                    text: "support@spentree.app",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildFooter(context),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Helper for Styled Expansion Tile with Parallel Lines
  Widget _buildExpansionRow(String title, String content) {
    return Theme(
      // Removes the default highlighted border when expanded
      data: ThemeData().copyWith(
        dividerColor: AppColors.colblack.withOpacity(0.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.colblack.withOpacity(0.8),
              width: 1,
            ),
          ),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.colblack,
            ),
          ),
          iconColor: AppColors.desctext,
          collapsedIconColor: AppColors.colblack.withOpacity(0.5),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.colblack.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start, // Ensures left alignment
      children: [
        // Line 1: Planted with love
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400, // Poppins Medium
            color: AppColors.white500,
          ),
        ),
        const SizedBox(height: 4),

        // Line 2: Designed by Designer
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com/in/designer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                const TextSpan(
                  text: "Designed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ), // Poppins Medium
                ),
                TextSpan(
                  text: "Designer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200, // Poppins ExtraLight
                    fontStyle: FontStyle.italic, // Italic
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Line 3: Developed by Developer
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com/in/developer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                const TextSpan(
                  text: "Developed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ), // Poppins Medium
                ),
                TextSpan(
                  text: "Developer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200, // Poppins ExtraLight
                    fontStyle: FontStyle.italic, // Italic
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
