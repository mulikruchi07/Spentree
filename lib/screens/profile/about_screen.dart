import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml
import '../../core/app_style.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Function to launch LinkedIn URLs
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allows hardware back button to return to Profile
      child: Scaffold(
        backgroundColor: AppColors.bgWhite,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // Add this Column
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Text(
                "About",
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
                "Spentree was created with one simple idea:\nBuilding money habits should feel encouraging, not stressful.",
              ),
              _buildPoppinsText(
                "Most finance apps focus on numbers, limits, and warnings.",
              ),
              const SizedBox(height: 12),
              _buildPoppinsText(
                "Spentree takes a different approach.\nWe turn your daily spending habits into something you can see grow.",
              ),
              const SizedBox(height: 12),
              _buildPoppinsText(
                "Every smart decision helps your tree stay healthy.\nEvery mindful day adds to your forest.",
              ),

              const SizedBox(height: 16),
              _buildSectionHeading("Why We Built Spentree?"),
              _buildPoppinsText(
                "Managing money, especially when you're young, can feel overwhelming. Budgets feel strict. Tracking feels tiring. Guilt often replaces motivation.",
              ),
              const SizedBox(height: 12),
              _buildPoppinsText("Spentree was designed to change that."),
              const SizedBox(height: 12),
              _buildPoppinsText(
                "Instead of telling you what you did wrong, Spentree shows you how small improvements can grow into something bigger — just like a forest.",
              ),

              const SizedBox(height: 12),
              _buildPoppinsText("We believe habits grow best with:"),
              _buildPoppinsText(
                "• Gentle reminders, not pressure\n• Visual progress, not spreadsheets\n• Consistency, not perfection",
              ),

              const SizedBox(height: 16),
              _buildSectionHeading("Our Philosophy"),
              _buildPoppinsText(
                "Money habits are like plants.\nThey don’t grow overnight. They need regular care, patience, and small daily efforts.",
              ),
              _buildPoppinsText(
                "Some days are dry. Some days it rains. But with time, a single plant becomes a forest.\nSpentree is here to help you see that journey.",
              ),

              const SizedBox(height: 16),
              _buildSectionHeading("Built for Everyday Life"),
              _buildPoppinsText(
                "Spentree is made for:\n• Students learning to manage expenses\n• Young professionals balancing spending and saving\n• Anyone who wants better control without feeling judged",
              ),
              _buildPoppinsText(
                "We focus on awareness and balance — not restriction.",
              ),

              const SizedBox(height: 16),
              _buildSectionHeading("Our Promise"),
              _buildPoppinsText(
                "We aim to keep Spentree:\n• Simple\n• Positive\n• Private\n• Helpful",
              ),
              const SizedBox(height: 12),
              _buildPoppinsText(
                "Your data belongs to you.\nYour growth happens at your pace.",
              ),

              const SizedBox(height: 16),
              _buildSectionHeading("Growing Together"),
              _buildPoppinsText(
                "Spentree is still growing, just like your forest. We’re always working to improve the experience and add features that help you build better money habits.",
              ),
              const SizedBox(height: 12),
              _buildPoppinsText("Thank you for being part of the journey."),

              const SizedBox(height: 12),
              _buildFooter(context),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
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
                TextSpan(
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
                TextSpan(
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
