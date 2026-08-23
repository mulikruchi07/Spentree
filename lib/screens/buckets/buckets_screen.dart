import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/transaction_service.dart';
import 'bucket_models.dart';
import 'bucket_detail_screen.dart';
import 'slide_route.dart';

class BucketsScreen extends StatefulWidget {
  const BucketsScreen({super.key});

  @override
  State<BucketsScreen> createState() => _BucketsScreenState();
}

class _BucketsScreenState extends State<BucketsScreen> {
  DateTime _focusedDate = DateTime.now();
  bool _isPickerOpen = false;

  // Only one bucket's dropdown is open at a time, per the design.
  String? _expandedBucketId;

  // Live swipe progress per bucket id (0.0 → 1.0) and which direction it's
  // being dragged in — direction decides which side's corners square off
  // to meet the red reveal.
  final Map<String, double> _bucketDragProgress = {};
  final Map<String, DismissDirection> _bucketDragDirection = {};

  // Ids removed locally the instant a swipe completes, so the Dismissible
  // for that id is never rebuilt again on the same frame — this is what
  // actually prevents the "dismissed Dismissible still part of the tree"
  // crash, regardless of how quickly BucketService's own list updates.
  final Set<String> _deletedBucketIds = {};

  final double cardRadius = 15.0;
  final double boxHeight = 76.0;

  void _moveMonth(int months) {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + months,
        1,
      );
      _expandedBucketId = null;
    });
  }

  void _onMonthChanged(int index) {
    setState(() => _focusedDate = DateTime(_focusedDate.year, index + 1, 1));
  }

  void _onYearChanged(int index) {
    setState(
      () => _focusedDate = DateTime(2025 + index, _focusedDate.month, 1),
    );
  }

  void _toggleExpanded(String bucketId) {
    setState(() {
      _expandedBucketId = _expandedBucketId == bucketId ? null : bucketId;
    });
  }

  void _deleteBucket(Bucket bucket) {
    setState(() {
      _deletedBucketIds.add(bucket.id);
      if (_expandedBucketId == bucket.id) _expandedBucketId = null;
      _bucketDragProgress.remove(bucket.id);
      _bucketDragDirection.remove(bucket.id);
    });
    BucketService().deleteBucket(bucket.id);
  }

  // Squares off only the side the red is being revealed from, so that
  // edge sits flush against the reveal instead of showing a curved sliver
  // of card poking past a straight red edge. The opposite side stays
  // rounded. Ramped hard so it reads as immediate (done by ~8% of the
  // drag) while still being a real interpolation, not a hard jump.
  BorderRadius _cardRadiusForDrag(String bucketId) {
    final raw = _bucketDragProgress[bucketId] ?? 0.0;
    final direction = _bucketDragDirection[bucketId];
    if (raw <= 0 || direction == null || direction == DismissDirection.none) {
      return BorderRadius.circular(cardRadius);
    }
    final squareAmount = (raw / 0.08).clamp(0.0, 1.0);
    final roundedRadius = Radius.circular(cardRadius);
    final squaredRadius = Radius.circular(cardRadius * (1 - squareAmount));

    // startToEnd = dragging right = reveal comes from the LEFT = square
    // the left corners. endToStart = dragging left = reveal from the
    // RIGHT = square the right corners.
    final squareLeft = direction == DismissDirection.startToEnd;
    return BorderRadius.only(
      topLeft: squareLeft ? squaredRadius : roundedRadius,
      bottomLeft: squareLeft ? squaredRadius : roundedRadius,
      topRight: squareLeft ? roundedRadius : squaredRadius,
      bottomRight: squareLeft ? roundedRadius : squaredRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return ListenableBuilder(
          listenable: BucketService(),
          builder: (context, _) {
            final buckets = BucketService()
                .bucketsForMonth(_focusedDate)
                .where((b) => !_deletedBucketIds.contains(b.id))
                .toList();

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
                      _buildNewBucketButton(),
                      const SizedBox(height: 20),

                      if (buckets.isEmpty)
                        _buildEmptyState()
                      else
                        Column(
                          children: buckets
                              .map((b) => _buildBucketRow(b))
                              .toList(),
                        ),

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
                      const SizedBox(height: 32),

                      _buildTipSection(),
                      const SizedBox(height: 20),
                      Divider(color: AppColors.divider, thickness: 0.5),
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
              "Buckets",
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: AppColors.colblack,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- MONTH CALENDAR (same component/behaviour as Forest) ---
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

  Widget _buildNewBucketButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _expandedBucketId = null);
        Navigator.push(
          context,
          slideRoute(const BucketDetailScreen(existingBucket: null)),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.colwhite, size: 20),
            const SizedBox(width: 8),
            Text(
              "New Bucket",
              style: GoogleFonts.poppins(
                color: AppColors.colwhite,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Transform.rotate(
              angle: -13.28 * math.pi / 180,
              child: Icon(
                PhosphorIconsRegular.bug,
                size: 90,
                color: AppColors.white500,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No buckets made yet",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.white500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUCKET ROW ---
  // Everything — the collapsed header, the expanded drop, AND the swipe
  // reveal — is wrapped in a single ClipRRect. That's what keeps the red
  // delete reveal and the card's rounded corners from ever "un-merging":
  // both are clipped to the exact same rounded rectangle, at any height
  // (collapsed or expanded), so there's never a square sliver of red
  // poking out past a curved card corner.
  //
  // The 15px gap between cards lives in an outer Padding, outside the
  // Dismissible entirely, so the red reveal never bleeds into that gap.
  //
  // Colors that only toggle between "transparent" and an opaque color
  // (on expand/collapse) use `opaqueColor.withOpacity(0)` as the
  // "transparent" endpoint instead of Colors.transparent — lerping
  // between true transparent (black at 0 alpha) and an opaque color
  // passes through a visible grey/black flash partway through the
  // animation; same-hue-zero-opacity avoids that entirely.
  Widget _buildBucketRow(Bucket bucket) {
    final isExpanded = _expandedBucketId == bucket.id;
    const dropDuration = Duration(milliseconds: 300);
    const dropCurve = Curves.easeOutCubic;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Dismissible(
          key: ValueKey(bucket.id),
          direction: isExpanded
              ? DismissDirection.none
              : DismissDirection.horizontal,
          resizeDuration: const Duration(milliseconds: 400),
          movementDuration: const Duration(milliseconds: 250),
          onUpdate: (details) {
            setState(() {
              _bucketDragProgress[bucket.id] = details.progress;
              _bucketDragDirection[bucket.id] = details.direction;
            });
          },
          onDismissed: (_) => _deleteBucket(bucket),
          background: _buildBucketSwipeReveal(alignStart: true),
          secondaryBackground: _buildBucketSwipeReveal(alignStart: false),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: dropDuration,
                curve: dropCurve,
                padding: isExpanded
                    ? const EdgeInsets.all(10)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppColors.inputFill
                      : AppColors.inputFill.withOpacity(0),
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleExpanded(bucket.id),
                      child: AnimatedContainer(
                        duration: dropDuration,
                        curve: dropCurve,
                        height: boxHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppColors.colwhite
                              : AppColors.colwhite.withOpacity(0),
                          borderRadius: _cardRadiusForDrag(bucket.id),
                          border: isExpanded
                              ? null
                              : Border.all(
                                  color: AppColors.inputFill,
                                  width: 1,
                                ),
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
                                PhosphorIconsRegular.archive,
                                color: AppColors.colblack,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    bucket.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.colblack,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                    ).format(bucket.dominantMonth),
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
                                  "- Rs. ${NumberFormat('#,##0').format(bucket.total)}",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                  ),
                                ),
                                Text(
                                  "${bucket.transactions.length} Expenses",
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
                      ),
                    ),
                    AnimatedSize(
                      duration: dropDuration,
                      curve: dropCurve,
                      alignment: Alignment.topCenter,
                      child: isExpanded
                          ? _buildExpandedContent(bucket)
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                  ],
                ),
              ),

              if (_bucketOverlayOpacity(bucket.id) > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _bucketOverlayOpacity(bucket.id),
                      child: Container(color: AppColors.destructiveRed),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _bucketOverlayOpacity(String bucketId) {
    final raw = (_bucketDragProgress[bucketId] ?? 0.0).clamp(0.0, 1.0);
    return (raw / 0.75).clamp(0.0, 1.0);
  }

  // Icon inset only — the red itself fills the entire clipped area (the
  // parent ClipRRect in _buildBucketRow is what gives it rounded corners,
  // so it always matches the card's own curve exactly).
  Widget _buildBucketSwipeReveal({required bool alignStart}) {
    return Container(
      color: AppColors.destructiveRed,
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(PhosphorIcons.trash, color: AppColors.colwhite, size: 26),
      ),
    );
  }

  Widget _buildExpandedContent(Bucket bucket) {
    final rows = bucket.transactions;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++)
            _buildExpenseListRow(rows[i], isLast: i == rows.length - 1),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _expandedBucketId = null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7D8D6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.destructiveRed,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _expandedBucketId = null);
                      Navigator.push(
                        context,
                        slideRoute(BucketDetailScreen(existingBucket: bucket)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Edit Bucket",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colwhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // No separate box per expense — a plain row, divided by a thin line,
  // padded to match the bucket name card's own horizontal padding (10).
  Widget _buildExpenseListRow(dynamic tx, {required bool isLast}) {
    final hour = TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod == 0
        ? 12
        : TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod;
    final minute = TimeOfDay.fromDateTime(
      tx.dateTime,
    ).minute.toString().padLeft(2, '0');
    final period = TimeOfDay.fromDateTime(tx.dateTime).period == DayPeriod.am
        ? "AM"
        : "PM";
    final timeStr = "$hour:$minute $period";

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                  TransactionService().getIconForCategory(tx.category),
                  color: AppColors.colblack,
                  size: 28,
                ),
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
                      (tx.type == 'Cash') ? "Manual entry" : "Bank account",
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
                    "- Rs. ${tx.amount.toStringAsFixed(0)}",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
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
        ),
        if (!isLast)
          Divider(color: AppColors.divider, thickness: 0.5, height: 1),
      ],
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
