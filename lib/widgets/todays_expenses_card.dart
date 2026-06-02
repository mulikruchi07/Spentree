import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/app_style.dart'; // Make sure this path is correct
import '../core/transaction_service.dart'; // Required for the Transaction model

class TodaysExpensesCard extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onGoToAnalytics;
  final VoidCallback onSwapTap;

  const TodaysExpensesCard({
    super.key,
    required this.transactions,
    required this.onGoToAnalytics,
    required this.onSwapTap,
  });

  @override
  Widget build(BuildContext context) {
    // Automatically take only the 4 most recent transactions
    final recentTx = transactions.take(4).toList();
    
    // Calculate how many empty slots we need to fill to maintain fixed height
    final int emptySlots = 4 - recentTx.length;

    // Build the list of widgets (Transactions + Dynamic Empty State)
    List<Widget> listContent = [];
    
    // 1. Add actual transactions
    for (int i = 0; i < recentTx.length; i++) {
      listContent.add(_buildTransactionRow(context, recentTx[i]));
      
      // Add a gap after each transaction, as long as it's not the absolute last element in the whole card
      if (i < recentTx.length - 1 || emptySlots > 0) {
        listContent.add(const SizedBox(height: 8));
      }
    }

    // 2. Add the dynamic Empty State (if needed)
    if (emptySlots > 0) {
      // Calculate exact pixel height to perfectly fill the missing slots + gaps
      // 72.57 is the exact height of one transaction row. 8.0 is the gap between them.
      double emptyHeight = (72.57 * emptySlots) + (8.0 * (emptySlots - 1));
      
      listContent.add(
        Container(
          height: emptyHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(50.39), // Pill shaped empty state
          ),
          child: emptySlots == 1
              // If only 1 slot is empty, use HORIZONTAL layout
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.leaf(PhosphorIconsStyle.fill),
                      color: AppColors.white500,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "No more expenses",
                      style: GoogleFonts.montserrat(
                        color: AppColors.white600,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              // If 2, 3, or 4 slots are empty, use VERTICAL layout
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.leaf(PhosphorIconsStyle.fill),
                      color: AppColors.white500,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recentTx.isEmpty ? "No expenses found." : "No more expenses.",
                      style: GoogleFonts.montserrat(
                        color: AppColors.white600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return Container(
      // EXACT padding and styling from your updated TodaysTreeCard
      padding: const EdgeInsets.only(top: 18, left: 14, right: 14, bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
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
                    PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.colblack,
                  ),
                ),
              ),
              Text(
                "Today's Expenses",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.colblack,
                ),
              ),
              GestureDetector(
                onTap: onGoToAnalytics,
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
          // LIST + EMPTY STATE (Always fixed height!)
          // ==========================================
          Column(
            children: listContent,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INDIVIDUAL TRANSACTION PILL
  // ==========================================
  Widget _buildTransactionRow(BuildContext context, Transaction tx) {
    return Container(
      // Note: Margin removed from here! It's handled by the SizedBox in the loop for perfect math.
      height: 72.57, // Exact height from your inner boxes
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(50.39), // Exact pill radius
      ),
      child: Row(
        children: [
          // Left Icon in a White Bubble (as seen in Figma)
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // Very soft black
                  blurRadius: 7, 
                  offset: const Offset(0, 3), 
                ),
              ],
            ),
            child: Icon(tx.icon, color: AppColors.colblack, size: 30),
          ),
          const SizedBox(width: 12),

          // Center Text (Name & Category)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tx.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.isManual ? "Cash" : "Bank account",
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),

          // Right Text (Amount & Time)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "- Rs. ${NumberFormat('#,##0').format(tx.amount)}",
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.time.format(context),
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}