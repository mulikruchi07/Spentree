import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/monthly_insights_service.dart';
import 'budget_models.dart';

// ── Dragger geometry constants ──────────────────────────────────────────
// Every offset below is derived from these three numbers, rather than
// separately guessed per-widget, which is what caused the thumb/dots/
// tooltip to not line up before: the track-end dots and the value bubble
// now use the EXACT same center-x math the Slider itself uses for the
// thumb (Flutter insets a slider's track by exactly the thumb's own
// preferred radius at each end), so at min/max the thumb sits perfectly
// centered on — and, since they're now the same size, completely covers —
// the start/end dot.
const double _kThumbOuterRadius =
    15.0; // thumb's outer ring AND dot's outer ring
const double _kThumbMiddleRadius =
    10.0; // thumb's middle ring AND dot's inner (colored) circle
const double _kThumbInnerRadius =
    6.0; // thumb's solid innermost dot (dots don't have this layer)
const double _kSliderBandHeight =
    40.0; // height reserved for the track/thumb row
const double _kBubbleWidth = 68.0;
const double _kBubbleHeight = 32.0;
const double _kBubbleTailHeight = 8.0;

class NewBudgetScreen extends StatefulWidget {
  final DateTime month;
  const NewBudgetScreen({super.key, required this.month});

  @override
  State<NewBudgetScreen> createState() => _NewBudgetScreenState();
}

class _NewBudgetScreenState extends State<NewBudgetScreen> {
  final MonthlyInsightsService _insights = MonthlyInsightsService();

  late List<String> _availableCategories;
  String? _selectedCategory;
  bool _isCategoryListVisible = false;

  double _amount = 500;
  double _maxAmount = 15000;
  bool _isLoadingMax = true;

  @override
  void initState() {
    super.initState();
    _availableCategories = BudgetService().availableCategoriesForMonth(
      widget.month,
      _insights.allCategories,
    );
    _selectedCategory = _availableCategories.isNotEmpty
        ? _availableCategories.first
        : null;
    _loadMaxAmount();
  }

  Future<void> _loadMaxAmount() async {
    int dailyLimit = 500;
    try {
      final fields = await AuthHelper.fetchDecryptedUserFields();
      final raw = fields?['daily_limit'];
      if (raw != null) {
        final parsed = double.tryParse(raw.toString());
        if (parsed != null) dailyLimit = parsed.round();
      }
    } catch (_) {
      // Keep the default.
    }

    final monthlyPool = dailyLimit * _insights.daysInMonth(widget.month);
    final alreadyAllocated = BudgetService().allocatedTotalForMonth(
      widget.month,
    );
    final remaining = (monthlyPool - alreadyAllocated).clamp(
      0.0,
      monthlyPool.toDouble(),
    );

    if (!mounted) return;
    setState(() {
      _maxAmount = remaining;
      _amount = remaining > 0 ? _amount.clamp(0.0, remaining) : 0.0;
      _isLoadingMax = false;
    });
  }

  Future<void> _handleSave() async {
    if (_selectedCategory == null) return;
    await BudgetService().addBudget(
      category: _selectedCategory!,
      limit: _amount,
      month: widget.month,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final noCategoriesLeft = _availableCategories.isEmpty;
        final assets = _selectedCategory != null
            ? _insights.getCategoryAssets(_selectedCategory!)
            : null;

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "New Budget",
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (noCategoriesLeft)
                    _buildAllCategoriesUsedNotice()
                  else ...[
                    Text(
                      "Choose Category",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      "Select the category to set the budget for",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCategorySelector(assets),
                    const SizedBox(height: 32),

                    Text(
                      "Decide Budget",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      "Set the Budget for the selected category",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isLoadingMax)
                      _buildSliderSkeleton()
                    else
                      _buildSliderSection(),
                  ],

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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CATEGORY SELECTOR — inline dropdown merged with the selector box ---
  Widget _buildCategorySelector(Map<String, dynamic>? assets) {
    final topRadius = Radius.circular(15);
    final bottomRadius = _isCategoryListVisible
        ? Radius.zero
        : Radius.circular(15);

    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isCategoryListVisible = !_isCategoryListVisible),
          child: Container(
            height: 76, // a little more breathing room top/bottom than before
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: topRadius,
                topRight: topRadius,
                bottomLeft: bottomRadius,
                bottomRight: bottomRadius,
              ),
              border: Border.all(color: AppColors.inputFill, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.iconbox,
                    borderRadius: BorderRadius.circular(9.63),
                  ),
                  child: Icon(
                    assets?['icon1'],
                    color: AppColors.colblack,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _selectedCategory ?? "",
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
                Icon(
                  _isCategoryListVisible
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.white500,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isCategoryListVisible
              ? Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.inputFill, width: 1),
                      right: BorderSide(color: AppColors.inputFill, width: 1),
                      bottom: BorderSide(color: AppColors.inputFill, width: 1),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _availableCategories.map((category) {
                      final catAssets = _insights.getCategoryAssets(category);
                      final isLast = category == _availableCategories.last;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            _isCategoryListVisible = false;
                          });
                        },
                        borderRadius: isLast
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              )
                            : BorderRadius.zero,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: AppColors.inputFill,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.iconbox,
                                  borderRadius: BorderRadius.circular(9.63),
                                ),
                                child: Icon(
                                  catAssets['icon1'],
                                  color: AppColors.colblack,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.colblack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // --- SKELETON (replaces the old CircularProgressIndicator) ---
  Widget _buildSliderSkeleton() {
    Widget bar({double height = 14, double? width}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _kBubbleHeight + _kBubbleTailHeight + _kSliderBandHeight,
          child: Center(child: bar(height: 6)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [bar(height: 14, width: 60), bar(height: 14, width: 60)],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: bar(height: 52)),
            const SizedBox(width: 12),
            Expanded(child: bar(height: 52)),
          ],
        ),
      ],
    );
  }

  void _updateAmountFromX(double localX, double trackWidth) {
    // No remaining budget.
    if (_maxAmount <= 0) {
      setState(() {
        _amount = 0;
      });
      return;
    }

    final fraction = ((localX - _kThumbOuterRadius) / trackWidth).clamp(
      0.0,
      1.0,
    );

    const step = 50.0;

    final amount = (fraction * _maxAmount / step).round() * step;

    setState(() {
      _amount = amount.clamp(0.0, _maxAmount);
    });
  }

  // --- SLIDER SECTION ---
  // Geometry note: a stock Material Slider insets its visible track by
  // exactly the thumb shape's own preferred radius at each end — since
  // _RingThumbShape reports radius _kThumbOuterRadius, the thumb's center
  // at value=min sits at exactly x=_kThumbOuterRadius from the left, and at
  // value=max sits at exactly x=(width-_kThumbOuterRadius). The start/end
  // dots and the value bubble both use that SAME formula below (not a
  // separately-guessed inset), which is what makes them land exactly where
  // the thumb actually is instead of merely close to it.
  Widget _buildSliderSection() {
    final lightGreenOpaque = Color.lerp(
      AppColors.primaryGreen,
      Colors.white,
      0.6,
    )!;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth - _kThumbOuterRadius * 2;

            final fraction = _maxAmount > 0
                ? (_amount / _maxAmount).clamp(0.0, 1.0)
                : 0.0;

            final thumbCenterX = _kThumbOuterRadius + trackWidth * fraction;

            final totalHeight =
                _kBubbleHeight + _kBubbleTailHeight + _kSliderBandHeight;

            final sliderBandTop = _kBubbleHeight + _kBubbleTailHeight;

            final thumbCenterY = sliderBandTop + _kSliderBandHeight / 2;

            final thumbTopY = thumbCenterY - _kThumbOuterRadius;

            return SizedBox(
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Start dot — the thumb will sit exactly on top of, and
                  // fully cover, this at value = 0 (same size, same center).
                  // ─────────────────────────────────────────────
                  // 1. LINE ONLY — ALWAYS AT THE BACK
                  // ─────────────────────────────────────────────
                  // ============================================================
                  // DRAGGER LINE — BACKMOST
                  // ============================================================
                  Positioned(
                    left: _kThumbOuterRadius,
                    right: _kThumbOuterRadius,
                    top: sliderBandTop + (_kSliderBandHeight - 6) / 2,
                    height: 6,
                    child: Stack(
                      children: [
                        // Full inactive line
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // Active green line.
                        // Its RIGHT EDGE is EXACTLY at thumbCenterX.
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: trackWidth * fraction,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // // ============================================================
                  // // DRAG AREA — ONLY HANDLES TOUCH
                  // // ============================================================
                  // Positioned(
                  //   left: 0,
                  //   right: 0,
                  //   top: sliderBandTop,
                  //   height: _kSliderBandHeight,
                  //   child: GestureDetector(
                  //     behavior: HitTestBehavior.opaque,

                  //     onTapDown: (details) {
                  //       final localX = details.localPosition.dx;

                  //       final newFraction =
                  //           ((localX - _kThumbOuterRadius) / trackWidth).clamp(
                  //             0.0,
                  //             1.0,
                  //           );

                  //       final step = 50.0;

                  //       final newAmount =
                  //           (newFraction * _maxAmount / step).round() * step;

                  //       setState(() {
                  //         _amount = newAmount.clamp(0.0, _maxAmount);
                  //       });
                  //     },

                  //     onHorizontalDragStart: (_) {},

                  //     onHorizontalDragUpdate: (details) {
                  //       final localX = details.localPosition.dx;

                  //       final newFraction =
                  //           ((localX - _kThumbOuterRadius) / trackWidth).clamp(
                  //             0.0,
                  //             1.0,
                  //           );

                  //       final step = 50.0;

                  //       final newAmount =
                  //           (newFraction * _maxAmount / step).round() * step;

                  //       setState(() {
                  //         _amount = newAmount.clamp(0.0, _maxAmount);
                  //       });
                  //     },

                  //     child: const SizedBox.expand(),
                  //   ),
                  // ),
                  // ─────────────────────────────────────────────
                  // 2. START CIRCLE
                  // ─────────────────────────────────────────────
                  Positioned(
                    left: 0,
                    top:
                        sliderBandTop +
                        (_kSliderBandHeight - _kThumbOuterRadius * 2) / 2,
                    child: Container(
                      width: _kThumbOuterRadius * 2,
                      height: _kThumbOuterRadius * 2,
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: _kThumbMiddleRadius * 2,
                          height: _kThumbMiddleRadius * 2,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ─────────────────────────────────────────────
                  // 3. END CIRCLE
                  // ─────────────────────────────────────────────
                  Positioned(
                    right: 0,
                    top:
                        sliderBandTop +
                        (_kSliderBandHeight - _kThumbOuterRadius * 2) / 2,
                    child: Container(
                      width: _kThumbOuterRadius * 2,
                      height: _kThumbOuterRadius * 2,
                      decoration: BoxDecoration(
                        color: AppColors.bgWhite,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: _kThumbMiddleRadius * 2,
                          height: _kThumbMiddleRadius * 2,
                          decoration: BoxDecoration(
                            color: lightGreenOpaque,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ============================================================
                  // 4. DRAG DETECTOR — ABOVE THE CIRCLES
                  // ============================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    top: sliderBandTop,
                    height: _kSliderBandHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,

                      onTapDown: (details) {
                        _updateAmountFromX(
                          details.localPosition.dx,
                          trackWidth,
                        );
                      },

                      onHorizontalDragUpdate: (details) {
                        _updateAmountFromX(
                          details.localPosition.dx,
                          trackWidth,
                        );
                      },

                      child: const SizedBox.expand(),
                    ),
                  ),

                  // ─────────────────────────────────────────────
                  // 4. MOVING CIRCLE — ALWAYS ON TOP
                  // ─────────────────────────────────────────────
                  Positioned(
                    left: thumbCenterX - _kThumbOuterRadius,
                    top: thumbCenterY - _kThumbOuterRadius,
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: Size(
                          _kThumbOuterRadius * 2,
                          _kThumbOuterRadius * 2,
                        ),
                        painter: _MovingThumbPainter(
                          outerRadius: _kThumbOuterRadius,
                          middleRadius: _kThumbMiddleRadius,
                          innerRadius: _kThumbInnerRadius,
                          lightGreenOpaque: lightGreenOpaque,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: thumbCenterX - (_kBubbleWidth / 2),
                    top: thumbTopY - _kBubbleHeight - _kBubbleTailHeight,
                    child: IgnorePointer(
                      child: _ValueBubble(text: "Rs.${_amount.round()}"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rs. 0",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
              Text(
                "Rs. ${_maxAmount.round()}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inputFill,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Save",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.inputFill,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.destructiveRed,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllCategoriesUsedNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          "Every category already has a budget set for this month.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.white500,
          ),
        ),
      ),
    );
  }
}

class _MovingThumbPainter extends CustomPainter {
  final double outerRadius;
  final double middleRadius;
  final double innerRadius;
  final Color lightGreenOpaque;

  const _MovingThumbPainter({
    required this.outerRadius,
    required this.middleRadius,
    required this.innerRadius,
    required this.lightGreenOpaque,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // OPAQUE outer ring — hides everything underneath.
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = lightGreenOpaque
        ..style = PaintingStyle.fill,
    );

    // White middle ring.
    canvas.drawCircle(
      center,
      middleRadius,
      Paint()
        ..color = AppColors.bgWhite
        ..style = PaintingStyle.fill,
    );

    // Solid green center.
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = AppColors.primaryGreen
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MovingThumbPainter oldDelegate) {
    return false;
  }
}

/// The moving thumb: three concentric, fully opaque circles — outer light
/// green, middle white, innermost solid green.
class _RingThumbShape extends SliderComponentShape {
  final double outerRadius;
  final double middleRadius;
  final double innerRadius;
  final Color lightGreenOpaque;

  const _RingThumbShape({
    required this.outerRadius,
    required this.middleRadius,
    required this.innerRadius,
    required this.lightGreenOpaque,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(outerRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Outer — light green, fully OPAQUE (no .withOpacity() — a translucent
    // ring let the track color show through underneath it, which is what
    // looked wrong before).
    canvas.drawCircle(center, outerRadius, Paint()..color = lightGreenOpaque);
    // Middle — white
    canvas.drawCircle(
      center,
      middleRadius,
      Paint()..color = AppColors.colwhite,
    );
    // Innermost — solid green
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = AppColors.primaryGreen,
    );
  }
}

/// Track-start/end marker: an outer white ring sized to match the thumb's
/// outer radius, with a solid colored center sized to match the thumb's
/// middle-ring radius. Same overall footprint as the thumb, so the thumb
/// fully covers it when the value is at that end.
class _EndDot extends StatelessWidget {
  final double outerRadius;
  final double innerRadius;
  final Color innerColor;

  const _EndDot({
    required this.outerRadius,
    required this.innerRadius,
    required this.innerColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerRadius * 2,
      height: outerRadius * 2,
      child: CustomPaint(
        painter: _EndDotPainter(
          outerRadius: outerRadius,
          innerRadius: innerRadius,
          innerColor: innerColor,
        ),
      ),
    );
  }
}

class _EndDotPainter extends CustomPainter {
  final double outerRadius;
  final double innerRadius;
  final Color innerColor;

  _EndDotPainter({
    required this.outerRadius,
    required this.innerRadius,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, outerRadius, Paint()..color = AppColors.colwhite);
    canvas.drawCircle(center, innerRadius, Paint()..color = innerColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Always-visible value bubble (not just while dragging) with a triangular
/// tail whose tip touches the thumb directly beneath it. Fixed width/height
/// so its position is exactly predictable (see _kBubbleWidth/_kBubbleHeight
/// above) and it never overflows on any screen size — the caller clamps its
/// horizontal position to stay fully on-screen.
class _ValueBubble extends StatelessWidget {
  final String text;
  const _ValueBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kBubbleWidth,
      height: _kBubbleHeight + _kBubbleTailHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _kBubbleHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ), // increased INTERNAL padding
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colwhite,
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size(12, _kBubbleTailHeight),
            painter: _BubbleTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryGreen;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
