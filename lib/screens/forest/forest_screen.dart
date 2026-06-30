import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/app_style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/monthly_insights_service.dart';
import '../../core/transaction_service.dart';
import '../../core/user_data.dart';
import 'spentwrap_intro_screen.dart';

// NEW: Centralized 6-state tree status helper (mirrors Dashboard logic)
class TreeStatus {
  final String label; // tree type name
  final String image; // tree image filename
  final int treesGrown;

  const TreeStatus({
    required this.label,
    required this.image,
    required this.treesGrown,
  });
}

TreeStatus getTreeStatusForPercentage(double percentage) {
  if (percentage >= 0.83) {
    return const TreeStatus(
      label: "Dense Forest",
      image: "dense_forest.png",
      treesGrown: 5,
    );
  } else if (percentage >= 0.66) {
    return const TreeStatus(
      label: "Grand Forest",
      image: "grand_forest.png",
      treesGrown: 3,
    );
  } else if (percentage >= 0.50) {
    return const TreeStatus(
      label: "Forest",
      image: "forest.png",
      treesGrown: 2,
    );
  } else if (percentage >= 0.33) {
    return const TreeStatus(
      label: "String Tree",
      image: "string_tree.png",
      treesGrown: 1,
    );
  } else if (percentage >= 0.16) {
    return const TreeStatus(
      label: "Drying Tree",
      image: "drying_tree.png",
      treesGrown: 0,
    );
  } else {
    return const TreeStatus(
      label: "Dry Tree",
      image: "dry_tree.png",
      treesGrown: 0,
    );
  }
}

// NEW: Forest-level (monthly) 5-state status helper
class ForestStatus {
  final String label; // Great/Good/Warning/Poor/Empty
  final IconData icon;
  final Color color;
  final String image; // forest_*.png

  const ForestStatus({
    required this.label,
    required this.icon,
    required this.color,
    required this.image,
  });
}

ForestStatus getForestStatusForPercentage(double percentage) {
  // percentage = pendingBudget / allowedBudget (higher = better, same direction as Dashboard)
  if (percentage >= 0.83) {
    return const ForestStatus(
      label: "Great",
      icon: Icons.trending_up,
      color: Color(0xFF34C759),
      image: "forest_great.png",
    );
  } else if (percentage >= 0.66) {
    return const ForestStatus(
      label: "Good",
      icon: Icons.trending_up,
      color: Color(0xFF34C759),
      image: "forest_good.png",
    );
  } else if (percentage >= 0.33) {
    return const ForestStatus(
      label: "Warning",
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFFCC00),
      image: "forest_warning.png",
    );
  } else if (percentage >= 0.16) {
    return const ForestStatus(
      label: "Poor",
      icon: Icons.trending_down,
      color: Color(0xFFFF383C),
      image: "forest_poor.png",
    );
  } else {
    return const ForestStatus(
      label: "Empty",
      icon: Icons.trending_down,
      color: Color(0xFFFF383C),
      image: "forest_empty.png",
    );
  }
}

class ForestScreen extends StatefulWidget {
  final bool isActive;
  const ForestScreen({super.key, this.isActive = false});

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

  // NEW: daily limit, loaded from SharedPreferences (same key as Dashboard)
  int _dailyLimit = 5000;

  // Dynamic Palette (Darkest to Lightest)
  final List<Color> _greenPalette = [
    const Color(0xFF005A32),
    const Color(0xFF238B45),
    const Color(0xFF41AB5D),
    const Color(0xFF74C476),
    const Color(0xFFA1D99B),
    const Color(0xFFC7E9C0),
  ];

  // Data (now computed, not hardcoded)
  late List<Map<String, dynamic>> _sortedCategories;

  WrapStatus _wrapStatus = WrapStatus(isAvailable: false, showDot: false);
  bool _isWrapDismissed = false; // Tracks if the user hit the 'X'

  final MonthlyInsightsService _insights = MonthlyInsightsService();

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _loadLimitAndData();
    _checkWrapEligibility();
    TransactionService().addListener(_onDataChanged);
  }

  // Check Wrap Status & Dismissal State
  Future<void> _checkWrapEligibility() async {
    final status = await _insights.checkWrapStatus();
    bool isDismissed = false;

    if (status.targetMonth != null) {
      final prefs = await SharedPreferences.getInstance();
      isDismissed =
          prefs.getBool(
            'wrap_dismissed_${status.targetMonth!.year}_${status.targetMonth!.month}',
          ) ??
          false;
    }

    if (mounted) {
      setState(() {
        _wrapStatus = status;
        _isWrapDismissed = isDismissed;
      });
    }
  }

  // Permanently hides the banner for the current target month
  Future<void> _dismissWrap() async {
    if (_wrapStatus.targetMonth != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'wrap_dismissed_${_wrapStatus.targetMonth!.year}_${_wrapStatus.targetMonth!.month}',
        true,
      );
      setState(() {
        _isWrapDismissed = true;
      });
    }
  }

  @override
  void dispose() {
    TransactionService().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _checkWrapEligibility(); // Re-check if day rolls over while app is open
      setState(() {});
    }
  }

  Future<void> _loadLimitAndData() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedLimit = prefs.getInt('daily_expense_limit');
    setState(() {
      if (savedLimit != null) {
        _dailyLimit = savedLimit;
      } else {
        int? parsedLimit = int.tryParse(
          UserData.dailyLimit.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        _dailyLimit = parsedLimit ?? 5000;
      }
    });
  }

  // ==========================================
  // MONTHLY DATA CALCULATIONS
  // ==========================================

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  double _dailyPercentage(double dailyExpense) {
    if (_dailyLimit <= 0) return 0.0;
    double pendingLimit = (_dailyLimit - dailyExpense).clamp(
      0.0,
      _dailyLimit.toDouble(),
    );
    return (pendingLimit / _dailyLimit).clamp(0.0, 1.0);
  }

  Map<int, double> _monthlyDailyExpenses() {
    final daysInMonth = _daysInMonth(_focusedDate);
    final Map<int, double> dailyTotals = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final tx = TransactionService().getTransactionsForDay(date);
      final total = tx.fold(0.0, (sum, item) => sum + item.amount);
      dailyTotals[day] = total;
    }
    return dailyTotals;
  }

  Map<String, dynamic> _computeForestStats() {
    final dailyTotals = _monthlyDailyExpenses();

    int dense = 0, grand = 0, forest = 0, string = 0, drying = 0, dry = 0;
    int totalTreesGrown = 0;

    dailyTotals.forEach((day, expense) {
      final pct = _dailyPercentage(expense);
      final status = getTreeStatusForPercentage(pct);
      totalTreesGrown += status.treesGrown;

      switch (status.label) {
        case "Dense Forest":
          dense++;
          break;
        case "Grand Forest":
          grand++;
          break;
        case "Forest":
          forest++;
          break;
        case "String Tree":
          string++;
          break;
        case "Drying Tree":
          drying++;
          break;
        case "Dry Tree":
          dry++;
          break;
      }
    });

    return {
      "totalTreesGrown": totalTreesGrown,
      "treeCounts": [
        {"name": "Dense Forest", "image": "dense_forest.png", "count": dense},
        {"name": "Grand Forest", "image": "grand_forest.png", "count": grand},
        {"name": "Forest", "image": "forest.png", "count": forest},
        {"name": "String Tree", "image": "string_tree.png", "count": string},
        {"name": "Drying Tree", "image": "drying_tree.png", "count": drying},
        {"name": "Dry Tree", "image": "dry_tree.png", "count": dry},
      ],
    };
  }

  double _monthlyExpense() {
    final dailyTotals = _monthlyDailyExpenses();
    return dailyTotals.values.fold(0.0, (sum, v) => sum + v);
  }

  int _monthlyAllowedBudget() {
    return _dailyLimit * _daysInMonth(_focusedDate);
  }

  double _monthlyPercentage() {
    final allowed = _dailyLimit * _insights.daysInMonth(_focusedDate);
    if (allowed <= 0) return 0.0;
    final expense = _insights.getTotalMonthlyExpense(_focusedDate);
    final pending = (allowed - expense).clamp(0.0, allowed.toDouble());
    return (pending / allowed).clamp(0.0, 1.0);
  }

  int _daysPassed() {
    final now = DateTime.now();
    final daysInMonth = _daysInMonth(_focusedDate);
    if (_focusedDate.year == now.year && _focusedDate.month == now.month) {
      return now.day;
    }
    if (DateTime(
      _focusedDate.year,
      _focusedDate.month,
      1,
    ).isBefore(DateTime(now.year, now.month, 1))) {
      return daysInMonth;
    }
    return 0;
  }

  double _averageDailyExpense() {
    final daysInMonth = _insights.daysInMonth(_focusedDate);
    final now = DateTime.now();
    int daysPassed =
        (_focusedDate.year == now.year && _focusedDate.month == now.month)
        ? now.day
        : (DateTime(
                _focusedDate.year,
                _focusedDate.month,
                1,
              ).isBefore(DateTime(now.year, now.month, 1))
              ? daysInMonth
              : 0);

    if (daysPassed <= 0) return 0.0;
    return _insights.getTotalMonthlyExpense(_focusedDate) / daysPassed;
    // return _dailyLimit.toDouble();
  }

  double _monthScore(DateTime monthDate) {
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final allowed = _dailyLimit * daysInMonth;
    if (allowed <= 0) return 0.0;

    double monthExpense = 0.0;
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthDate.year, monthDate.month, day);
      final tx = TransactionService().getTransactionsForDay(date);
      monthExpense += tx.fold(0.0, (sum, item) => sum + item.amount);
    }

    final pending = (allowed - monthExpense).clamp(0.0, allowed.toDouble());
    return pending / allowed;
  }

  String _getComparisonText() {
    final currentScore = _monthScore(_focusedDate);
    final previousMonthDate = DateTime(
      _focusedDate.year,
      _focusedDate.month - 1,
      1,
    );
    final previousScore = _monthScore(previousMonthDate);

    final currentMonthName = DateFormat('MMM').format(_focusedDate);
    final previousMonthName = DateFormat('MMM').format(previousMonthDate);

    return currentScore >= previousScore
        ? "$currentMonthName was more greener than $previousMonthName"
        : "$previousMonthName was more greener than $currentMonthName";
  }

  List<Map<String, dynamic>> _computeCategorySpends() {
    final daysInMonth = _daysInMonth(_focusedDate);
    final Map<String, double> totals = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final tx = TransactionService().getTransactionsForDay(date);
      for (var item in tx) {
        totals[item.category] = (totals[item.category] ?? 0.0) + item.amount;
      }
    }

    var entries = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < entries.length; i++) {
      result.add({
        "name": entries[i].key,
        "amount": entries[i].value,
        "color": _greenPalette[i % _greenPalette.length],
      });
    }
    return result;
  }

  List<LocalTransaction> _computeTopExpenses() {
    final daysInMonth = _insights.daysInMonth(_focusedDate);
    final List<LocalTransaction> allTx = [];
    for (int day = 1; day <= daysInMonth; day++) {
      allTx.addAll(
        TransactionService().getTransactionsForDay(
          DateTime(_focusedDate.year, _focusedDate.month, day),
        ),
      );
    }
    allTx.sort((a, b) => b.amount.compareTo(a.amount));
    return allTx.take(3).toList();
  }

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
    MediaQuery.platformBrightnessOf(context);

    final forestStats = _insights.computeForestStats(_focusedDate, _dailyLimit);
    final monthlyExpense = _insights.getTotalMonthlyExpense(_focusedDate);
    final monthlyAllowed = _dailyLimit * _insights.daysInMonth(_focusedDate);
    final monthlyPercentage = _monthlyPercentage();
    final forestStatus = getForestStatusForPercentage(monthlyPercentage);
    final averageDaily = _averageDailyExpense();
    final comparisonText = _getComparisonText();
    _sortedCategories = _insights.computeCategorySpends(_focusedDate);
    final topExpenses = _computeTopExpenses();
    final monthName = DateFormat('MMMM').format(_focusedDate);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
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
                      // 1. Header (Trophy gesture removed, made static)
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // NEW: Wrap Banner (Shows if available, not completed, and not dismissed via 'X')
                      if (_wrapStatus.isAvailable &&
                          _wrapStatus.showDot &&
                          !_isWrapDismissed)
                        _buildWrapBanner(),

                      // 2. Monthly Calendar Box (Compact)
                      _buildMonthlyCalendar(),
                      const SizedBox(height: 24),

                      // 3. Forest Visualization & Tree List
                      _buildForestSection(
                        monthName,
                        forestStatus,
                        forestStats,
                        comparisonText,
                      ),
                      const SizedBox(height: 32),

                      // 4. Monthly Summary
                      Text(
                        "$monthName's Summary",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        "$monthName's Expense",
                        "Rs. ${NumberFormat('#,##0').format(monthlyExpense)}",
                        isExpense: true,
                        forestStatus: forestStatus,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        "Average Daily Expense",
                        "Rs. ${NumberFormat('#,##0').format(averageDaily)} / ${NumberFormat('#,##0').format(_dailyLimit)}",
                      ),

                      const SizedBox(height: 32),

                      // 5. Category Spends
                      Text(
                        "Category Spends",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
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
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTopExpensesList(topExpenses),

                      const SizedBox(height: 48),

                      // 7. Tip & Footer
                      _buildTipSection(),
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.colblack,
              ),
            ),
            Text(
              "Forest",
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: AppColors.colblack,
              ),
            ),
          ],
        ),
        // Gesture logic removed. Trophy is strictly aesthetic now.
        Icon(
          PhosphorIconsRegular.trophy,
          size: 32,
          color: AppColors.colblack,
        ),
      ],
    );
  }

  // NEW: The Clickable Banner matching your UI Design
  Widget _buildWrapBanner() {
    final monthName = DateFormat('MMMM').format(_wrapStatus.targetMonth!);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpentWrapScreen(
              targetMonth: _wrapStatus.targetMonth!,
              dailyLimit: _dailyLimit,
            ),
          ),
        ).then(
          (_) => _checkWrapEligibility(),
        ); // Re-evaluate if user completed it
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.colwhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Green Squircle Icon Box
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                PhosphorIconsRegular.presentationChart,
                color: AppColors.colwhite,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Text(
                "$monthName Spentwrap is waiting",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
              ),
            ),
            // Close Button ('X')
            GestureDetector(
              onTap: _dismissWrap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  CupertinoIcons.clear,
                  color: AppColors.colblack,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  onTap: () => _moveMonth(-1),
                  child: Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDate),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                GestureDetector(
                  onTap: () => _moveMonth(1),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
              ],
            ),
          ),
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
              onSelectedItemChanged: _onYearChanged,
              children: List.generate(
                10,
                (i) => Center(
                  child: Text(
                    "${2025 + i}",
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

  Widget _buildForestSection(
    String monthName,
    ForestStatus forestStatus,
    Map<String, dynamic> forestStats,
    String comparisonText,
  ) {
    final treeCounts = forestStats["treeCounts"] as List<Map<String, dynamic>>;
    final totalTreesGrown = forestStats["totalTreesGrown"] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$monthName's Forest",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 152,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: forestStatus.color,
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Image.asset(
                  "assets/images/forest/${forestStatus.image}",
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            decoration: BoxDecoration(
              color: forestStatus.color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              comparisonText,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.colwhite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Total trees grown : $totalTreesGrown",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: treeCounts
              .map(
                (tree) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/forest/${tree['image']}",
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tree['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colblack,
                          ),
                        ),
                      ),
                      Text(
                        "- ${tree['count']}",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
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
    ForestStatus? forestStatus,
  }) {
    return Container(
      width: double.infinity,
      height: boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
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
                  color: AppColors.white600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colblack,
                ),
              ),
            ],
          ),
          if (isExpense && forestStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: forestStatus.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(forestStatus.icon, color: AppColors.colwhite, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    forestStatus.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.colwhite,
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
    if (_sortedCategories.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.inputFill),
        ),
      );
    }

    double total = _sortedCategories.fold(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );
    if (total <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.inputFill),
        ),
      );
    }

    double cumulativeSum = 0;
    List<Widget> barLayers = [];
    for (int i = 0; i < _sortedCategories.length; i++) {
      var cat = _sortedCategories[i];
      cumulativeSum += cat['amount'] as double;
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 24,
        width: double.infinity,
        decoration: BoxDecoration(color: AppColors.inputFill),
        child: Stack(children: barLayers),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_sortedCategories.isEmpty) {
      return Center(
        child: Text(
          "No expenses recorded this month.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white500,
          ),
        ),
      );
    }

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
                      cat['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                  ),
                  Text(
                    "- Rs. ${NumberFormat('#,##0').format(cat['amount'])}",
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopExpensesList(List<LocalTransaction> topExpenses) {
    if (topExpenses.isEmpty) {
      return Center(
        child: Text(
          "No expenses recorded this month.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white500,
          ),
        ),
      );
    }

    return Column(
      children: topExpenses
          .map(
            (tx) => Container(
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
                    child: Icon(TransactionService().getIconForCategory(tx.category), size: 28, color: AppColors.colblack),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tx.receiverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),
                        Text(
                          (tx.type == 'Cash') ? "Cash" : "Bank account",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: AppColors.white500,
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
                        "- Rs. ${NumberFormat('#,##0').format(tx.amount)}",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      Text(
                        DateFormat('E, d MMMM yyyy').format(tx.dateTime),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: AppColors.white500,
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
      ],
    );
  }
}
