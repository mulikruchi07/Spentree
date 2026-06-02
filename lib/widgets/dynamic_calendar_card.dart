import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/app_style.dart'; // Make sure this path is correct
import '../core/transaction_service.dart'; // Connects to your actual transactions

class DynamicCalendarCard extends StatefulWidget {
  final int dailyLimit;
  final VoidCallback onSwapTap; // Callback to swap to the TodaysExpensesCard

  const DynamicCalendarCard({
    super.key,
    required this.dailyLimit,
    required this.onSwapTap,
  });

  @override
  State<DynamicCalendarCard> createState() => _DynamicCalendarCardState();
}

class _DynamicCalendarCardState extends State<DynamicCalendarCard> {
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    // Strictly locks to the current month
    _viewDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // Listen to changes in transactions so the calendar updates in REAL-TIME
    TransactionService().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // Remove the listener when the widget is destroyed
    TransactionService().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    // Re-build the calendar whenever a transaction is added/edited
    if (mounted) setState(() {});
  }

  // ==========================================
  // REAL-TIME DATA LOGIC
  // ==========================================
  Color _getColorForDate(DateTime date) {
    // 1. Don't color future dates (they haven't happened yet)
    if (date.isAfter(DateTime.now())) return Colors.transparent;

    // 2. Fetch the actual transactions for this specific day
    final dailyTx = TransactionService().getTransactionsForDay(date);

    // 3. If nothing was spent, leave the background transparent
    if (dailyTx.isEmpty) return Colors.transparent;

    // 4. Calculate total spent for that day
    double totalExpense = dailyTx.fold(0, (sum, item) => sum + item.amount);

    // 5. Calculate the health percentage
    final double pendingLimit = (widget.dailyLimit - totalExpense).clamp(
      0.0,
      widget.dailyLimit.toDouble(),
    );
    final double percentage = widget.dailyLimit > 0
        ? (pendingLimit / widget.dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    // 6. Return the correct status color
    if (percentage >= 0.66) return const Color(0xFF34C759); // Green (Great)
    if (percentage >= 0.33) return const Color(0xFFFFCC00); // Yellow (Warning)
    return const Color(0xFFFF383C); // Red (Poor)
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _viewDate.year,
      _viewDate.month,
    );
    // Determine which day of the week the 1st falls on (1 = Mon, 7 = Sun)
    final firstDayOffset =
        DateTime(_viewDate.year, _viewDate.month, 1).weekday - 1;

    return Container(
      // Padding exactly matches the other cards
      padding: const EdgeInsets.only(top: 18, left: 14, right: 14, bottom: 0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // TOP ROW: SWAP WIDGET BUTTON
          // ==========================================
          GestureDetector(
            onTap: widget.onSwapTap, // Triggers the swap!
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

          const SizedBox(height: 20),

          // ==========================================
          // MONTH & YEAR TITLE
          // ==========================================
          Padding(
            // Padding aligned exactly with the left edge of the grid
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              DateFormat('MMMM yyyy').format(_viewDate),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ==========================================
          // CALENDAR GRID (Tightened Spacing)
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day of Week Headers (Mo, Tu, We...)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map((e) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          e,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colblack,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10), // Reduced gap below headers
                // The Actual Dates Grid
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 42, // Max 6 weeks
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 10, // TIGHTENED horizontal gap
                    mainAxisSpacing: 10, // TIGHTENED vertical gap
                  ),
                  itemBuilder: (context, i) {
                    // Empty space for offset
                    if (i < firstDayOffset ||
                        i >= daysInMonth + firstDayOffset) {
                      return const SizedBox();
                    }

                    // Calculate date
                    final int dayNumber = i - firstDayOffset + 1;
                    final DateTime cellDate = DateTime(
                      _viewDate.year,
                      _viewDate.month,
                      dayNumber,
                    );

                    // Fetch color from Real-Time Logic
                    final Color dayColor = _getColorForDate(cellDate);
                    final bool hasColor = dayColor != Colors.transparent;

                    return Container(
                      decoration: BoxDecoration(
                        color: dayColor,
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Rounded pill corners
                      ),
                      child: Center(
                        child: Text(
                          "$dayNumber",
                          style: GoogleFonts.montserrat(
                            // Text turns white on colored backgrounds
                            color: hasColor
                                ? Colors.white
                                : const Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
