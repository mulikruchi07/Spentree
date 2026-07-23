// lib/screens/profile/regulatory_compliance_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart';

class RegulatoryComplianceScreen extends StatelessWidget {
  const RegulatoryComplianceScreen({super.key});

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
                    "Data Protection &",
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    "Regulatory Compliance",
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText("App: Spentree"),
                  _buildBodyText("Applicable Jurisdiction: Republic of India"),
                  const SizedBox(height: 16),
                  _buildBodyText(
                    "This document outlines Spentree's strict compliance with the Digital Personal Data Protection Act, 2023 (DPDP Act) and the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011 under the IT Act, 2000.",
                  ),

                  _buildPartHeading(
                    "PART 1: Compliance with the DPDP Act, 2023",
                  ),
                  _buildBodyText(
                    "Under the DPDP Act, Spentree acts as a Data Fiduciary, and our users are Data Principals. We strictly adhere to the fundamental principles of the Act.",
                  ),

                  _buildSection(
                    "1. Itemized Notice and Explicit Consent (Section 5 & 6)",
                    "We do not collect any personal data without explicit, affirmative consent.",
                  ),
                  _buildBodyText(
                    "Plain Language Requirement: Before the READ_SMS permission is triggered on Android, Spentree provides an itemized \"Prominent Disclosure\" pop-up in plain English.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Consent Withdrawal: Users can withdraw their consent at any time via the Android Device Settings by revoking the SMS permission. This will instantly halt all automated tracking without penalizing the user's access to manual app features.",
                  ),

                  _buildSection(
                    "2. Data Minimization & Purpose Limitation (Section 8)",
                    "We only collect data that is strictly necessary for providing the gamified expense tracking experience.",
                  ),
                  _buildBodyText(
                    "What we collect: Email address, Name, Profile Image, and transaction data (Amount, Receiver, Date, Time) is encrypted before being stored in our cloud infrastructure and decrypted only for the authenticated user.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "What we DO NOT collect: We explicitly ignore and never process Personal SMS messages, OTPs (One-Time Passwords), failed transaction alerts, refund notifications, and initial Autopay setup pings (e.g., ₹1 or ₹2 test debits).",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "No Raw Data Uploads: Your raw SMS inbox is never transmitted to, uploaded to, or stored on our servers. All SMS parsing is strictly executed offline, locally on the user's device.",
                  ),

                  _buildSection(
                    "3. Rights of the Data Principal (Section 11-14)",
                    "Spentree guarantees all rights granted to Indian citizens under the DPDP Act:",
                  ),
                  _buildBodyText(
                    "Right to Access & Portability: Users can view their entire financial summary and account details natively within the app.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Right to Correction & Erasure: Users can manually edit, categorize, hide, or permanently delete specific transactions.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Right to Total Erasure: If a user chooses to delete their account, all associated data is immediately and permanently expunged from our Supabase servers.",
                  ),

                  _buildSection(
                    "4. Grievance Redressal (Section 15)",
                    "Under the DPDP Act, users must have a dedicated point of contact to resolve data discrepancies. Spentree has appointed a designated Grievance Officer:",
                  ),
                  _buildBodyText(
                    "Name: Pranav Phanse\nDesignation: Grievance Officer & Co-Founder\nContact Email: team.spentree@gmail.com\nResponse Time: We legally commit to acknowledging grievances within 24 hours and resolving them within 15 days of receipt.",
                  ),

                  _buildPartHeading(
                    "PART 2: Compliance with IT Act, 2000 & SPDI Rules, 2011",
                  ),
                  _buildBodyText(
                    "Because Spentree processes records of bank transactions, this data is classified under Indian law as Sensitive Personal Data or Information (SPDI). We have implemented \"Reasonable Security Practices and Procedures\" (Rule 8) to protect this data.",
                  ),

                  _buildSection(
                    "1. Data Localization & Hosting",
                    "To comply with Indian data sovereignty preferences, all Spentree cloud data is hosted entirely within India.",
                  ),
                  _buildBodyText(
                    "Infrastructure: Supabase (hosted on Amazon Web Services - AWS).\nRegion: ap-south-1 (Mumbai, Maharashtra, India).",
                  ),

                  _buildSection(
                    "2. Hashing & Anonymization",
                    "To ensure the absolute privacy of our users, we do not store raw transaction data in our cloud database.",
                  ),
                  _buildBodyText(
                    "When the offline SMS parser detects a valid expense, the transaction details (Merchant Name, Amount, Date) are passed through a cryptographic Hashing Algorithm before being synced to the cloud.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "This ensures that in the absolute worst-case scenario of a database breach, the data is scrambled and unreadable. Even the Spentree development team cannot read a user's personal financial history.",
                  ),

                  _buildSection(
                    "3. Bank-Grade Cloud Security (AES-256 & RLS)",
                    "Encryption at Rest and in Transit: All SPDI transmitted between the user's device and our Supabase servers is encrypted in transit using TLS 1.2/1.3. Data at rest in our AWS Mumbai servers is encrypted using standard AES-256 encryption.",
                  ),
                  _buildBodyText(
                    "Row Level Security (RLS): Our Supabase PostgreSQL database enforces strict Row Level Security policies. This means at the database architecture level, a user's authenticated session can only query, edit, or decrypt their own specific rows. Cross-user data bleed is cryptographically prevented.",
                  ),

                  _buildSection(
                    "4. Local Device Security (Rule 8 Compliance)",
                    "We recognize that the most vulnerable point for SPDI is the user's physical phone.",
                  ),
                  _buildBodyText(
                    "App Lock / Biometrics: Spentree includes native biometric authentication utilizing Android's FaceID/Fingerprint APIs. This ensures that even if a user's phone is unlocked and handed to someone else, their financial dashboard remains locked and secure.",
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

  Widget _buildPartHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
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
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/pranav-phanse-8b4bbb318"),
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
