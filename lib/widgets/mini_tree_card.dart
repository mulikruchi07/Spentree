import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_style.dart'; // Make sure this path is correct

class MiniTreeCard extends StatelessWidget {
  final double todayExpense;
  final int dailyLimit;

  const MiniTreeCard({
    super.key,
    required this.todayExpense,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    // --- MATH & LOGIC ---
    final double pendingLimit = (dailyLimit - todayExpense).clamp(
      0.0,
      dailyLimit.toDouble(),
    );
    final double percentage = dailyLimit > 0
        ? (pendingLimit / dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    String treeImagePath;
    String badgeText;
    Color statusColor;
    IconData badgeIcon;

    if (percentage >= 0.66) {
      treeImagePath = percentage >= 0.83
          ? "assets/images/dashboard/tree_1.png"
          : "assets/images/dashboard/tree_2.png";
      badgeText = "Great";
      statusColor = const Color(0xFF34C759); // Green
      badgeIcon = Icons.trending_up;
    } else if (percentage >= 0.33) {
      treeImagePath = percentage >= 0.50
          ? "assets/images/dashboard/tree_3.png"
          : "assets/images/dashboard/tree_4.png";
      badgeText = "Warning";
      statusColor = const Color(0xFFFFCC00); // Yellow
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      treeImagePath = percentage >= 0.16
          ? "assets/images/dashboard/tree_5.png"
          : "assets/images/dashboard/tree_6.png";
      badgeText = "Poor";
      statusColor = const Color(0xFFFF383C); // Red
      badgeIcon = Icons.trending_down;
    }

    // AspectRatio guarantees it is ALWAYS a perfect square
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: statusColor, // The entire card is the solid status color
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ==========================================
              // BOTTOM LAYER: THE TREE (SCALED UP, NOT CUT OFF)
              // ==========================================
              Positioned(
                bottom: 0, 
                left: 0,
                right: 0,
                // Inner ClipRRect is gone. Tree can now stretch up freely!
                child: Transform.scale(
                  scale: 1.15, // Increased slightly to beautifully close the gap to the badge
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    treeImagePath,
                    fit: BoxFit.fitWidth, 
                  ),
                ),
              ),

            // ==========================================
            // TOP LAYER: THE CENTERED WHITE BADGE
            // ==========================================
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ), // Distance from the top
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.bgWhite, // Solid white background (no border)
                    borderRadius: BorderRadius.circular(17.59),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badgeIcon,
                        color:
                            statusColor, // Icon is the colored status (Green/Yellow/Red)
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor, // Text is the colored status
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}