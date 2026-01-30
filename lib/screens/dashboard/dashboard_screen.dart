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
  // --- STATE VARIABLES ---
  late DateTime _focusedDate;
  late DateTime _today;
  bool _isPickerOpen = false;

  // Data
  late int limit;
  final int todayExpense = 2000;
  late int pendingLimit;

  // --- DIMENSIONS & COLORS ---
  final double boxHeight = 85.0;
  final double commonRadius = 15.0; // "Keep corner radius of all as 15"

  final Color colBlack = const Color(0xFF000000);
  final Color col606060 = const Color(0xFF606060);
  final Color col808080 = const Color(0xFF808080);
  final Color colBoxBg = const Color(0xFFF1F1F1);

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

  // --- LOGIC: Tree Image Selector ---
  String _getTreeImage() {
    double percentage = (pendingLimit / limit).clamp(0.0, 1.0);
    if (percentage > 0.8) return "assets/images/tree_1.png";
    if (percentage > 0.6) return "assets/images/tree_2.png";
    if (percentage > 0.4) return "assets/images/tree_3.png";
    return "assets/images/tree_1.png";
  }

  // --- LOGIC: Calendar Navigation ---
  void _moveWeek(int days) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: days));
    });
  }

  List<DateTime> _getWeekDays() {
    // Find Monday of the currently focused week
    // weekday 1 = Mon ... 7 = Sun
    int currentWeekday = _focusedDate.weekday;
    DateTime startOfWeek = _focusedDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // Scroll Picker Logic
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
            // --- TOP MARGIN ---
            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Header ---
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // --- 2. Functional Calendar ---
                  _buildCalendarBox(),

                  const SizedBox(height: 24),

                  // --- 3. Tree Section (Big BG, Big Image) ---
                  _buildTreeSection(),

                  const SizedBox(height: 24),

                  // --- 4. Your Balance ---
                  _buildSectionHeader("Your Balance", "Change Limit"),
                  const SizedBox(height: 12), // Reduced gap for compactness
                  // Today's Expense Card
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
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: col606060,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${NumberFormat('#,##0').format(todayExpense)}",
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
                  const SizedBox(height: 12), // Reduced gap
                  // Pending Limit Card
                  _buildGrayCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pending Limit",
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: col606060,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                text:
                                    "/ ${NumberFormat('#,##0').format(limit)}",
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
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
                  // This heading should now be visible without scrolling on most screens
                  _buildSectionHeader("Today's Expenses", "Add expense"),
                  const SizedBox(height: 16),
                  _buildTransactionList(),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "See all expenses",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: col808080,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- 6. Tip of the day ---
                  Text(
                    "Tip of the day",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Cooking one meal at home can save enough to grow 3 new leaves.",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: col808080,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 7. Footer ---
                  Divider(color: col808080, thickness: 0.5),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "Planted with love in Mumbai, India",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: col808080,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

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
                fontWeight: FontWeight.w600,
                color: colBlack,
              ),
            ),
            Text(
              "${UserData.userName},",
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: colBlack,
                height: 1.0,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colBlack, width: 1.5),
          ),
          child: Icon(Icons.park_outlined, size: 26, color: colBlack),
        ),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colBoxBg,
        borderRadius: BorderRadius.circular(commonRadius), // Radius 15
      ),
      child: Column(
        children: [
          // Header: Arrows & Date
          GestureDetector(
            onTap: () {
              setState(() {
                _isPickerOpen = !_isPickerOpen;
              });
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Spaced to edges
              children: [
                // PREV ARROW
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.chevron_left, size: 24, color: col808080),
                  onPressed: () => _moveWeek(-7), // Move back 7 days
                ),

                // Date Text
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM').format(_focusedDate),
                      // "Decrease the weight of month year text"
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500, // Medium
                        color: colBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w500, // Medium
                        color: colBlack,
                      ),
                    ),
                  ],
                ),

                // NEXT ARROW
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.chevron_right, size: 24, color: col808080),
                  onPressed: () => _moveWeek(7), // Move forward 7 days
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content
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
          onTap: () {
            setState(() {
              _focusedDate = date;
            });
          },
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: col606060,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: 38,
                height: 46,
                decoration: BoxDecoration(
                  color: isFocused
                      ? const Color(0xFFD1D1D6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dot above number if TODAY
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: colBlack,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 7),

                    Text(
                      "${date.day}",
                      // "Make the date number grey same as week character"
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: isFocused
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: col606060, // Grey
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
              children: List.generate(12, (index) {
                return Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, index + 1)),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colBlack,
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _focusedDate.year - 2025,
              ),
              itemExtent: 32,
              onSelectedItemChanged: (index) => _onYearChanged(2025 + index),
              children: List.generate(11, (index) {
                return Center(
                  child: Text(
                    "${2025 + index}",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colBlack,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeSection() {
    return Center(
      child: Column(
        children: [
          // "Increase the tress image size such that it fill the whole space"
          // "Image bottom must stick the background bottom"
          SizedBox(
            height: 250, // Increase overall height area
            width: double.infinity,
            child: Stack(
              alignment: Alignment.bottomCenter, // Key: Sticks items to bottom
              children: [
                // "Background must be big in height"
                Container(
                  height: 140, // Increased BG height
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 0,
                  ), // Full width in stack
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ), // More curved
                  ),
                ),

                // Tree Image
                // Maximize size to fill space
                Positioned(
                  bottom: 25, // Slight offset so it sits IN the box, not below
                  child: Image.asset(
                    _getTreeImage(),
                    height: 220, // Massive Tree
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Your future self is smiling right now",
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colBlack,
          ),
        ),
        Text(
          action,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: col808080,
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
        borderRadius: BorderRadius.circular(commonRadius), // Radius 15
      ),
      child: child,
    );
  }

  Widget _buildGreenBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      {
        "icon": Icons.fastfood_outlined,
        "name": "McDonald's Ltd.",
        "amount": "- Rs. 159",
      },
      {
        "icon": Icons.shopping_bag_outlined,
        "name": "Zudio",
        "amount": "- Rs. 899",
      },
      {
        "icon": Icons.phone_android_outlined,
        "name": "Jio Recharge",
        "amount": "- Rs. 349",
      },
      {
        "icon": Icons.local_pizza_outlined,
        "name": "Dominos Ltd.",
        "amount": "- Rs. 458",
      },
    ];

    return Column(
      children: transactions.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          width: double.infinity,
          height: boxHeight, // Same fixed height
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colBoxBg,
            borderRadius: BorderRadius.circular(commonRadius), // Radius 15
          ),
          child: Row(
            children: [
              // "Increase the logo size in transaction list"
              Container(
                width: 52, // Increased from 46
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15), // Matching radius
                ),
                child: Icon(
                  tx['icon'] as IconData,
                  color: colBlack,
                  size: 26,
                ), // Bigger icon
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Bank account",
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: col606060,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('E, d MMM yyyy').format(DateTime.now()),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: col606060,
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
