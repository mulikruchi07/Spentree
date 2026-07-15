// lib/screens/profile/eula_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart';

class EulaScreen extends StatelessWidget {
  const EulaScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    SystemUIService.applyNavBarStyle(context);

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
                    "End-User License Agreement",
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
                    "This End-User License Agreement (\"Agreement\") is a legal agreement between you (the \"User\") and the Spentree development team (\"we,\" \"us,\" or \"our\") regarding your use of the Spentree mobile application (\"the Software\").",
                  ),

                  _buildSection(
                    "1. License Grant",
                    "By downloading, installing, or using the Software, you are granted a limited, non-exclusive, non-transferable, and revocable license to use the Software strictly for your personal, non-commercial purposes. You are not buying the software; you are being granted a license to access and use its features subject to this Agreement.",
                  ),

                  _buildSection(
                    "2. Intellectual Property Rights",
                    "The Software, including all source code, design elements (such as the virtual ecosystem, tree/forest graphics, and UI), and branding, is the sole property of Spentree. You may not:",
                  ),
                  _buildBodyText(
                    "• Copy, modify, or create derivative works of the Software.\n• Decompile, reverse-engineer, or attempt to extract the source code.\n• Use our trademarks, logos, or assets without our express written consent.",
                  ),

                  _buildSection(
                    "3. SMS Parsing (\"As-Is\" Provision)",
                    "Spentree uses automated logic to parse financial SMS data to assist in expense tracking. You acknowledge and agree that:",
                  ),
                  _buildBodyText(
                    "• The automated parsing feature is provided on an \"as-is\" and \"as-available\" basis.\n• Parsing accuracy may vary depending on bank messaging formats, device settings, or network conditions.\n• We provide no guarantee that all financial transactions will be captured, categorized, or accurately logged. You are responsible for verifying your financial records.",
                  ),

                  _buildSection(
                    "4. Limitation of Liability",
                    "To the maximum extent permitted by applicable law, in no event shall the Spentree team be liable for any direct, indirect, special, incidental, or consequential damages arising out of:",
                  ),
                  _buildBodyText(
                    "• Any disruption, error, or failure in the Software (e.g., app crashes, incorrect transaction parsing, or synchronization errors).\n• Unauthorized access to your account if such access results from your failure to keep your credentials secure.\n• Data loss or corruption, including any data lost due to device failures or syncing interruptions.\n• Any financial decisions made, or actions taken, based on the data reported within the app.",
                  ),

                  _buildSection(
                    "5. Termination",
                    "This Agreement is effective until terminated by you or us. Your rights under this license will terminate automatically if you fail to comply with any of the terms of this Agreement. Upon termination, you must cease all use of the Software and delete all copies from your device.",
                  ),

                  _buildSection(
                    "6. Disclaimer of Warranties",
                    "We provide the software without any warranty of any kind, whether express or implied. We do not warrant that the software will be error-free, that the service will be uninterrupted, or that any defects will be corrected.",
                  ),

                  _buildSection(
                    "7. Governing Law",
                    "This Agreement is governed by and construed in accordance with the laws of India. Any legal action or proceeding arising under this Agreement shall be brought exclusively in the courts located in Mumbai, Maharashtra.",
                  ),

                  const SizedBox(height: 32),
                  _buildFooter(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
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
