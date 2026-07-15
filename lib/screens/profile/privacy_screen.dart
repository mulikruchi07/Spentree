// lib/screens/profile/privacy_screen.dart
// Change: added SystemUIService.applyNavBarStyle()

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import '../../core/system_ui_service.dart'; // NEW

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                    "Privacy Policy",
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
                    "Welcome to Spentree (\"we,\" \"our,\" or \"us\"). We are committed to protecting your privacy and ensuring your data is handled with the utmost transparency and security.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Spentree is a financial tracking and analytics application. To provide seamless automated expense tracking, Spentree requests access to your SMS messages. We do not read your personal conversations. We use an offline-first architecture to parse only bank-related transaction messages locally on your device. We place your privacy at the forefront of our operations. To guarantee complete confidentiality, we employ advanced hashing and encryption protocols on all sensitive financial information before it is transmitted to our cloud environment. We are not able to routinely access or view your personal financial information except where required for providing the service, troubleshooting with your consent, or where required by applicable law.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "This Privacy Policy explains how we collect, use, process, and protect your information when you use the Spentree mobile application and our waitlist website. This policy complies with the Digital Personal Data Protection Act, 2023 (DPDP Act) and the Information Technology Act, 2000 of India.",
                  ),

                  _buildSection(
                    "1. Information We Collect",
                    "We collect only the data necessary to provide and improve the Spentree experience.",
                  ),
                  _buildBoldText("A. Information You Provide Directly"),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Waitlist Sign-up Details: Submitting your information through our landing page limits our collection exclusively to your Email Address. Please note that waitlist registration is independent of account creation; a full registration process is required upon our official release.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Account: When you sign in using Google Authentication, we receive only the information you authorize Google to share with us, such as your name, email address, and profile picture. We never receive or store your Google account password. During account creation, users provide explicit consent to the Terms of Service, Privacy Policy, and End User License Agreement. We retain a timestamp and version of the accepted legal documents for compliance purposes.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Onboarding Data: During setup, we collect your financial goals, spending limits, and preferred categories (e.g., Food, Shopping, Bills) to personalize your growing \"Forest\" and dashboard.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Manual Entries: Any expenses or transactions you manually add to the app.",
                  ),
                  const SizedBox(height: 16),
                  _buildBoldText(
                    "B. Information Processed Automatically (The READ_SMS Permission)",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "To automate your expense tracking, Spentree requests the READ_SMS permission.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "What we look for: SMS messages are scanned strictly offline on your device. We exclusively scan for financial keywords (e.g., \"debited,\" \"Rs.\", \"spent\") and specific sender IDs associated with banks, credit cards, and cooperative institutions.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "What we extract: Transaction amount, date, time, and merchant/receiver name. This data is hashed before being synced to our secure cloud database. This means the data is scrambled into an unreadable format. We (the developers) cannot see who you paid, how much you spent, or when you spent it.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "What we ignore: We actively filter out OTPs (One Time Passwords), failed transactions, refunds, initial Autopay/Mandate setup micro-transactions, and non-financial personal messages.",
                  ),
                  const SizedBox(height: 16),
                  _buildBoldText("C. Notification Permission"),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Spentree may request notification permission to send spending limit alerts when you exceed your configured spending limit. Notification permission is optional and can be enabled or disabled at any time through your device settings.",
                  ),
                  const SizedBox(height: 16),
                  _buildBoldText("D. Local Storage, Device & App Usage Data"),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Spentree stores certain preferences locally on your device, including theme settings, onboarding progress, biometric lock preferences, permission states, and other application settings to improve your experience. We also process:",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "• Authentication tokens and biometric lock states (FaceID/Fingerprint settings are processed locally on your device).\n• Standard Supabase connection logs (such as error logs or failed login attempts) to maintain app security and fix bugs.\n• Your current app level, seeds earned, unlocked achievements, and the visual state of your forest.",
                  ),

                  _buildSection(
                    "2. The \"Offline-First\" Promise: How We Process SMS Data",
                    "Because we handle sensitive financial data, we have designed Spentree with an Offline-First Architecture.",
                  ),
                  _buildBodyText(
                    "Local Parsing: When an SMS arrives, our engine (SmsReceiver) parses the message entirely offline on your device.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "No Inbox Uploads: Your raw SMS inbox, personal texts, and OTPs are never uploaded to our servers, nor are they shared with any third party.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Syncing: Only the structured, extracted transaction data (Amount, Date, Merchant Name) is synced to our secure cloud database (Supabase) so you can access your dashboard across devices.",
                  ),

                  _buildSection(
                    "3. How We Use Your Information",
                    "We use the extracted and provided data strictly for the following purposes:",
                  ),
                  _buildBodyText(
                    "• To automatically generate your daily, weekly, and monthly expense analytics.\n• To visualize your spending habits through our interactive \"Forest\" UI (e.g., growing or drying trees based on your limits).\n• To securely authenticate your account and sync your data.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Push Notifications: We respect your peace. Spentree will only send you push notifications on your device when you exceed your set spending limits. Notification permission is optional and can be changed at any time through your device settings.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Email Communications: We will only email you for critical updates, such as waitlist launch announcements, major app security updates, changes to your account data, or updates to this Privacy Policy.",
                  ),

                  _buildSection(
                    "4. Data Storage, Security, and Third Parties",
                    "We classify your financial data as Sensitive Personal Data or Information (SPDI) and employ bank-grade security:",
                  ),
                  _buildBodyText(
                    "Cloud Security & Authentication (Supabase): Your synced transactions are stored in our backend using strict Row Level Security (RLS) policies. This guarantees that your data is encrypted and can only be queried and viewed by your specific authenticated user ID. Authentication is managed through Supabase Authentication using industry-standard authentication tokens. To enhance account security, Spentree currently permits only one active authenticated session per account. Signing in on another device may automatically terminate the previous session.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Local Security (App Lock): We provide local biometric authentication (Fingerprint/FaceID) to lock the Spentree app, ensuring no one who handles your unlocked phone can view your financial data.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Third-Party Services: We do not sell, rent, or trade your personal or financial data to advertisers or data brokers. We only share data with essential service providers (like Google Cloud/Supabase for database hosting) who are bound by strict confidentiality agreements.",
                  ),

                  _buildSection(
                    "5. Your Rights & Controls (Under DPDP Act, 2023)",
                    "As a user in India, you have full ownership of your data. Within the Spentree app, you can:",
                  ),
                  _buildBodyText(
                    "Right to Access & Portability: View all your processed transactions and profile data.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Right to Correction (Hide/Edit): You can manually edit merchant names, change categories, or \"Hide\" specific transactions from your analytics.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Right to Erasure (Permanent Deletion): You can permanently delete specific transactions. Once deleted, our engine places the transaction ID in a local _deletedKey vault, ensuring it is never re-fetched or re-synced, even if the original SMS is still on your phone. If you choose to delete your Spentree account via the in-app settings, all your data is deleted immediately from our active Supabase servers. We do not hold onto your data after you delete your account.",
                  ),
                  const SizedBox(height: 8),
                  _buildBodyText(
                    "Right to Withdraw Consent: You can revoke the READ_SMS permission at any time via your Android device settings. Spentree will immediately stop parsing new messages, though you will lose automated tracking features.",
                  ),

                  _buildSection(
                    "6. Data Retention",
                    "Waitlist Data: Waitlist emails are kept solely to track interest and send app launch notifications, after which they are deleted upon your request or when no longer needed.",
                  ),
                  _buildBodyText(
                    "App Data: We retain your transaction history and profile data only for as long as your account is active. If you delete your account, your data is permanently expunged from our active Supabase servers immediately.",
                  ),

                  _buildSection(
                    "7. Children's Privacy",
                    "Spentree is designed to help students, freelancers, and early earners build better money habits through gamification. There is no minimum age requirement to use the app, and we welcome young adults striving for financial discipline.",
                  ),
                  _buildBodyText(
                    "However, under Indian law, if you are under the age of 18, you represent and warrant that you have obtained the consent of your parent or legal guardian to use Spentree and agree to these terms.",
                  ),

                  _buildSection(
                    "8. Changes to this Privacy Policy",
                    "We may update this Privacy Policy as we add new features or as legal requirements change. If we make material changes (especially regarding how we handle SMS data), we will provide a prominent notice by sending you an email before the changes take effect.",
                  ),

                  _buildSection(
                    "9. Grievance Redressal Mechanism",
                    "In accordance with the Information Technology Act, 2000 and the DPDP Act, 2023, if you have any discrepancies or grievances regarding your data, please contact our Grievance Officer:",
                  ),
                  _buildBodyText(
                    "Name: Pranav Phanse\nEmail: team.spentree@gmail.com\nAddress: Mumbai, Maharashtra\nTime to Respond: We will acknowledge your complaint within 24 hours and resolve it within 15 days.",
                  ),
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
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
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
