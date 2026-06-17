import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/app_style.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    return const TreeStatus(label: "Dense Forest", image: "dense_forest.png", treesGrown: 5);
  } else if (percentage >= 0.66) {
    return const TreeStatus(label: "Grand Forest", image: "grand_forest.png", treesGrown: 3);
  } else if (percentage >= 0.50) {
    return const TreeStatus(label: "Forest", image: "forest.png", treesGrown: 2);
  } else if (percentage >= 0.33) {
    return const TreeStatus(label: "String Tree", image: "string_tree.png", treesGrown: 1);
  } else if (percentage >= 0.16) {
    return const TreeStatus(label: "Drying Tree", image: "drying_tree.png", treesGrown: 0);
  } else {
    return const TreeStatus(label: "Dry Tree", image: "dry_tree.png", treesGrown: 0);
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

  final AudioPlayer _audioPlayer = AudioPlayer();

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

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _loadLimitAndData();
    TransactionService().addListener(_onDataChanged);
    if (widget.isActive) _playForestSound();
  }

  @override
  void didUpdateWidget(covariant ForestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Triggers when the tab becomes fully active after a swipe
    if (widget.isActive && !oldWidget.isActive) {
      _playForestSound();
    }
  }

  @override
  void dispose() {
    TransactionService().removeListener(_onDataChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // NEW: load daily limit (same SharedPreferences key as DashboardScreen)
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

  // --- NEW: PLAYBACK LOGIC (unchanged) ---
  Future<void> _playForestSound() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isSoundEnabled = prefs.getBool('sound_effects') ?? true;

    if (!isSoundEnabled) return;

    final hour = DateTime.now().hour;
    final bool isNight = hour >= 18 || hour < 6;

    final String audioFile = isNight
        ? 'audio/night_forest.m4a'
        : 'audio/morning_forest.m4a';

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(audioFile));
  }

  // ==========================================
  // NEW: MONTHLY DATA CALCULATIONS
  // ==========================================

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Returns daily tree percentage using the same formula as Dashboard:
  /// percentage = pendingLimit / dailyLimit, where
  /// pendingLimit = (dailyLimit - dailyExpense).clamp(0, dailyLimit)
  double _dailyPercentage(double dailyExpense) {
    if (_dailyLimit <= 0) return 0.0;
    double pendingLimit = (_dailyLimit - dailyExpense).clamp(
      0.0,
      _dailyLimit.toDouble(),
    );
    return (pendingLimit / _dailyLimit).clamp(0.0, 1.0);
  }

  /// Computes per-day expense totals for every day of the focused month.
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

  /// Computes tree-type counts and total trees grown for the month.
  Map<String, dynamic> _computeForestStats() {
    final dailyTotals = _monthlyDailyExpenses();

    // Counts per tree type, in tree_1..tree_6 order
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

  /// Total monthly expense for the focused month.
  double _monthlyExpense() {
    final dailyTotals = _monthlyDailyExpenses();
    return dailyTotals.values.fold(0.0, (sum, v) => sum + v);
  }

  /// Monthly allowed budget = dailyLimit * daysInMonth
  int _monthlyAllowedBudget() {
    return _dailyLimit * _daysInMonth(_focusedDate);
  }

  /// Forest-level percentage: how much of the monthly budget remains.
  /// percentage = pendingMonthlyBudget / monthlyAllowedBudget
  double _monthlyPercentage() {
    final allowed = _monthlyAllowedBudget();
    if (allowed <= 0) return 0.0;
    final expense = _monthlyExpense();
    final pending = (allowed - expense).clamp(0.0, allowed.toDouble());
    return (pending / allowed).clamp(0.0, 1.0);
  }

  /// Days passed in the focused month (capped to today if current month).
  int _daysPassed() {
    final now = DateTime.now();
    final daysInMonth = _daysInMonth(_focusedDate);
    if (_focusedDate.year == now.year && _focusedDate.month == now.month) {
      return now.day;
    }
    // For past months, all days have passed; for future months, 0.
    if (DateTime(_focusedDate.year, _focusedDate.month, 1).isBefore(
      DateTime(now.year, now.month, 1),
    )) {
      return daysInMonth;
    }
    return 0;
  }

  double _averageDailyExpense() {
    final daysPassed = _daysPassed();
    if (daysPassed <= 0) return 0.0;
    return _monthlyExpense() / daysPassed;
  }

  /// Returns a comparable "score" for a given month: pendingBudget / allowedBudget.
  /// Used to compare current vs previous month.
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

  /// Returns comparison text between current and previous month.
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

  /// Groups all transactions in the focused month by category.
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

  /// Returns top 3 transactions in the focused month, sorted by amount desc.
  List<Transaction> _computeTopExpenses() {
    final daysInMonth = _daysInMonth(_focusedDate);
    final List<Transaction> allTx = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      allTx.addAll(TransactionService().getTransactionsForDay(date));
    }

    allTx.sort((a, b) => b.amount.compareTo(a.amount));
    return allTx.take(3).toList();
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
    MediaQuery.platformBrightnessOf(context);

    // NEW: compute everything for the focused month
    final forestStats = _computeForestStats();
    final monthlyExpense = _monthlyExpense();
    final monthlyAllowed = _monthlyAllowedBudget();
    final monthlyPercentage = _monthlyPercentage();
    final forestStatus = getForestStatusForPercentage(monthlyPercentage);
    final averageDaily = _averageDailyExpense();
    final comparisonText = _getComparisonText();
    _sortedCategories = _computeCategorySpends();
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
                      // 1. Header
                      _buildHeader(),
                      const SizedBox(height: 20),

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
                        "Rs. ${NumberFormat('#,##0').format(averageDaily)} / ${NumberFormat('#,##0').format(monthlyAllowed)}",
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
                fontSize: 18,
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SpentWrapScreen()),
            );
          },
          child: Icon(
            PhosphorIcons.trophy,
            size: 32,
            color: AppColors.colblack,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCalendar() {
    return Container(
      // Compact height
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

  // CHANGED: now fully dynamic — forest image/background/badge driven by monthlyPercentage,
  // tree list and total trees grown driven by daily tree-state aggregation.
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
                  // CHANGED: dynamic background color based on forest status
                  color: forestStatus.color,
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
              ),

              // CHANGED: dynamic forest image based on forest status
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

        // Badge — CHANGED: dynamic comparison text, color matches forest status
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

        // Tree Stats — CHANGED: dynamic total
        Text(
          "Total trees grown : $totalTreesGrown",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 16),

        // Tree List Loop — CHANGED: counts now computed from monthly data
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

  // CHANGED: badge now dynamic per ForestStatus
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
                  Icon(forestStatus.icon, color: AppColors.colblack, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    forestStatus.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: AppColors.colblack,
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
      // Graceful empty state: render an empty bar with no segments
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
        decoration: BoxDecoration(
          color: AppColors.inputFill,
        ),
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

  // CHANGED: now driven by real transactions
  Widget _buildTopExpensesList(List<Transaction> topExpenses) {
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
                    child: Icon(
                      tx.icon,
                      size: 28,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tx.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),
                        Text(
                          tx.isManual ? "Cash" : "Bank account",
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
                        DateFormat('E, d MMMM yyyy').format(tx.date),
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