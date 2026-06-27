import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../core/app_style.dart'; // Directly pulling from your style file

class TodaysTreeCard extends StatelessWidget {
  final double todayExpense;
  final int dailyLimit;
  final Uint8List treeBytes;
  final VoidCallback onGoToDashboard;
  final VoidCallback onSwapTap;

  const TodaysTreeCard({
    super.key,
    required this.todayExpense,
    required this.dailyLimit,
    required this.treeBytes,

    required this.onGoToDashboard,
    required this.onSwapTap,
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

    if (percentage >= 0.83) {
      badgeText = "Great";
      statusColor = const Color(0xFF34C759);
    } else if (percentage >= 0.66) {
      badgeText = "Good";
      statusColor = const Color(0xFF34C759);
    } else if (percentage >= 0.50) {
      badgeText = "Warning";
      statusColor = const Color(0xFFFFCC00);
    } else if (percentage >= 0.33) {
      badgeText = "Careful";
      statusColor = const Color(0xFFFFCC00);
    } else if (percentage >= 0.16) {
      badgeText = "Poor";
      statusColor = const Color(0xFFFF383C);
    } else {
      badgeText = "Empty";
      statusColor = const Color(0xFFFF383C);
    }

    return GestureDetector(
      onTap: onGoToDashboard,
      child: Container(
        padding: const EdgeInsets.only(
          top: 18,
          left: 14,
          right: 14,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgWhite, // Using your exact AppColors variable
          borderRadius: BorderRadius.circular(40.31),
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
          children: [
            // ==========================================
            // TOP HEADER
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onSwapTap,
                  child: Container(
                    width: 42,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.arrowsLeftRight,
                      size: 16,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
                Text(
                  "Today's Tree",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                GestureDetector(
                  onTap: onGoToDashboard,
                  child: Container(
                    width: 52,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ==========================================
            // MAIN TREE IMAGE
            // ==========================================
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                height: 168,
                decoration: BoxDecoration(
                  color: statusColor,
                  image: DecorationImage(
                    image: MemoryImage(
                      treeBytes,
                    ), // Draws instantly from RAM bytes
                    fit: BoxFit.fitHeight, // Fills the box perfectly
                    alignment: Alignment
                        .bottomCenter, // Grounds the tree to the bottom
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // TODAY'S EXPENSE ROW
            // ==========================================
            Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color:
                    AppColors.inputFill, // Using your exact AppColors variable
                borderRadius: BorderRadius.circular(50.39),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Today's Expense",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors
                              .white600, // Using your exact AppColors variable
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rs. ${NumberFormat('#,##0').format(todayExpense)}",
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),
                  // Dynamic Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badgeText == "Great"
                              ? Icons.trending_up
                              : Icons.warning_amber_rounded,
                          color: badgeText == "Warning"
                              ? Colors.black
                              : Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: badgeText == "Warning"
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ==========================================
            // PENDING LIMIT ROW
            // ==========================================
            Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    AppColors.inputFill, // Using your exact AppColors variable
                borderRadius: BorderRadius.circular(50.39),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pending Limit",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors
                          .white600, // Using your exact AppColors variable
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "Rs. ${NumberFormat('#,##0').format(pendingLimit)} ",
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.colblack,
                          ),
                        ),
                        TextSpan(
                          text: "/ ${NumberFormat('#,##0').format(dailyLimit)}",
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.colblack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
