import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../core/app_style.dart'; // Make sure this path is correct

class GreetingCard extends StatelessWidget {
  final String userName;
  final double todayExpense;
  final int dailyLimit;
  final String? profileImageUrl;
  final VoidCallback onArrowTap;

  const GreetingCard({
    super.key,
    required this.userName,
    required this.todayExpense,
    required this.dailyLimit,
    this.profileImageUrl,
    required this.onArrowTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- MATH & LOGIC FOR BADGE ---
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

    if (percentage >= 0.66) {
      badgeText = "Great";
      statusColor = const Color(0xFF34C759); // Green
      badgeIcon = Icons.trending_up;
    } else if (percentage >= 0.33) {
      badgeText = "Warning";
      statusColor = const Color(0xFFFFCC00); // Yellow
      badgeIcon = Icons.warning_amber_rounded;
    } else {
      badgeText = "Poor";
      statusColor = const Color(0xFFFF383C); // Red
      badgeIcon = Icons.trending_down;
    }

    // --- DATE FORMATTING ---
    String formattedDate = DateFormat("E, d MMMM ''yy").format(DateTime.now());

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 14, right: 14, bottom: 19),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(40.11), // Exact radius requested
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==========================================
          // TOP ROW: PROFILE, GREETING, ARROW BUTTON
          // ==========================================
          Row(
            children: [
              // Profile Image or Default Avatar (60x60, No Yellow)
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF4F4F4,
                  ), // Clean light gray instead of yellow
                  shape: BoxShape.circle,
                  image: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(profileImageUrl!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profileImageUrl == null || profileImageUrl!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFFBDBDBD), // Soft gray default icon
                        size: 42,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name and Welcome Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $userName",
                      style: GoogleFonts.montserrat(
                        fontSize: 16.05,
                        fontWeight: FontWeight.w600, // SemiBold
                        color: AppColors.colblack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Welcome back",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w400, // Regular
                        color: const Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),

              // Top Right Arrow Button (58.16 x 58.16, border width 1)
              GestureDetector(
                onTap: onArrowTap,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.redirctcircle,
                      width: 1, // Exact border width
                    ),
                  ),
                  child: Icon(
                    PhosphorIconsRegular.arrowUpRight,
                    color: AppColors.divider,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ==========================================
          // BOTTOM ROW: DATE, AMOUNT & BADGE
          // ==========================================
          Padding(
            // Adjust this 'horizontal' value to increase or decrease the left/right gap!
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Today's Expense  •  ",
                        style: GoogleFonts.montserrat(
                          fontSize: 12.03,
                          fontWeight: FontWeight.w500, // Medium
                          color: const Color(
                            0xFF636363,
                          ), // Exact color requested
                        ),
                      ),
                      TextSpan(
                        text: formattedDate,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.03,
                          fontWeight: FontWeight.w500, // Medium
                          color: const Color(0xFF636363),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Amount Text (Size 40, Bold)
                    Text(
                      "Rs. ${NumberFormat('#,##0').format(todayExpense)}",
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700, // Bold
                        color: AppColors.colblack,
                        letterSpacing: -1,
                      ),
                    ),

                    // Dynamic Status Badge (Text Size 12, Medium)
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
                            badgeIcon,
                            color: badgeText == "Warning"
                                ? Colors.black
                                : Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500, // Medium
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
