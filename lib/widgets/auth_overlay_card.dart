import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_style.dart'; // Make sure this path is correct

class AuthOverlayCard extends StatelessWidget {
  final bool isSignUpMode; // Toggles between Log in and Sign up states
  final VoidCallback onActionTap;

  const AuthOverlayCard({
    super.key,
    this.isSignUpMode = false, // Defaults to "Log in" mode
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Generous vertical padding to give it that tall, spacious look
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(
          40.31,
        ), // Exact radius from your other cards
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ==========================================
          // BRAND LOGO
          // ==========================================
          // Replace the asset path below with your actual exported 'S' logo image!
          Image.asset(
            'assets/images/spentree_logo.png', // Make sure to add your logo to your assets folder
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            // Fallback icon just in case the image isn't loaded yet
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.hexagon_outlined,
              size: 72,
              color: AppColors.primaryGreen,
            ),
          ),

          const SizedBox(height: 28),

          // ==========================================
          // DYNAMIC TEXT
          // ==========================================
          Text(
            isSignUpMode
                ? "Create Your Account To Access\nThis Feature"
                : "Log In To Your Account To Access\nThis Feature", // Slightly adjusted for Log In grammar
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500, // Medium weight matching Figma
              color: AppColors.colblack,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // ==========================================
          // PILL BUTTON
          // ==========================================
          SizedBox(
            height: 46, // Height of the pill
            width:
                140, // Fixed width keeps the button looking compact and centered
            child: ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Perfect pill shape
                ),
              ),
              child: Text(
                isSignUpMode ? "Sign up" : "Log in",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
