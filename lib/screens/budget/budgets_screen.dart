import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/monthly_insights_service.dart';
import 'package:spentree/core/entitlement_service.dart';
import 'budget_models.dart';
import 'new_budget_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  DateTime _focusedDate = DateTime.now();
  bool _isPickerOpen = false;

  final MonthlyInsightsService _insights = MonthlyInsightsService();
  final double cardRadius = 15.0;

  // Live swipe progress per budget id (0.0 → 1.0) and which direction it's
  // being dragged in — direction decides which side's corners square off
  // to meet the red reveal. Same mechanism as buckets_screen.dart.
  final Map<String, double> _budgetDragProgress = {};
  final Map<String, DismissDirection> _budgetDragDirection = {};

  // Ids removed locally the instant a swipe completes, so the Dismissible
  // for that id is never rebuilt again on the same frame — this is what
  // actually prevents the "dismissed Dismissible still part of the tree"
  // crash, regardless of how quickly BudgetService's own list updates.
  final Set<String> _deletedBudgetIds = {};

  @override
  void initState() {
    super.initState();
    // Budgets is a fully Pro feature — the sync itself is also Pro-gated
    // server-side (encrypt-budget/decrypt-budget), this just kicks off the
    // pull/push cycle for whoever is signed in.
    BudgetService().initService();
  }

  void _moveMonth(int months) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + months, 1);
    });
  }

  void _onMonthChanged(int index) {
    setState(() => _focusedDate = DateTime(_focusedDate.year, index + 1, 1));
  }

  void _onYearChanged(int index) {
    setState(() => _focusedDate = DateTime(2025 + index, _focusedDate.month, 1));
  }

  void _deleteBudget(CategoryBudget budget) {
    setState(() {
      _deletedBudgetIds.add(budget.id);
      _budgetDragProgress.remove(budget.id);
      _budgetDragDirection.remove(budget.id);
    });
    BudgetService().removeBudget(budget.id);
  }

  // Squares off only the side the red is being revealed from — identical
  // logic to buckets_screen.dart's _cardRadiusForDrag.
  BorderRadius _cardRadiusForDrag(String budgetId) {
    final raw = _budgetDragProgress[budgetId] ?? 0.0;
    final direction = _budgetDragDirection[budgetId];
    if (raw <= 0 || direction == null || direction == DismissDirection.none) {
      return BorderRadius.circular(cardRadius);
    }
    final squareAmount = (raw / 0.08).clamp(0.0, 1.0);
    final roundedRadius = Radius.circular(cardRadius);
    final squaredRadius = Radius.circular(cardRadius * (1 - squareAmount));
    final squareLeft = direction == DismissDirection.startToEnd;
    return BorderRadius.only(
      topLeft: squareLeft ? squaredRadius : roundedRadius,
      bottomLeft: squareLeft ? squaredRadius : roundedRadius,
      topRight: squareLeft ? roundedRadius : squaredRadius,
      bottomRight: squareLeft ? roundedRadius : squaredRadius,
    );
  }

  Widget _buildBudgetSwipeReveal({required bool alignStart}) {
    return Container(
      color: AppColors.destructiveRed,
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(PhosphorIconsRegular.trash, color: AppColors.colwhite, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    // DEFENSE IN DEPTH ONLY — the real enforcement is server-side
    // (encrypt-budget/decrypt-budget reject non-Pro callers). This guard
    // just avoids rendering Pro UI if the route is somehow reached
    // directly, mirroring buckets_screen.dart's approach exactly: no
    // visible "Pro required" text, just a quiet back-out.
    return ListenableBuilder(
      listenable: EntitlementService(),
      builder: (context, _) {
        if (!EntitlementService().isProForCurrentUser) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return Scaffold(backgroundColor: AppColors.bgWhite);
        }
        return _buildBudgetsScaffold(context);
      },
    );
  }

  Widget _buildBudgetsScaffold(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return ListenableBuilder(
          listenable: BudgetService(),
          builder: (context, _) {
            final budgets = BudgetService()
                .budgetsForMonth(_focusedDate)
                .where((b) => !_deletedBudgetIds.contains(b.id))
                .toList();
            final categorySpends = _insights.computeCategorySpends(_focusedDate, forceAll: true);
            final spendByCategory = {
              for (final entry in categorySpends) entry['name'] as String: entry['amount'] as double,
            };

            // Total Budget card is the sum of the cards actually shown
            // below it — NOT a daily-limit-derived monthly pool. This also
            // removes the async-dependent value that used to cause a
            // visible "blink" once a network fetch resolved: budgets and
            // local transaction spend are both already in memory (Isar +
            // TransactionService), so this never needs to wait on
            // anything before it can render its final value.
            final totalBudgeted = budgets.fold(0.0, (sum, b) => sum + b.limit);
            final totalUsedAcrossBudgeted = budgets.fold(
              0.0,
              (sum, b) => sum + (spendByCategory[b.category] ?? 0.0),
            );

            return Scaffold(
              backgroundColor: AppColors.bgWhite,
              body: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildMonthlyCalendar(),
                      const SizedBox(height: 20),
                      _buildNewBudgetButton(),
                      const SizedBox(height: 20),

                      if (budgets.isNotEmpty) ...[
                        _buildTotalBudgetCard(totalUsedAcrossBudgeted, totalBudgeted),
                        const SizedBox(height: 20),
                      ],

                      if (budgets.isEmpty)
                        _buildEmptyState()
                      else
                        Column(
                          children: budgets
                              .map((b) => _buildBudgetCard(b, spendByCategory[b.category] ?? 0.0))
                              .toList(),
                        ),

                      if (budgets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            "That's it for today.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _buildTipSection(),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.divider, thickness: 1),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Planted with love in Mumbai, India",
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white500),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Smart",
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.colblack),
        ),
        Text(
          "Budget",
          style: GoogleFonts.montserrat(fontSize: 36, fontWeight: FontWeight.w600, height: 1.0, color: AppColors.colblack),
        ),
      ],
    );
  }

  // --- MONTH CALENDAR (same component/behaviour as Forest/Buckets — unchanged) ---
  Widget _buildMonthlyCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(cardRadius)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _moveMonth(-1),
                  child: Icon(Icons.chevron_left, size: 24, color: AppColors.colblack),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDate),
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.colblack),
                ),
                GestureDetector(
                  onTap: () => _moveMonth(1),
                  child: Icon(Icons.chevron_right, size: 24, color: AppColors.colblack),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPickerOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
              scrollController: FixedExtentScrollController(initialItem: _focusedDate.month - 1),
              itemExtent: 32,
              onSelectedItemChanged: _onMonthChanged,
              children: List.generate(
                12,
                (i) => Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, i + 1)),
                    style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.colblack),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _focusedDate.year - 2025),
              itemExtent: 32,
              onSelectedItemChanged: _onYearChanged,
              children: List.generate(
                10,
                (i) => Center(
                  child: Text(
                    "${2025 + i}",
                    style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.colblack),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBudgetButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewBudgetScreen(month: _focusedDate)),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.colwhite, size: 20),
            const SizedBox(width: 8),
            Text(
              "New Budget",
              style: GoogleFonts.poppins(color: AppColors.colwhite, fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBudgetCard(double used, double totalBudgeted) {
    final progress = totalBudgeted > 0 ? (used / totalBudgeted).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(cardRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Budget",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white500),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "Rs. ${NumberFormat('#,##0').format(used)}",
                style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.colblack),
              ),
              Text(
                " / ${NumberFormat('#,##0').format(totalBudgeted)}",
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.white500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.colwhite,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            // Reference design shows this icon at a slight tilt rather than
            // perfectly upright — matched here rather than left square.
            Transform.rotate(
              angle: -0.12, // ~ -7 degrees
              child: Icon(PhosphorIconsRegular.bug, size: 90, color: AppColors.white500),
            ),
            const SizedBox(height: 20),
            Text(
              "You have not yet\ndecided any budget",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.white500),
            ),
          ],
        ),
      ),
    );
  }

  // Same structural approach as buckets_screen.dart's _buildBucketRow:
  // the card and the red delete reveal are both clipped to one ClipRRect
  // so they can never "un-merge" mid-swipe, and the 15px gap between cards
  // lives in an outer Padding, outside the Dismissible entirely, so the
  // red never bleeds into that gap.
  Widget _buildBudgetCard(CategoryBudget budget, double usedThisMonth) {
    final assets = _insights.getCategoryAssets(budget.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Dismissible(
          key: ValueKey(budget.id),
          direction: DismissDirection.horizontal,
          resizeDuration: const Duration(milliseconds: 400),
          movementDuration: const Duration(milliseconds: 250),
          onUpdate: (details) {
            setState(() {
              _budgetDragProgress[budget.id] = details.progress;
              _budgetDragDirection[budget.id] = details.direction;
            });
          },
          onDismissed: (_) => _deleteBudget(budget),
          background: _buildBudgetSwipeReveal(alignStart: true),
          secondaryBackground: _buildBudgetSwipeReveal(alignStart: false),
          child: Container(
            height: 76.0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.colwhite,
              borderRadius: _cardRadiusForDrag(budget.id),
              border: Border.all(color: AppColors.inputFill, width: 1),
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
                      BoxShadow(color: AppColors.colblack.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(assets['icon1'], color: AppColors.colblack, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        budget.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.colblack),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(budget.month),
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "- Rs. ${NumberFormat('#,##0').format(usedThisMonth)}",
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.colblack),
                    ),
                    Text(
                      "/ Rs. ${NumberFormat('#,##0').format(budget.limit)}",
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tip of the day",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.colblack),
        ),
        const SizedBox(height: 8),
        Text(
          "Cooking one meal at home can save enough to grow 3 new leaves.",
          style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w500, color: AppColors.white500, height: 1.3),
        ),
      ],
    );
  }
}