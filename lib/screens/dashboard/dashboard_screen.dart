import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_style.dart';
import '../../core/user_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATE ---
  late DateTime _focusedDate;
  late DateTime _today;
  bool _isPickerOpen = false;

  // Data
  late int limit;
  final int todayExpense = 4000;
  late int pendingLimit;

  // --- STYLING CONSTANTS ---
  final double cardRadius = 15.0;
  final double boxHeight = 76.0; // Reduced height "a bit"

  // Colors
  final Color colBlack = const Color(0xFF000000);
  final Color colGrey80 = const Color(0xFF808080); // Tip, Divider, Week chars
  final Color colGrey60 = const Color(0xFF606060); // Labels
  final Color colGreen = const Color(0xFF34C759);
  final Color colBoxBg = const Color(0xFFF4F4F4);

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDate = _today;

    int? parsedLimit = int.tryParse(
      UserData.dailyLimit.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    limit = parsedLimit ?? 5000;
    pendingLimit = limit - todayExpense;
  }

  // --- LOGIC ---
  String _getTreeImage() {
    double percentage = (pendingLimit / limit).clamp(0.0, 1.0);
    // Using generic assets, ensure these exist in your assets folder
    if (percentage > 0.8) return "assets/images/tree_1.png";
    if (percentage > 0.6) return "assets/images/tree_2.png";
    if (percentage > 0.4) return "assets/images/tree_3.png";
    return "assets/images/tree_1.png";
  }

  void _moveWeek(int days) {
    setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
  }

  List<DateTime> _getWeekDays() {
    int currentWeekday = _focusedDate.weekday;
    DateTime startOfWeek = _focusedDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
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
    setState(() {
      _focusedDate = DateTime(newYear, _focusedDate.month, _focusedDate.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Margin
            const SizedBox(height: 70),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Header ---
                  _buildHeader(),

                  const SizedBox(height: 20), // "Gap distance... reduce it"
                  // --- 2. Calendar ---
                  _buildCalendarBox(),

                  const SizedBox(
                    height: 20,
                  ), // "Gap between calendar and image"
                  // --- 3. Tree Section ---
                  _buildTreeSection(),

                  const SizedBox(
                    height: 28,
                  ), // Reduced spacing to bring Balance up
                  // --- 4. Your Balance ---
                  _buildSectionHeader("Your Balance", "Change Limit"),
                  const SizedBox(height: 12),

                  // Today's Expense
                  _buildGrayCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Today's Expense",
                              // Montserrat, 12, Grey60
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colGrey60,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Rs. ${NumberFormat('#,##0').format(todayExpense)}",
                              // Montserrat, 22, Bold
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colBlack,
                              ),
                            ),
                          ],
                        ),
                        _buildGreenBadge("Great"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pending Limit
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
                            color: colGrey60,
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
                                  color: colBlack,
                                ),
                              ),
                              TextSpan(
                                // "Same text size as that of 3000" -> 22 Bold
                                text:
                                    "/ ${NumberFormat('#,##0').format(limit)}",
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 5. Transactions ---
                  _buildSectionHeader("Today's Expenses", "Add expense"),
                  const SizedBox(height: 16),
                  _buildTransactionList(),

                  const SizedBox(height: 12), // Reduced gap
                  Center(
                    child: Text(
                      "See all expenses",
                      // Poppins
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colGrey80,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32), // Reduced gap
                  // --- 6. Tip of the day ---
                  Text(
                    "Tip of the day",
                    // Poppins, Medium 16
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cooking one meal at home can save enough to grow 3 new leaves.",
                    // Poppins, 21, 808080
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                      color: colGrey80,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ), // "Reduce gap distance between tip and divide line"
                  Divider(color: colBlack, thickness: 0.5),

                  const SizedBox(height: 20),

                  // --- 7. Footer ---
                  Center(
                    child: Text(
                      "Planted with love in Mumbai, India",
                      // Poppins, Medium 13
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colGrey80,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 120,
                  ), // "Increase some more space from bottom margin"
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello",
              // Montserrat, Medium 16, Black
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colBlack,
              ),
            ),
            Text(
              "${UserData.userName},",
              // Montserrat, SemiBold 36
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: colBlack,
                height: 1.0,
              ),
            ),
          ],
        ),
        // Trophy Icon - No Circle
        Icon(Icons.emoji_events_outlined, size: 32, color: colBlack),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: colBoxBg,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT ARROW (Restored functionality)
                GestureDetector(
                  onTap: () => _moveWeek(-7),
                  child: Icon(Icons.chevron_left, size: 24, color: colBlack),
                ),

                Row(
                  children: [
                    Text(
                      DateFormat('MMMM').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colBlack,
                      ),
                    ),
                  ],
                ),

                // RIGHT ARROW (Restored functionality)
                GestureDetector(
                  onTap: () => _moveWeek(7),
                  child: Icon(Icons.chevron_right, size: 24, color: colBlack),
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
        bool isFocused =
            date.day == _focusedDate.day &&
            date.month == _focusedDate.month &&
            date.year == _focusedDate.year;
        bool isToday =
            date.day == _today.day &&
            date.month == _today.month &&
            date.year == _today.year;

        return GestureDetector(
          onTap: () => setState(() => _focusedDate = date),
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colGrey80,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: 36,
                height: 48, // Taller for the dot
                decoration: BoxDecoration(
                  color: isFocused
                      ? const Color(0xFFE0E0E0)
                      : Colors.transparent, // Darker grey selection
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dot above number
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: colBlack,
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
                        color: colGrey80, // Numbers are Grey
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
                    style: GoogleFonts.montserrat(fontSize: 16),
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
                    style: GoogleFonts.montserrat(fontSize: 16),
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
    return Column(
      children: [
        SizedBox(
          height: 250, // Large height
          width: double.infinity,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Green Background
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colGreen,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              // Tree Image - "Cut a little and touch bottom"
              Positioned(
                bottom: -15,
                child: Image.asset(
                  _getTreeImage(),
                  height: 260, // Maximized size
                  fit: BoxFit.fitHeight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16), // Same gap as top
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: colGreen,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            "Your future self is smiling right now",
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          // Poppins, 16, SemiBold
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colBlack,
          ),
        ),
        Text(
          action,
          // Poppins, 13, Medium
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colGrey80,
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
        color: colBoxBg,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: child,
    );
  }

  Widget _buildGreenBadge(String text) {
    return Container(
      // Reduced height to hug text
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: colGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // Icons mapped to Figma visual
    final transactions = [
      {
        "icon": Icons.fastfood,
        "name": "McDonald's Ltd.",
        "amount": "- Rs. 159",
      }, // Burger
      {
        "icon": Icons.checkroom,
        "name": "Zudio",
        "amount": "- Rs. 899",
      }, // Shirt
      {
        "icon": Icons.smartphone,
        "name": "Jio Recharge",
        "amount": "- Rs. 349",
      }, // Mobile
      {
        "icon": Icons.local_pizza,
        "name": "Dominos Ltd.",
        "amount": "- Rs. 458",
      }, // Pizza
    ];

    return Column(
      children: transactions.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15), // Reduced gap
          width: double.infinity,
          height: boxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colBoxBg,
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          child: Row(
            children: [
              // Logo Box
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9.63),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(tx['icon'] as IconData, color: colBlack, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tx['name'] as String,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Bank account",
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colGrey80,
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
                    tx['amount'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('E, d MMM yyyy').format(DateTime.now()),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colGrey80,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
