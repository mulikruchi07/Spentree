// import 'package:flutter/material.dart';
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import '../../core/app_style.dart';
// import '../../core/user_data.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   // --- STATE ---
//   late DateTime _focusedDate;
//   late DateTime _today;
//   bool _isPickerOpen = false;

//   // Data
//   late int limit;
//   final int todayExpense = 4000;
//   late int pendingLimit;

//   // --- STYLING CONSTANTS ---
//   final double cardRadius = 15.0;
//   final double boxHeight = 76.0; // Reduced height "a bit"

//   @override
//   void initState() {
//     super.initState();
//     _today = DateTime.now();
//     _focusedDate = _today;

//     int? parsedLimit = int.tryParse(
//       UserData.dailyLimit.replaceAll(RegExp(r'[^0-9]'), ''),
//     );
//     limit = parsedLimit ?? 5000;
//     pendingLimit = limit - todayExpense;
//   }

//   // --- LOGIC ---
//   String _getTreeImage() {
//     double percentage = (pendingLimit / limit).clamp(0.0, 1.0);
//     // Using generic assets, ensure these exist in your assets folder
//     if (percentage > 0.8) return "assets/images/tree_1.png";
//     if (percentage > 0.6) return "assets/images/tree_2.png";
//     if (percentage > 0.4) return "assets/images/tree_3.png";
//     return "assets/images/tree_1.png";
//   }

//   void _moveWeek(int days) {
//     setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
//   }

//   List<DateTime> _getWeekDays() {
//     int currentWeekday = _focusedDate.weekday;
//     DateTime startOfWeek = _focusedDate.subtract(
//       Duration(days: currentWeekday - 1),
//     );
//     return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
//   }

//   void _onMonthChanged(int newMonthIndex) {
//     setState(() {
//       int year = _focusedDate.year;
//       int day = _focusedDate.day;
//       int maxDays = DateTime(year, newMonthIndex + 2, 0).day;
//       if (day > maxDays) day = maxDays;
//       _focusedDate = DateTime(year, newMonthIndex + 1, day);
//     });
//   }

//   void _onYearChanged(int newYear) {
//     setState(() {
//       _focusedDate = DateTime(newYear, _focusedDate.month, _focusedDate.day);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgWhite,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Top Margin
//             const SizedBox(height: 70),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // --- 1. Header ---
//                   _buildHeader(),

//                   const SizedBox(height: 20), // "Gap distance... reduce it"
//                   // --- 2. Calendar ---
//                   _buildCalendarBox(),

//                   const SizedBox(
//                     height: 20,
//                   ), // "Gap between calendar and image"
//                   // --- 3. Tree Section ---
//                   _buildTreeSection(),

//                   const SizedBox(
//                     height: 28,
//                   ), // Reduced spacing to bring Balance up
//                   // --- 4. Your Balance ---
//                   _buildSectionHeader("Your Balance", "Change Limit"),
//                   const SizedBox(height: 12),

//                   // Today's Expense
//                   _buildGrayCard(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               "Today's Expense",
//                               // Montserrat, 12, Grey60
//                               style: GoogleFonts.montserrat(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                                 color: AppColors.white600,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               "Rs. ${NumberFormat('#,##0').format(todayExpense)}",
//                               // Montserrat, 22, Bold
//                               style: GoogleFonts.montserrat(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.w700,
//                                 color: AppColors.colblack,
//                               ),
//                             ),
//                           ],
//                         ),
//                         _buildGreenBadge("Great"),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Pending Limit
//                   _buildGrayCard(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           "Pending Limit",
//                           style: GoogleFonts.montserrat(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.white600,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         RichText(
//                           text: TextSpan(
//                             children: [
//                               TextSpan(
//                                 text:
//                                     "Rs. ${NumberFormat('#,##0').format(pendingLimit)} ",
//                                 style: GoogleFonts.montserrat(
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.w700,
//                                   color: AppColors.colblack,
//                                 ),
//                               ),
//                               TextSpan(
//                                 // "Same text size as that of 3000" -> 22 Bold
//                                 text:
//                                     "/ ${NumberFormat('#,##0').format(limit)}",
//                                 style: GoogleFonts.montserrat(
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.w700,
//                                   color: AppColors.colblack,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // --- 5. Transactions ---
//                   _buildSectionHeader("Today's Expenses", "Add expense"),
//                   const SizedBox(height: 16),
//                   _buildTransactionList(),

//                   const SizedBox(height: 12), // Reduced gap
//                   Center(
//                     child: Text(
//                       "See all expenses",
//                       // Poppins
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.white500,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 32), // Reduced gap
//                   // --- 6. Tip of the day ---
//                   Text(
//                     "Tip of the day",
//                     // Poppins, Medium 16
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "Cooking one meal at home can save enough to grow 3 new leaves.",
//                     // Poppins, 21, 808080
//                     style: GoogleFonts.poppins(
//                       fontSize: 21,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.white500,
//                       height: 1.3,
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 20,
//                   ), // "Reduce gap distance between tip and divide line"
//                   Divider(color: AppColors.divider, thickness: 1),

//                   const SizedBox(height: 20),

//                   // --- 7. Footer ---
//                   Center(
//                     child: Text(
//                       "Planted with love in Mumbai, India",
//                       // Poppins, Medium 13
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.white500,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(
//                     height: 120,
//                   ), // "Increase some more space from bottom margin"
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- WIDGETS ---

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Hello",
//               // Montserrat, Medium 16, Black
//               style: GoogleFonts.montserrat(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.colblack,
//               ),
//             ),
//             Text(
//               "${UserData.userName},",
//               // Montserrat, SemiBold 36
//               style: GoogleFonts.montserrat(
//                 fontSize: 36,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.colblack,
//                 height: 1.0,
//               ),
//             ),
//           ],
//         ),
//         // Trophy Icon - No Circle
//         Icon(PhosphorIcons.trophy(), size: 32, color: AppColors.colblack),
//       ],
//     );
//   }

//   Widget _buildCalendarBox() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
//       decoration: BoxDecoration(
//         color: AppColors.inputFill,
//         borderRadius: BorderRadius.circular(cardRadius),
//       ),
//       child: Column(
//         children: [
//           GestureDetector(
//             onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // LEFT ARROW (Restored functionality)
//                 GestureDetector(
//                   onTap: () => _moveWeek(-7),
//                   child: Icon(
//                     Icons.chevron_left,
//                     size: 24,
//                     color: AppColors.colblack,
//                   ),
//                 ),

//                 Row(
//                   children: [
//                     Text(
//                       DateFormat('MMMM').format(_focusedDate),
//                       style: GoogleFonts.montserrat(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.colblack,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       DateFormat('yyyy').format(_focusedDate),
//                       style: GoogleFonts.montserrat(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.colblack,
//                       ),
//                     ),
//                   ],
//                 ),

//                 // RIGHT ARROW (Restored functionality)
//                 GestureDetector(
//                   onTap: () => _moveWeek(7),
//                   child: Icon(
//                     Icons.chevron_right,
//                     size: 24,
//                     color: AppColors.colblack,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           AnimatedCrossFade(
//             duration: const Duration(milliseconds: 300),
//             crossFadeState: _isPickerOpen
//                 ? CrossFadeState.showSecond
//                 : CrossFadeState.showFirst,
//             firstChild: _buildWeekStrip(),
//             secondChild: _buildScrollPickers(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeekStrip() {
//     final weekDays = _getWeekDays();
//     final dayNames = ["M", "T", "W", "T", "F", "S", "S"];

//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: List.generate(7, (index) {
//         DateTime date = weekDays[index];
//         bool isFocused =
//             date.day == _focusedDate.day &&
//             date.month == _focusedDate.month &&
//             date.year == _focusedDate.year;
//         bool isToday =
//             date.day == _today.day &&
//             date.month == _today.month &&
//             date.year == _today.year;

//         return GestureDetector(
//           onTap: () => setState(() => _focusedDate = date),
//           child: Column(
//             children: [
//               Text(
//                 dayNames[index],
//                 style: GoogleFonts.montserrat(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.datenum,
//                 ),
//               ),
//               const SizedBox(height: 12),

//               Container(
//                 width: 36,
//                 height: 48, // Taller for the dot
//                 decoration: BoxDecoration(
//                   color: isFocused
//                       ? AppColors.datebox
//                       : Colors.transparent, // Darker grey selection
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Dot above number
//                     if (isToday)
//                       Container(
//                         width: 5,
//                         height: 5,
//                         margin: const EdgeInsets.only(bottom: 4),
//                         decoration: BoxDecoration(
//                           color: AppColors.datenum,
//                           shape: BoxShape.circle,
//                         ),
//                       )
//                     else
//                       const SizedBox(height: 9),

//                     Text(
//                       "${date.day}",
//                       style: GoogleFonts.montserrat(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.datenum, // Numbers are Grey
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildScrollPickers() {
//     return SizedBox(
//       height: 120,
//       child: Row(
//         children: [
//           Expanded(
//             child: CupertinoPicker(
//               scrollController: FixedExtentScrollController(
//                 initialItem: _focusedDate.month - 1,
//               ),
//               itemExtent: 32,
//               onSelectedItemChanged: _onMonthChanged,
//               children: List.generate(
//                 12,
//                 (index) => Center(
//                   child: Text(
//                     DateFormat('MMMM').format(DateTime(2025, index + 1)),
//                     style: GoogleFonts.montserrat(
//                       fontSize: 16,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: CupertinoPicker(
//               scrollController: FixedExtentScrollController(
//                 initialItem: _focusedDate.year - 2025,
//               ),
//               itemExtent: 32,
//               onSelectedItemChanged: (index) => _onYearChanged(2025 + index),
//               children: List.generate(
//                 11,
//                 (index) => Center(
//                   child: Text(
//                     "${2025 + index}",
//                     style: GoogleFonts.montserrat(
//                       fontSize: 16,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTreeSection() {
//     return Column(
//       children: [
//         SizedBox(
//           height: 250, // Large height
//           width: double.infinity,
//           child: Stack(
//             alignment: Alignment.bottomCenter,
//             clipBehavior: Clip.none,
//             children: [
//               // Green Background
//               Container(
//                 height: 160,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryGreen,
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//               ),
//               // Tree Image - "Cut a little and touch bottom"
//               Positioned(
//                 bottom: -15,
//                 child: Image.asset(
//                   _getTreeImage(),
//                   height: 260, // Maximized size
//                   fit: BoxFit.fitHeight,
//                 ),
//               ),
//             ],
//           ),
//         ),

//         const SizedBox(height: 16), // Same gap as top
//         // Badge
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
//           decoration: BoxDecoration(
//             color: AppColors.primaryGreen,
//             borderRadius: BorderRadius.circular(30),
//           ),
//           child: Text(
//             "Your future self is smiling right now",
//             style: GoogleFonts.montserrat(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//               color: AppColors.colwhite,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, String action) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           // Poppins, 16, SemiBold
//           style: GoogleFonts.poppins(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: AppColors.colblack,
//           ),
//         ),
//         Text(
//           action,
//           // Poppins, 13, Medium
//           style: GoogleFonts.poppins(
//             fontSize: 15,
//             fontWeight: FontWeight.w500,
//             color: AppColors.white500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGrayCard({required Widget child}) {
//     return Container(
//       width: double.infinity,
//       height: boxHeight,
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       decoration: BoxDecoration(
//         color: AppColors.inputFill,
//         borderRadius: BorderRadius.circular(cardRadius),
//       ),
//       child: child,
//     );
//   }

//   Widget _buildGreenBadge(String text) {
//     return Container(
//       // Reduced height to hug text
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
//       decoration: BoxDecoration(
//         color: AppColors.primaryGreen,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.trending_up, color: AppColors.colwhite, size: 14),
//           const SizedBox(width: 4),
//           Text(
//             text,
//             style: GoogleFonts.montserrat(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: AppColors.colwhite,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionList() {
//     // Icons mapped to Figma visual
//     final transactions = [
//       {
//         "icon": PhosphorIcons.bowlSteam(),
//         "name": "McDonald's Ltd.",
//         "amount": "- Rs. 159",
//       }, // Burger
//       {
//         "icon": PhosphorIcons.tShirt(),
//         "name": "Zudio",
//         "amount": "- Rs. 899",
//       }, // Shirt
//       {
//         "icon": PhosphorIcons.simCard(),
//         "name": "Jio",
//         "amount": "- Rs. 349",
//       }, // Mobile
//       {
//         "icon": PhosphorIcons.bowlSteam(),
//         "name": "Dominos Ltd.",
//         "amount": "- Rs. 458",
//       }, // Pizza
//     ];

//     return Column(
//       children: transactions.map((tx) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 15), // Reduced gap
//           width: double.infinity,
//           height: boxHeight,
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           decoration: BoxDecoration(
//             color: AppColors.inputFill,
//             borderRadius: BorderRadius.circular(cardRadius),
//           ),
//           child: Row(
//             children: [
//               // Logo Box
//               Container(
//                 width: 55,
//                 height: 55,
//                 decoration: BoxDecoration(
//                   color: AppColors.iconbox,
//                   borderRadius: BorderRadius.circular(9.63),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.colblack.withOpacity(0.05),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   tx['icon'] as IconData,
//                   color: AppColors.colblack,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       tx['name'] as String,
//                       style: GoogleFonts.montserrat(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.colblack,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       "Bank account",
//                       style: GoogleFonts.montserrat(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.white500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     tx['amount'] as String,
//                     style: GoogleFonts.montserrat(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     DateFormat('E, d MMM yyyy').format(DateTime.now()),
//                     style: GoogleFonts.montserrat(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.white500,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for weekly limit check
import 'package:spentree/core/user_profile.dart';
import '../../core/app_style.dart';
import '../../core/user_data.dart';

import '../../core/transaction_service.dart';
import 'package:spentree/screens/main_wrapper.dart';

// ==========================================
// NEW: Centralized Badge Status Helper
// ==========================================
class BadgeStatus {
  final String label;
  final IconData icon;
  final Color color;

  const BadgeStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}

BadgeStatus getBadgeStatusForPercentage(double percentage) {
  if (percentage >= 0.83) {
    return const BadgeStatus(
      label: "Great",
      icon: Icons.trending_up,
      color: Color(0xFF34C759),
    );
  } else if (percentage >= 0.66) {
    return const BadgeStatus(
      label: "Good",
      icon: Icons.trending_up,
      color: Color(0xFF34C759),
    );
  } else if (percentage >= 0.50) {
    return const BadgeStatus(
      label: "Warning",
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFFCC00),
    );
  } else if (percentage >= 0.33) {
    return const BadgeStatus(
      label: "Careful",
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFFCC00),
    );
  } else if (percentage >= 0.16) {
    return const BadgeStatus(
      label: "Poor",
      icon: Icons.trending_down,
      color: Color(0xFFFF383C),
    );
  } else {
    return const BadgeStatus(
      label: "Empty",
      icon: Icons.trending_down,
      color: Color(0xFFFF383C),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _focusedDate;
  late DateTime _today;
  bool _isPickerOpen = false;
  bool _isExpensesExpanded = false; // NEW: tracks expand/collapse state

  int limit = 1000;
  double pendingLimit = 0.0;

  final double cardRadius = 15.0;
  final double boxHeight = 76.0;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDate = _today;
    _loadLimit();
    TransactionService().syncWidget(); // NEW
    TransactionService().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    TransactionService().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // --- LIMIT MANAGEMENT ---
  Future<void> _loadLimit() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedLimit = prefs.getInt('daily_expense_limit');

    setState(() {
      if (savedLimit != null) {
        limit = savedLimit;
      } else {
        int? parsedLimit = int.tryParse(
          UserData.dailyLimit.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        limit = parsedLimit ?? 5000;
      }
    });
  }

  void _handleChangeLimit() async {
    final newLimit = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _ChangeLimitPopup(),
    );

    if (newLimit != null) {
      setState(() {
        limit = newLimit;
      });
    }
  }

  String _getTreeImage() {
    double percentage = limit > 0
        ? (pendingLimit / limit).clamp(0.0, 1.0)
        : 0.0;

    if (percentage >= 0.83) return "assets/images/dashboard/tree_1.png";
    if (percentage >= 0.66) return "assets/images/dashboard/tree_2.png";
    if (percentage >= 0.50) return "assets/images/dashboard/tree_3.png";
    if (percentage >= 0.33) return "assets/images/dashboard/tree_4.png";
    if (percentage >= 0.16) return "assets/images/dashboard/tree_5.png";

    return "assets/images/dashboard/tree_6.png";
  }

  void _moveWeek(int days) {
    setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
  }

  void _onMonthChanged(int newMonthIndex) {
    setState(() {
      int year = _focusedDate.year;
      int day = _focusedDate.day;
      int maxDays = DateTime(year, newMonthIndex + 2, 0).day;
      if (day > maxDays) day = maxDays;
      _focusedDate = DateTime(year, newMonthIndex + 1, day);
    });
  }

  void _onYearChanged(int newYear) {
    setState(
      () => _focusedDate = DateTime(
        newYear,
        _focusedDate.month,
        _focusedDate.day,
      ),
    );
  }

  List<DateTime> _getWeekDays() {
    int currentWeekday = _focusedDate.weekday;
    DateTime startOfWeek = _focusedDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        bool isViewingToday = DateUtils.isSameDay(_focusedDate, _today);

        final dailyTx = TransactionService().getTransactionsForDay(
          _focusedDate,
        );
        double selectedDayExpense = dailyTx.fold(
          0,
          (sum, item) => sum + item.amount,
        );
        pendingLimit = (limit - selectedDayExpense).clamp(
          0.0,
          limit.toDouble(),
        );

        // NEW: Compute current badge status synced with tree state
        double percentage = limit > 0
            ? (pendingLimit / limit).clamp(0.0, 1.0)
            : 0.0;
        final BadgeStatus currentBadge = getBadgeStatusForPercentage(
          percentage,
        );

        // NEW: Determine visible transactions based on expand state
        final List<Transaction> visibleTx = _isExpensesExpanded
            ? dailyTx
            : dailyTx.take(4).toList();
        final bool hasMoreThanFour = dailyTx.length > 4;

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: TransactionService().isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 70),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildCalendarBox(),
                            const SizedBox(height: 20),

                            _buildTreeSection(),

                            const SizedBox(height: 28),
                            // CONNECTED THE BUTTON HERE
                            _buildSectionHeader(
                              "Your Balance",
                              "Change Limit",
                              onTapAction: _handleChangeLimit,
                            ),
                            const SizedBox(height: 12),

                            _buildGrayCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isViewingToday
                                            ? "Today's Expense"
                                            : "Expense on ${DateFormat('d MMM').format(_focusedDate)}",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Rs. ${NumberFormat('#,##0').format(selectedDayExpense)}",
                                        style: GoogleFonts.montserrat(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.colblack,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // CHANGED: Use synchronized 6-state badge
                                  _buildStatusBadge(currentBadge),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildGrayCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Pending Limit",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white600,
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
                                          text:
                                              "/ ${NumberFormat('#,##0').format(limit)}",
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

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isViewingToday
                                      ? "Today's Expenses"
                                      : "Expenses",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MainWrapper(initialIndex: 1),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Add expense",
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (dailyTx.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(
                                    cardRadius,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      PhosphorIcons.leaf,
                                      color: AppColors.white500,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "No expenses found for this day.",
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.white600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              // CHANGED: Expandable transaction list with smooth animation
                              Column(
                                children: [
                                  // Always-visible first 4 transactions
                                  Column(
                                    children: dailyTx
                                        .take(4)
                                        .map((tx) => _buildTransactionCard(tx))
                                        .toList(),
                                  ),
                                  // Animated reveal of remaining transactions
                                  if (hasMoreThanFour)
                                    ClipRect(
                                      child: AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 350,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                        alignment: Alignment.topCenter,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, animation) {
                                                final slide =
                                                    Tween<Offset>(
                                                      begin: const Offset(
                                                        0,
                                                        -0.05,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.easeOut,
                                                      ),
                                                    );
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: slide,
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          child: _isExpensesExpanded
                                              ? Column(
                                                  key: const ValueKey(
                                                    'expanded',
                                                  ),
                                                  children: dailyTx
                                                      .skip(4)
                                                      .map(
                                                        (tx) =>
                                                            _buildTransactionCard(
                                                              tx,
                                                            ),
                                                      )
                                                      .toList(),
                                                )
                                              : const SizedBox(
                                                  key: ValueKey('collapsed'),
                                                  width: double.infinity,
                                                  height: 0,
                                                ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                            const SizedBox(height: 12),
                            // CHANGED: "See all expenses" / "Show less" toggle
                            if (hasMoreThanFour)
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpensesExpanded =
                                          !_isExpensesExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isExpensesExpanded
                                        ? "Show less"
                                        : "See all expenses",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white500,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 32),
                            Text(
                              "Tip of the day",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.colblack,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Cooking one meal at home can save enough to grow 3 new leaves.",
                              style: GoogleFonts.poppins(
                                fontSize: 21,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(color: AppColors.divider, thickness: 1),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                "Planted with love in Mumbai, India",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // --- SUB WIDGETS ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.colblack,
              ),
            ),
            ValueListenableBuilder<UserProfile>(
              valueListenable: userProfileNotifier,
              builder: (context, profile, _) => Text(
                "${profile.name},",
                style: GoogleFonts.montserrat(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
        Icon(PhosphorIcons.trophy, size: 32, color: AppColors.colblack),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _moveWeek(-7),
                  child: Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _moveWeek(7),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPickerOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildWeekStrip(),
            secondChild: _buildScrollPickers(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final weekDays = _getWeekDays();
    final dayNames = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        DateTime date = weekDays[index];
        bool isFocused = DateUtils.isSameDay(date, _focusedDate);
        bool isToday = DateUtils.isSameDay(date, _today);

        return GestureDetector(
          onTap: () => setState(() => _focusedDate = date),
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.datenum,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 48,
                decoration: BoxDecoration(
                  color: isFocused ? AppColors.datebox : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.colblack,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 9),
                    Text(
                      "${date.day}",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.datenum,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildScrollPickers() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _focusedDate.month - 1,
              ),
              itemExtent: 32,
              onSelectedItemChanged: _onMonthChanged,
              children: List.generate(
                12,
                (index) => Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, index + 1)),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _focusedDate.year - 2025,
              ),
              itemExtent: 32,
              onSelectedItemChanged: (index) => _onYearChanged(2025 + index),
              children: List.generate(
                11,
                (index) => Center(
                  child: Text(
                    "${2025 + index}",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeSection() {
    double percentage = limit > 0
        ? (pendingLimit / limit).clamp(0.0, 1.0)
        : 0.0;

    String imagePath;
    String message;
    Color badgeColor;
    Color textColor = AppColors.colwhite;

    if (percentage >= 0.83) {
      imagePath = "assets/images/dashboard/tree_1.png";
      message = "Your future self is smiling right now";
      badgeColor = const Color(0xFF34C759);
    } else if (percentage >= 0.66) {
      imagePath = "assets/images/dashboard/tree_2.png";
      message = "Careful… you’re starting to slip";
      badgeColor = const Color(0xFF34C759);
    } else if (percentage >= 0.50) {
      imagePath = "assets/images/dashboard/tree_3.png";
      message = "That impulse just cost you growth";
      badgeColor = const Color(0xFFFFCC00);
      textColor = AppColors.colwhite;
    } else if (percentage >= 0.33) {
      imagePath = "assets/images/dashboard/tree_4.png";
      message = "A small reset can bring this back";
      badgeColor = const Color(0xFFFFCC00);
      textColor = AppColors.colwhite;
    } else if (percentage >= 0.16) {
      imagePath = "assets/images/dashboard/tree_5.png";
      message = "Ahh, Better luck next time";
      badgeColor = const Color(0xFFFF383C);
    } else {
      imagePath = "assets/images/dashboard/tree_6.png";
      message = "Its okay, every forest grows again";
      badgeColor = const Color(0xFFFF383C);
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onTapAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colblack,
          ),
        ),
        GestureDetector(
          onTap: onTapAction,
          child: Text(
            action,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.white500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrayCard({required Widget child}) {
    return Container(
      width: double.infinity,
      height: boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: child,
    );
  }

  // NEW: Generic synchronized badge builder (replaces _buildGreenBadge/_buildRedBadge usage in expense card)
  Widget _buildStatusBadge(BadgeStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: AppColors.colwhite, size: 14),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.colwhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity,
      height: boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppColors.iconbox,
              borderRadius: BorderRadius.circular(9.63),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colblack.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(tx.icon, color: AppColors.colblack, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tx.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "- Rs. ${NumberFormat('#,##0').format(tx.amount)}",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.time.format(context),
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// NEW: Change Limit Popup Widget
// ==========================================
class _ChangeLimitPopup extends StatefulWidget {
  const _ChangeLimitPopup();

  @override
  State<_ChangeLimitPopup> createState() => _ChangeLimitPopupState();
}

class _ChangeLimitPopupState extends State<_ChangeLimitPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _limitCtrl = TextEditingController();
  bool _isChecked = false;
  String? _errorMsg;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerError(String msg) {
    setState(() => _errorMsg = msg);
    _shakeController.forward(from: 0.0);
  }

  Future<void> _validateAndSubmit() async {
    setState(() => _errorMsg = null);

    final val = int.tryParse(_limitCtrl.text) ?? 0;

    if (val <= 0) {
      _triggerError("Please enter a valid amount");
      return;
    }
    if (val > 100000) {
      _triggerError("Limit cannot exceed Rs. 1,00,000");
      return;
    }
    if (!_isChecked) {
      _triggerError("Please agree to the condition");
      return;
    }

    // --- CHECK WEEKLY LIMIT ENFORCEMENT ---
    final prefs = await SharedPreferences.getInstance();
    final lastChangeStr = prefs.getString('last_limit_change');

    if (lastChangeStr != null) {
      final lastChangeDate = DateTime.parse(lastChangeStr);
      final difference = DateTime.now().difference(lastChangeDate).inDays;

      if (difference < 7) {
        _triggerError("You can only change your limit once a week.");
        return;
      }
    }

    // --- SUCCESS: SAVE TO CACHE AND RETURN ---
    await prefs.setInt('daily_expense_limit', val);
    await prefs.setString(
      'last_limit_change',
      DateTime.now().toIso8601String(),
    );

    await TransactionService().syncWidget();

    if (mounted) {
      Navigator.pop(context, val); // Return the new value to update the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offsetAnimation.value, 0),
          child: child,
        );
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Change limit",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // To show current limit, we pull it from UserData or state
                  Text(
                    "Enter your new daily limit",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          _errorMsg != null &&
                              (_errorMsg!.contains("valid") ||
                                  _errorMsg!.contains("exceed") ||
                                  _errorMsg!.contains("once"))
                          ? Border.all(
                              color: AppColors.destructiveRed,
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _limitCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: AppColors.colblack,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter new limit",
                              hintStyle: GoogleFonts.montserrat(
                                color: AppColors.grey600,
                              ),
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              if (_errorMsg != null)
                                setState(() => _errorMsg = null);
                            },
                          ),
                        ),
                        Text(
                          "INR",
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isChecked = !_isChecked;
                        if (_isChecked) _errorMsg = null;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: _isChecked
                                ? AppColors.primaryGreen
                                : AppColors.inputFill,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                _errorMsg != null &&
                                    _errorMsg!.contains("agree") &&
                                    !_isChecked
                                ? Border.all(
                                    color: AppColors.destructiveRed,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: _isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Limit can be changed only once a week",
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: AppColors.white500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.poppins(
                          color: AppColors.destructiveRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Change",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colwhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
