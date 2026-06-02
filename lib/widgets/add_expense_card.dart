import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_style.dart'; // Make sure this points to your style file

class AddExpenseCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddExpenseCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // Guarantees a perfect square
      child: GestureDetector(
        onTap: onTap, // Triggers the redirect when tapped anywhere on the card
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgWhite, // Solid white background
            borderRadius: BorderRadius.circular(25), // Matches the MiniTreeCard
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // TOP: THE GREEN CIRCLE BUTTON
              // ==========================================
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.colwhite,
                  size: 22, // Sleek, thin white plus icon
                ),
              ),

              const Spacer(), // Pushes the text perfectly to the bottom
              // ==========================================
              // BOTTOM: TITLES & SUBTITLES
              // ==========================================
              Text(
                "Add Expense",
                style: GoogleFonts.montserrat(
                  fontSize: 17.74,
                  fontWeight: FontWeight.w700, // Bold as per Figma
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                "Keep a track of your\ncash transactions.",
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey800, // Gray subtitle color
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
