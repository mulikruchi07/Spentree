// lib/screens/profile/helpdesk_screen.dart
// Change: added SystemUIService.applyNavBarStyle() — same fix as about_screen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart'; // NEW

class HelpdeskScreen extends StatelessWidget {
  const HelpdeskScreen({super.key});

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
                    "Helpdesk",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
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
                    "Welcome to Spentree Help\nHere you'll find answers to common questions about how the app works.",
                  ),
                  const SizedBox(height: 12),
                  _buildExpansionRow(
                    "What is Spentree?",
                    "Spentree is a personal finance habit-building app that helps users track daily spending and build better money awareness through visual tools like trees and forests.",
                  ),
                  _buildExpansionRow(
                    "How does the daily limit work?",
                    "You set a daily spending limit in your profile. As you spend during the day, Spentree tracks how much of your limit you've used. Your tree changes based on how close you are to your limit. At midnight, your daily tree resets for a fresh start.",
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
                    "Why am I getting spending alerts?",
                    "Spending alerts are designed to keep you mindful. You will receive notifications as you approach 100% of your daily limit.",
                  ),
                  _buildExpansionRow(
                    "Is my data safe?",
                    "Your privacy is a priority. All transaction processing happens locally on your device, and we do not sell your personal financial data to third parties.",
                  ),
                  _buildExpansionRow(
                    "I overspent today. What happens?",
                    "If you exceed your limit, your tree for the day will appear withered in your history. However, every day is a fresh start to try again!",
                  ),
                  _buildExpansionRow(
                    "How is my data used by Spentree?",
                    "SMS parsing is simply the process of reading a text message and automatically understanding what information it contains. Instead of asking the user to manually enter every expense, the app reads bank transaction SMS, identifies whether it is a real transaction, extracts important details such as the amount spent, the merchant or person's name, the date and time, and the payment method, and then saves it as an expense. It also ignores irrelevant messages like OTPs, promotional offers, payment requests, and failed transactions, ensuring that only genuine spending transactions are recorded automatically. This makes expense tracking fast, accurate, and effortless for the user.",
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Still need help?",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPoppinsText("We're here for you."),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.colblack,
                      ),
                      children: [
                        const TextSpan(text: "Contact us at: "),
                        TextSpan(
                          text: "team.spentree@gmail.com",
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
          ), // SafeArea
        );
      },
    );
  }

  Widget _buildExpansionRow(String title, String content) {
    return Theme(
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
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/ruchi-mulik-816a2b295"),
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
