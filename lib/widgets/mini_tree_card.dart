import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_style.dart'; // Make sure this path is correct

class MiniTreeCard extends StatelessWidget {
  final double todayExpense;
  final int dailyLimit;
  final Uint8List treeBytes; // ADDED
  final VoidCallback onTap;

  const MiniTreeCard({
    super.key,
    required this.todayExpense,
    required this.dailyLimit,
    required this.treeBytes, // ADDED
    required this.onTap,
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

    String badgeText;
    Color statusColor;
    IconData badgeIcon;

    if (percentage >= 0.83) {
      badgeText = "Great";
      statusColor = const Color(0xFF34C759);
      badgeIcon = Icons.trending_up;
    } else if (percentage >= 0.66) {
      badgeText = "Good";
      statusColor = const Color(0xFF34C759);
      badgeIcon = Icons.trending_up;
    } else if (percentage >= 0.50) {
      badgeText = "Warning";
      statusColor = const Color(0xFFFFCC00);
      badgeIcon = Icons.warning_amber_rounded;
    } else if (percentage >= 0.33) {
      badgeText = "Careful";
      statusColor = const Color(0xFFFFCC00);
      badgeIcon = Icons.warning_amber_rounded;
    } else if (percentage >= 0.16) {
      badgeText = "Poor";
      statusColor = const Color(0xFFFF383C);
      badgeIcon = Icons.trending_down;
    } else {
      badgeText = "Empty";
      statusColor = const Color(0xFFFF383C);
      badgeIcon = Icons.trending_down;
    }

    // AspectRatio guarantees it is ALWAYS a perfect square
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: onTap,
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
                    scale:
                        1.15, // Increased slightly to beautifully close the gap to the badge
                    alignment: Alignment.bottomCenter,
                    child: Image.memory(treeBytes, fit: BoxFit.fitWidth),
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
                        color: AppColors
                            .bgWhite, // Solid white background (no border)
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
      ),
    );
  }
}
