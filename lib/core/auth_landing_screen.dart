import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/auth/sign_up_screen.dart';
import 'package:spentree/screens/profile/eula_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:spentree/screens/profile/terms_screen.dart';
import 'package:spentree/screens/profile/privacy_screen.dart';
import 'package:spentree/core/auth_helper.dart';

class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});
  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  String? _googleError;

  // Matching SignUpScreen dimensions for consistency
  final double horizontalPadding = 24.0;
  final double componentHeight = 60.0;
  final double cornerRadius = 14.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // HEADER (Matches SignUpScreen size & color)
                  Text(
                    "Join Spentree",
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SUBTEXT (Matches SignUpScreen style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit,",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey700,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // TIGHTER SPACING as requested (Reduced from 32 to 24)
                  const SizedBox(height: 24),

                  // EMAIL BUTTONS
                  _buildButton(
                    label: "Create account with Email ID",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    label: "Sign in using Email ID",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DIVIDER
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.inactiveGrey)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Or",
                          style: GoogleFonts.poppins(color: AppColors.textGrey),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.inactiveGrey)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSocialButton(
                    imagePath: 'assets/images/google.png',
                    label: "Continue using Google",
                    onTap: () async {
                      final error = await AuthHelper.signInWithGoogle();
                      if (error != null && mounted)
                        setState(() => _googleError = error);
                    },
                  ),
                  if (_googleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _googleError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: AppColors.errorRed,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 26),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.grey700,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: "By creating an account, you agree to our ",
                          ),
                          TextSpan(
                            text: "Terms of Service",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ", "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ", and "),
                          TextSpan(
                            text: "End User License Agreement",
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EulaScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // const SizedBox(height: 16),
                  // _buildSocialButton(
                  //   imagePath: 'assets/images/apple.png',
                  //   label: "Continue using Apple",
                  //   onTap: () => _signInWithOAuth(OAuthProvider.apple),
                  // ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: componentHeight,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.inputFill, // Using theme-aware input color
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.grey800,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: componentHeight,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.inputFill,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 24, width: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> _signInWithOAuth(OAuthProvider provider) async {
  //   try {
  //     await Supabase.instance.client.auth.signInWithOAuth(
  //       provider, // ← was hardcoded to OAuthProvider.google
  //       redirectTo: 'spentree://login-callback',
  //       authScreenLaunchMode: LaunchMode.inAppWebView,
  //     );
  //   } catch (e) {
  //     debugPrint("Social Auth Error: $e");
  //   }
  // }
}
