import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ForestScreen extends StatefulWidget {
  const ForestScreen({super.key});

  @override
  State<ForestScreen> createState() => _ForestScreenState();
}

class _ForestScreenState extends State<ForestScreen> {
  // --- STATE ---
  late DateTime _focusedDate;
  bool _isPickerOpen = false;

  // --- UI CONSTANTS ---
  final double cardRadius = 15.0;
  final double boxHeight = 76.0;
  final Color colBlack = const Color(0xFF000000);
  final Color colGrey80 = const Color(0xFF808080);
  final Color colGrey60 = const Color(0xFF606060);
  final Color colGreen = const Color(0xFF34C759);
  final Color colBoxBg = const Color(0xFFF1F1F1);

  // Dynamic Palette (Darkest to Lightest)
  final List<Color> _greenPalette = [
    const Color(0xFF1B5E20), // Darkest
    const Color(0xFF2E7D32),
    const Color(0xFF43A047),
    const Color(0xFF66BB6A),
    const Color(0xFF81C784),
    const Color(0xFFA5D6A7), // Lightest
  ];

  // Data
  late List<Map<String, dynamic>> _sortedCategories;

  final List<Map<String, dynamic>> _rawCategoryData = [
    {"name": "Food & Beverages", "amount": 3000},
    {"name": "Shopping", "amount": 15000},
    {"name": "To People", "amount": 12000},
    {"name": "Fuel", "amount": 7000},
    {"name": "Recharge", "amount": 6000},
    {"name": "Other", "amount": 2000},
  ];

  // Tree Data for the list
  final List<Map<String, String>> _treeTypes = [
    {"name": "Dense Forest", "image": "dense_forest.png", "count": "02"},
    {"name": "Grand Forest", "image": "grand_forest.png", "count": "05"},
    {"name": "Forest", "image": "forest.png", "count": "08"},
    {"name": "String Tree", "image": "string_tree.png", "count": "10"},
    {"name": "Drying Tree", "image": "drying_tree.png", "count": "04"},
    {"name": "Dry Tree", "image": "dry_tree.png", "count": "02"},
  ];

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _processCategoryData();
  }

  void _processCategoryData() {
    // 1. Sort by amount descending (High to Low)
    _sortedCategories = List.from(_rawCategoryData);
    _sortedCategories.sort(
      (a, b) => (b['amount'] as int).compareTo(a['amount'] as int),
    );

    // 2. Assign colors from palette based on index
    for (int i = 0; i < _sortedCategories.length; i++) {
      _sortedCategories[i]['color'] = _greenPalette[i % _greenPalette.length];
    }
  }

  // --- LOGIC ---
  void _onMonthChanged(int index) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, index + 1, 1);
    });
  }

  void _onYearChanged(int index) {
    setState(() {
      _focusedDate = DateTime(2025 + index, _focusedDate.month, 1);
    });
  }

  void _moveMonth(int months) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + months,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // 2. Monthly Calendar Box (Compact)
                  _buildMonthlyCalendar(),
                  const SizedBox(height: 24),

                  // 3. Forest Visualization & Tree List
                  _buildForestSection(),
                  const SizedBox(height: 32),

                  // 4. Monthly Summary
                  Text(
                    "April's Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    "April's Expense",
                    "Rs. 75,000",
                    isExpense: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    "Average Daily Expense",
                    "Rs. 3,500 / 5,000",
                  ),

                  const SizedBox(height: 32),

                  // 5. Category Spends
                  Text(
                    "Category Spends",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMultiSegmentProgressBar(),
                  const SizedBox(height: 24),
                  _buildCategoryList(),

                  const SizedBox(height: 32),

                  // 6. Top Expenses
                  Text(
                    "Top Expenses",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopExpensesList(),

                  const SizedBox(height: 48),

                  // 7. Tip & Footer
                  _buildTipSection(),
                  const SizedBox(height: 20),
                  Divider(color: colBlack, thickness: 0.5),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Planted with love in Mumbai, India",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colGrey80,
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
              "My",
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "Forest",
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ],
        ),
        const Icon(Icons.emoji_events_outlined, size: 32),
      ],
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      // Compact height
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                GestureDetector(
                  onTap: () => _moveMonth(-1),
                  child: const Icon(Icons.chevron_left, size: 24),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDate),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () => _moveMonth(1),
                  child: const Icon(Icons.chevron_right, size: 24),
                ),
              ],
            ),
          ),
          // Smooth Expansion
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPickerOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildScrollPickers(),
          ),
        ],
      ),
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
                (i) => Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, i + 1)),
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
              onSelectedItemChanged: _onYearChanged,
              children: List.generate(
                10,
                (i) => Center(
                  child: Text(
                    "${2025 + i}",
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

  Widget _buildForestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Left Align Title
      children: [
        Text(
          "April's Forest",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Isometric Forest Image
        Center(
          child: Image.asset(
            "assets/images/full_forest_iso.png",
            height: 220,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 20),

        // Green Badge Centered
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              color: colGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "April was greener than March",
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Tree Stats
        Text(
          "Total trees planted : 31",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Tree List Loop
        Column(
          children: _treeTypes
              .map(
                (tree) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      // Tree Icon
                      Image.asset(
                        "assets/images/forest/${tree['image']}",
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tree['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        "- ${tree['count']}",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value, {
    bool isExpense = false,
  }) {
    return Container(
      width: double.infinity,
      height: boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colBoxBg,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colGrey60,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colBlack,
                ),
              ),
            ],
          ),
          if (isExpense)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Great",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiSegmentProgressBar() {
    double total = _sortedCategories.fold(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );
    double cumulativeSum = 0;
    List<Widget> barLayers = [];
    for (int i = 0; i < _sortedCategories.length; i++) {
      var cat = _sortedCategories[i];
      cumulativeSum += cat['amount'] as int;
      double percentage = cumulativeSum / total;

      Widget barLayer = FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: cat['color'],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
        ),
      );

      barLayers.insert(0, barLayer);
    }

    // 5. Wrap the stack in ClipRRect for the main outer curve
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // The main outer curve
      child: Container(
        height: 24, // Fixed height for the progress bar
        width: double.infinity,
        decoration: BoxDecoration(
          color: colBoxBg, // Background color in case total < 100%
        ),
        child: Stack(children: barLayers),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
      children: _sortedCategories
          .map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cat['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      cat['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    "- Rs. ${NumberFormat('#,##0').format(cat['amount'])}",
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopExpensesList() {
    final expenses = [
      {
        "name": "Shell Petroleum",
        "amount": "- Rs. 1500",
        "icon": Icons.local_gas_station,
      },
      {
        "name": "D-Mart",
        "amount": "- Rs. 2000",
        "icon": Icons.shopping_bag_outlined,
      },
      {
        "name": "Unknown Source",
        "amount": "+ Rs. 2000",
        "icon": Icons.currency_rupee,
      },
    ];
    return Column(
      children: expenses
          .map(
            (ex) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              width: double.infinity,
              height: boxHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colBoxBg,
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: Row(
                children: [
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
                    child: Icon(
                      ex['icon'] as IconData,
                      size: 28,
                      color: colBlack,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ex['name'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colBlack,
                          ),
                        ),
                        Text(
                          "Bank account",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: colGrey80,
                            fontWeight: FontWeight.w500,
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
                        ex['amount'] as String,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colBlack,
                        ),
                      ),
                      Text(
                        "Fri, 11 April 2025",
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: colGrey80,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tip of the day",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Cooking one meal at home can save enough to grow 3 new leaves.",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: colGrey80,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
