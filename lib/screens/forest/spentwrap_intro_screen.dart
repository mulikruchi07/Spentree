import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/monthly_insights_service.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import '../../core/app_style.dart';
import 'package:spentree/screens/main_wrapper.dart';

enum WrapPhase {
  intro,
  transition,
  details,
  topSpends,
  strongestDay,
  treesGrown,
  summary,
}

class SpentWrapScreen extends StatefulWidget {
  final DateTime targetMonth;
  final int dailyLimit;

  const SpentWrapScreen({
    super.key,
    required this.targetMonth,
    required this.dailyLimit,
  });

  @override
  State<SpentWrapScreen> createState() => _SpentWrapScreenState();
}

class _SpentWrapScreenState extends State<SpentWrapScreen>
    with TickerProviderStateMixin {
  // --- Controllers for the Choreography ---
  late AnimationController _introCtrl;
  late AnimationController _exitCtrl;
  late AnimationController _remindExitCtrl;
  late AnimationController _circleCtrl;

  // Layer 3 (Details) Entry & Exit
  late AnimationController _detailsCtrl;
  late AnimationController _detailsExitCtrl;

  // Layer 4 (Top Spends) Entry
  late AnimationController _topSpendsCtrl;
  late AnimationController _topSpendsExitCtrl;

  // Layer 5 (Strongest Day) Entry
  late AnimationController _strongestDayCtrl;
  late AnimationController _strongestDayExitCtrl;

  // Layer 6 (Trees Grown) Entry
  late AnimationController _treesGrownCtrl;
  late AnimationController _treesGrownExitCtrl;

  late AnimationController _summaryCtrl;

  // The ultimate exit when clicking "Go to Forest"
  late AnimationController _finalExitCtrl;

  // 5-second timer for the progress dashes
  late AnimationController _progressCtrl;

  WrapPhase _currentPhase = WrapPhase.intro;

  // Tracks which dash is currently active/filling (0 for Details, 1 for Top Spends)
  int _activeProgressIndex = 0;
  int _maxVisitedLayer =
      0; // Tracks if a layer has been seen to prevent re-animating
  bool _isTransitioning = false; // Prevents bugs if user taps wildly
  bool _isExitingForward = false;
  DateTime? _tapDownTime;

  final List<WrapPhase> _phaseOrder = [
    WrapPhase.details,
    WrapPhase.topSpends,
    WrapPhase.strongestDay,
    WrapPhase.treesGrown,
    WrapPhase.summary,
  ];

  // // Tree Data for Layer 6
  // final List<Map<String, String>> _treeTypes = [
  //   {"name": "Dense Forest", "image": "dense_forest.png", "count": "02"},
  //   {"name": "Grand Forest", "image": "grand_forest.png", "count": "05"},
  //   {"name": "Forest", "image": "forest.png", "count": "08"},
  //   {"name": "String Tree", "image": "string_tree.png", "count": "10"},
  //   {"name": "Drying Tree", "image": "drying_tree.png", "count": "04"},
  //   {"name": "Dry Tree", "image": "dry_tree.png", "count": "02"},
  // ];

  // late List<Map<String, dynamic>> _sortedCategories;
  // final List<Map<String, dynamic>> _rawCategoryData = [
  //   {"name": "Food & Beverages", "amount": 30000},
  //   {"name": "Shopping", "amount": 1500},
  //   {"name": "To People", "amount": 1500},
  //   {"name": "Fuel", "amount": 7000},
  //   {"name": "Recharge", "amount": 6000},
  //   {"name": "Other", "amount": 2000},
  // ];
  // final List<Color> _greenPalette = [
  //   const Color(0xFF005A32),
  //   const Color(0xFF238B45),
  //   const Color(0xFF41AB5D),
  //   const Color(0xFF74C476),
  //   const Color(0xFFA1D99B),
  //   const Color(0xFFC7E9C0),
  // ];

  final MonthlyInsightsService _insights = MonthlyInsightsService();

  // DYNAMIC DATA
  late String _monthName;
  late Map<String, dynamic> _forestStats;
  late ForestStatus _forestStatus;
  late List<Map<String, dynamic>> _allCategories;
  late List<Map<String, dynamic>> _topCategories;
  late List<LocalTransaction> _topTransactions;
  late Map<String, dynamic> _strongestDayData;
  late Map<String, dynamic> _categoryAssets;
  late double _totalExpense;
  late List<Map<String, dynamic>> _sortedCategories;

  @override
  void initState() {
    super.initState();
    _loadDynamicData();

    // 1. Intro Entry Animation (1.4s)
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Intro Exit Animation (When checkout is clicked)
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _remindExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 3. White Circle Drop & Expand Transition
    _circleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 4. Details Screen Entry Animation
    _detailsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // NEW: Details Screen Exit Animation
    _detailsExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Smooth 1s exit
    );

    // NEW: Top Spends Screen Entry Animation
    _topSpendsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _topSpendsExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 4. Layer 5 (Strongest Day)
    _strongestDayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _strongestDayExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 5. Layer 6 (Trees Grown)
    _treesGrownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _treesGrownExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _summaryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _finalExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 5-Second Progress Bar Timer
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Entry triggers the timer
    _detailsCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _progressCtrl.forward();
    });

    // Auto-Advance Logic
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isTransitioning) {
        if (_activeProgressIndex < 4) {
          _navigateLayer(_activeProgressIndex + 1, isAutoAdvance: true);
        }
      }
    });

    // Initial 2.5 second delay so the user reads "SPENTWRAP"
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _introCtrl.forward();
    });
  }

  // void _processCategoryData() {
  //   _sortedCategories = List.from(_rawCategoryData);
  //   _sortedCategories.sort(
  //     (a, b) => (b['amount'] as int).compareTo(a['amount'] as int),
  //   );
  //   for (int i = 0; i < _sortedCategories.length; i++) {
  //     _sortedCategories[i]['color'] = _greenPalette[i % _greenPalette.length];
  //   }
  // }

  void _loadDynamicData() {
    _monthName = DateFormat('MMMM').format(widget.targetMonth);

    // Total & Status
    _totalExpense = _insights.getTotalMonthlyExpense(widget.targetMonth);
    int monthlyBudget =
        widget.dailyLimit * _insights.daysInMonth(widget.targetMonth);
    double pct = monthlyBudget > 0
        ? ((monthlyBudget - _totalExpense).clamp(0, monthlyBudget) /
              monthlyBudget)
        : 0;
    _forestStatus = getForestStatusForPercentage(pct);

    // Forest / Trees
    _forestStats = _insights.computeForestStats(
      widget.targetMonth,
      widget.dailyLimit,
    );

    // Categories
    _allCategories = _insights.computeCategorySpends(
      widget.targetMonth,
      forceAll: true,
    );
    _topCategories = _insights.computeCategorySpends(
      widget.targetMonth,
    ); // Excludes 0 amounts

    _sortedCategories = _allCategories;

    // Assets based on #1 category
    String topCatName = _topCategories.isNotEmpty
        ? _topCategories.first['name']
        : "Other";
    _categoryAssets = _insights.getCategoryAssets(topCatName);

    // Top 3 TX
    final daysInMonth = _insights.daysInMonth(widget.targetMonth);
    final List<LocalTransaction> allTx = [];
    for (int day = 1; day <= daysInMonth; day++) {
      allTx.addAll(
        TransactionService().getTransactionsForDay(
          DateTime(widget.targetMonth.year, widget.targetMonth.month, day),
        ),
      );
    }
    allTx.sort((a, b) => b.amount.compareTo(a.amount));
    _topTransactions = allTx.take(3).toList();

    // Strongest Day
    _strongestDayData =
        _insights.getStrongestDay(widget.targetMonth, widget.dailyLimit) ??
        {
          "day": 1,
          "date": widget.targetMonth,
          "expense": 0.0,
          "percentage": 100,
          "treeStatus": "Dense Forest",
        };
  }

  // --- DYNAMIC TEXT TIP GENERATOR ---
  String _getCategoryTip(String categoryName) {
    String lower = categoryName.toLowerCase();
    if (lower.contains("food") || lower.contains("beverage"))
      return "Maybe you should join\ncooking classes";
    if (lower.contains("shop")) return "Window shopping?\nNever heard of it";
    if (lower.contains("people")) return "You made someone’s\nday this month.";
    if (lower.contains("fuel") || lower.contains("transport"))
      return "Your vehicle eats petrol\nfor breakfast.";
    if (lower.contains("bill") || lower.contains("recharge"))
      return "Subscriptions survived\nanother month.";
    return "Mysterious spending\ndetected.";
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _exitCtrl.dispose();
    _circleCtrl.dispose();
    _detailsCtrl.dispose();
    _detailsExitCtrl.dispose();
    _topSpendsCtrl.dispose();
    _topSpendsExitCtrl.dispose();
    _strongestDayCtrl.dispose();
    _strongestDayExitCtrl.dispose();
    _treesGrownCtrl.dispose();
    _treesGrownExitCtrl.dispose();
    _summaryCtrl.dispose();
    _finalExitCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // --- SMART TAP & AUTO-ADVANCE NAVIGATION ENGINE ---
  AnimationController _getEntryCtrl(int index) {
    switch (index) {
      case 0:
        return _detailsCtrl;
      case 1:
        return _topSpendsCtrl;
      case 2:
        return _strongestDayCtrl;
      case 3:
        return _treesGrownCtrl;
      case 4:
        return _summaryCtrl;
      default:
        return _detailsCtrl;
    }
  }

  AnimationController _getExitCtrl(int index) {
    switch (index) {
      case 0:
        return _detailsExitCtrl;
      case 1:
        return _topSpendsExitCtrl;
      case 2:
        return _strongestDayExitCtrl;
      case 3:
        return _treesGrownExitCtrl;
      case 4:
        return _finalExitCtrl;
      default:
        return _detailsExitCtrl;
    }
  }

  void _navigateLayer(int newIndex, {bool isAutoAdvance = false}) {
    if (_isTransitioning) return;
    _progressCtrl.stop();

    bool isFirstTime = newIndex > _maxVisitedLayer;
    _isExitingForward = newIndex > _activeProgressIndex;

    if (isFirstTime) {
      // PLAY SMOOTH EXIT/ENTRY ANIMATION ONLY ONCE
      _isTransitioning = true;
      _getExitCtrl(_activeProgressIndex).forward().then((_) {
        _getEntryCtrl(_activeProgressIndex).reset();
        _getExitCtrl(_activeProgressIndex).reset();

        setState(() {
          _activeProgressIndex = newIndex;
          _currentPhase = _phaseOrder[newIndex];
          _maxVisitedLayer = newIndex;
        });

        _progressCtrl.reset();
        _isExitingForward = false;

        _getEntryCtrl(newIndex).forward().then((_) {
          _isTransitioning = false;
          _progressCtrl.forward();
        });
      });
    } else {
      // ALREADY VISITED: INSTANT SNAP (No animation)
      _getEntryCtrl(_activeProgressIndex).reset();
      _getExitCtrl(_activeProgressIndex).reset();

      setState(() {
        _activeProgressIndex = newIndex;
        _currentPhase = _phaseOrder[newIndex];
      });

      _getEntryCtrl(newIndex).value = 1.0; // Instantly place layer on screen
      _progressCtrl.reset();
      _isExitingForward = false;
      _progressCtrl.forward();
    }
  }
  // // --- GESTURE LOGIC (PAUSE / TAP LEFT / TAP RIGHT) ---
  // void _handleTapDown(TapDownDetails details) {
  //   if (_currentPhase != WrapPhase.intro &&
  //       _currentPhase != WrapPhase.transition) {
  //     _tapDownTime = DateTime.now();
  //     _progressCtrl.stop(); // Pause the bar instantly
  //   }
  // }

  // void _handleTapUp(TapUpDetails details, double screenWidth) {
  //   if (_currentPhase == WrapPhase.intro ||
  //       _currentPhase == WrapPhase.transition)
  //     return;

  //   final tapDuration = DateTime.now().difference(_tapDownTime!);

  //   // If held for less than 200ms, it's a tap. Otherwise, it was a hold.
  //   if (tapDuration.inMilliseconds < 200) {
  //     if (details.globalPosition.dx < screenWidth / 2) {
  //       // Tapped Left
  //       if (_activeProgressIndex > 0) _navigateLayer(_activeProgressIndex - 1);
  //     } else {
  //       // Tapped Right
  //       if (_activeProgressIndex < 4) _navigateLayer(_activeProgressIndex + 1);
  //     }
  //   } else {
  //     // User let go after a long press, resume the bar smoothly
  //     if (!_isTransitioning) _progressCtrl.forward();
  //   }
  // }

  // --- TRANSITIONS TO FOREST PAGE ---
  void _startCheckoutTransition() {
    _isTransitioning = true;
    _exitCtrl.forward().then((_) {
      setState(() => _currentPhase = WrapPhase.transition);
      _circleCtrl.forward().then((_) {
        setState(() {
          _currentPhase = WrapPhase.details;
          _activeProgressIndex = 0;
          _maxVisitedLayer = 0;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _detailsCtrl.forward().then((_) {
              _isTransitioning = false;
              _progressCtrl.forward();
            });
          }
        });
      });
    });
  }

  void _remindMeLaterTransition() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _progressCtrl.stop();
    _remindExitCtrl.forward().then((_) {
      _triggerStandardNavigation();
    });
  }

  void _goToForestFinalTransition() {
    if (_isTransitioning) return;
    _isTransitioning = true;
    _progressCtrl.stop();
    _finalExitCtrl.forward().then((_) async {
      await _insights.markWrapAsViewed(widget.targetMonth); // MARK AS READ!
      _triggerStandardNavigation();
    });
  }

  // FIXED: Restores MainWrapper (Navbar & Swipe logic) with a smooth Fade!
  void _triggerStandardNavigation() {
    // Navigator.pushReplacement(
    //   context,
    //   PageRouteBuilder(
    //     // Pass the index of your Forest tab here (e.g., 1, 2, or 3 depending on your navbar order)
    //     pageBuilder: (context, animation, secondaryAnimation) =>
    //         const MainWrapper(initialIndex: 2),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(opacity: animation, child: child);
    //     },
    //     transitionDuration: const Duration(
    //       milliseconds: 800,
    //     ), // Smooth 0.8s fade
    //   ),
    // );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainWrapper(
          initialIndex: 2,
        ), // <-- UPDATE THIS to your main wrapper class name if different!
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topTextCenterY = screenHeight * 0.100;

    return Scaffold(
      backgroundColor:
          _currentPhase == WrapPhase.intro ||
              _currentPhase == WrapPhase.transition
          ? AppColors.primaryGreen
          : AppColors.bgWhite,
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_currentPhase != WrapPhase.intro &&
              _currentPhase != WrapPhase.transition) {
            _tapDownTime = DateTime.now();
            _progressCtrl.stop(); // Instantly pause exactly where it is
          }
        },
        onPointerUp: (event) {
          if (_currentPhase == WrapPhase.intro ||
              _currentPhase == WrapPhase.transition)
            return;

          final tapDuration = DateTime.now().difference(_tapDownTime!);
          if (tapDuration.inMilliseconds < 250) {
            // It's a quick tap
            if (event.position.dx < screenWidth / 2) {
              if (_activeProgressIndex > 0)
                _navigateLayer(_activeProgressIndex - 1);
            } else {
              if (_activeProgressIndex < 4)
                _navigateLayer(_activeProgressIndex + 1);
            }
          } else {
            // It was a long press hold. Resume!
            if (!_isTransitioning) _progressCtrl.forward();
          }
        },
        onPointerCancel: (event) {
          if (_currentPhase != WrapPhase.intro &&
              _currentPhase != WrapPhase.transition &&
              !_isTransitioning) {
            _progressCtrl.forward();
          }
        },
        child: Stack(
          children: [
            // ==========================================
            // LAYER 1: INTRO SCREEN (Only visible initially)
            // ==========================================
            if (_currentPhase == WrapPhase.intro ||
                _currentPhase == WrapPhase.transition)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _introCtrl,
                  _exitCtrl,
                  _remindExitCtrl,
                ]),
                builder: (context, child) {
                  final intro = Curves.easeOutCubic.transform(_introCtrl.value);
                  final exit = Curves.easeIn.transform(_exitCtrl.value);
                  final remindExit = Curves.easeIn.transform(
                    _remindExitCtrl.value,
                  );

                  // Both CheckOut and Remind exits fade the background/trees
                  final val = intro * (1 - exit) * (1 - remindExit);

                  // Both exits slide the center card down
                  final exitDownVal = (intro - exit - remindExit).clamp(
                    0.0,
                    1.0,
                  );

                  final double treeWidth = screenWidth * 0.55;
                  final double forestWidth = screenWidth * 1.45;

                  return Stack(
                    children: [
                      // --- Hollow "WRAP" Texts ---
                      Positioned(
                        top: screenHeight * 0.20,
                        left: lerpDouble(
                          -screenWidth,
                          -screenWidth * 0.25,
                          val,
                        ),
                        child: Opacity(
                          opacity: val,
                          child: _buildHollowText(screenWidth),
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight * 0.16,
                        right: lerpDouble(
                          -screenWidth,
                          -screenWidth * 0.10,
                          val,
                        ),
                        child: Opacity(
                          opacity: val,
                          child: _buildHollowText(screenWidth),
                        ),
                      ),

                      // --- 2. Floating 3D Assets ---
                      Positioned(
                        top: screenHeight * 0.15,
                        right: lerpDouble(-treeWidth, -(treeWidth * 0.50), val),
                        width: treeWidth,
                        child: Opacity(
                          opacity: val,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/${_forestStats["dominantTreeImage"]}',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -screenHeight * 0.002,
                        left: lerpDouble(
                          -forestWidth,
                          -(forestWidth * 0.60),
                          val,
                        ),
                        width: forestWidth,
                        child: Opacity(
                          opacity: val,
                          child: Image.asset(
                            'assets/images/forest/${_forestStatus.image}',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // --- Center Data Card ---
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            (screenHeight * 1.2) * (1 - exitDownVal),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15.0,
                                    sigmaY: 15.0,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      screenWidth * 0.035,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.40),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.03,
                                          ),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            PhosphorIconsRegular
                                                .presentationChart,
                                            color: AppColors.colwhite,
                                            size: screenWidth * 0.1,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.02),
                                        Text(
                                          "$_monthName Spentwrap",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: screenWidth * 0.055,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.colwhite,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          "See your performance in the\nlast month",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.colwhite
                                                .withOpacity(0.46),
                                            height: 1.4,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.02),

                                        // Checkout Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: screenHeight * 0.06,
                                          child: ElevatedButton(
                                            onPressed: _startCheckoutTransition,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryGreen,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              "Checkout",
                                              style: GoogleFonts.montserrat(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.colwhite,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.01),

                                        // Remind me later Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: screenHeight * 0.06,
                                          child: OutlinedButton(
                                            onPressed: _remindMeLaterTransition,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: AppColors.colwhite
                                                    .withOpacity(1),
                                                width: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              "Remind me later",
                                              style: GoogleFonts.montserrat(
                                                fontSize: screenWidth * 0.04,
                                                fontWeight: FontWeight.w500,
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
                          ),
                        ),
                      ),

                      // --- SPENTWRAP Title ---
                      Align(
                        alignment: Alignment(
                          0,
                          lerpDouble(0.0, -0.70, intro)! -
                              lerpDouble(0.0, 1.5, remindExit)!,
                        ),
                        child: Opacity(
                          opacity: (1.0 - remindExit).clamp(0.0, 1.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "SPENTWRAP",
                              style: TextStyle(
                                fontFamily: 'CalcioDemo',
                                fontSize: lerpDouble(
                                  screenWidth * 0.2,
                                  screenWidth * 0.15,
                                  intro,
                                ),
                                color: AppColors.colwhite,
                                letterSpacing: 2.0,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // ==========================================
            // LAYER 2: CIRCLE TRANSITION
            // ==========================================
            if (_currentPhase == WrapPhase.transition)
              AnimatedBuilder(
                animation: _circleCtrl,
                builder: (context, child) {
                  final circleVal = _circleCtrl.value;

                  double dropProgress = Curves.easeOutCubic.transform(
                    (circleVal / 0.5).clamp(0.0, 1.0),
                  );
                  double expandProgress = Curves.easeInCirc.transform(
                    ((circleVal - 0.5) / 0.5).clamp(0.0, 1.0),
                  );

                  double circleY = lerpDouble(
                    topTextCenterY + 40,
                    screenHeight / 2,
                    dropProgress,
                  )!;
                  double scale = lerpDouble(
                    1.0,
                    screenHeight * 0.1,
                    expandProgress,
                  )!;

                  return Positioned(
                    top: circleY - 10,
                    left: screenWidth / 2 - 10,
                    child: Opacity(
                      opacity: dropProgress,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.colwhite,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ==========================================
            // HEADER & PROGRESS BAR (PERSISTENT ACROSS LAYER 3 & 4)
            // ==========================================
            // if (_currentPhase != WrapPhase.intro && _currentPhase != WrapPhase.transition)
            if (_currentPhase != WrapPhase.intro &&
                _currentPhase != WrapPhase.transition)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _detailsCtrl,
                  _progressCtrl,
                  _finalExitCtrl,
                ]),
                builder: (context, child) {
                  // Header ONLY animates in during the initial details entry.
                  // It stays at value 1.0 permanently after that.
                  final dVal = _activeProgressIndex == 0
                      ? Curves.easeOutCubic.transform(_detailsCtrl.value)
                      : 1.0;
                  final pVal = _progressCtrl.value;
                  final finalExit = Curves.easeInCubic.transform(
                    _finalExitCtrl.value,
                  );

                  return SafeArea(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        lerpDouble(-screenHeight * 0.3, 0, dVal)! +
                            lerpDouble(0, -screenHeight * 0.3, finalExit)!,
                      ),
                      child: Opacity(
                        opacity: 1.0 - finalExit,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: screenHeight * 0.05),
                            Text(
                              "$_monthName Spentwrap",
                              style: GoogleFonts.montserrat(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colblack,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                // Logic to fill the progress bar left-to-right over 5 seconds
                                double fillPercent = 0.0;
                                if (index < _activeProgressIndex) {
                                  fillPercent = 1.0; // Fully filled past bars
                                } else if (index == _activeProgressIndex) {
                                  fillPercent = pVal; // Currently filling bar
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: screenWidth * 0.1,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: fillPercent,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ==========================================
            // LAYER 3: DETAILS SCREEN (Biggest Spending Zone)
            // ==========================================
            if (_currentPhase == WrapPhase.details)
              AnimatedBuilder(
                animation: Listenable.merge([_detailsCtrl, _detailsExitCtrl]),
                builder: (context, child) {
                  // Intro is 0 to 1, Exit is 0 to 1
                  final intro = Curves.easeOutCubic.transform(
                    _detailsCtrl.value,
                  );
                  final exit = Curves.easeInCubic.transform(
                    _detailsExitCtrl.value,
                  );

                  // Active Val for sliding elements: Combines entry (0->1) and exit (1->0)
                  final dVal = intro * (1 - exit);
                  final linearVal =
                      _detailsCtrl.value * (1 - _detailsExitCtrl.value);

                  if (exit == 1.0) return const SizedBox.shrink();

                  return Stack(
                    children: [
                      Positioned(
                        top: screenHeight * 0.12,
                        left: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.15,
                          dVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, 14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/${_categoryAssets["img1"]}', // Use img2 for the second one
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight * 0.12,
                        right: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.15,
                          dVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, -14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/${_categoryAssets["img2"]}', // Use img2 for the second one
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),

                      SafeArea(
                        child: Column(
                          children: [
                            // Invisible placeholder to push content exactly below the persistent header
                            _buildInvisibleHeaderSpacer(
                              screenWidth,
                              screenHeight,
                            ),

                            SizedBox(height: screenHeight * 0.12),

                            // Biggest Spending Zone Text (Slides DOWN initially, slides UP on exit)
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(-screenHeight * 0.6, 0, intro)! +
                                    lerpDouble(0, -screenHeight * 0.6, exit)!,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Your ",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "BIGGEST\n",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.1,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "spending zone",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.08),

                            // --- Center Data Box & Icons ---
                            Align(
                              alignment: Alignment.center,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  // Top Right Green Box (Slides left/right on entry/exit)
                                  Positioned(
                                    top: -26,
                                    right: -40,
                                    child: Transform.translate(
                                      offset: Offset(
                                        lerpDouble(screenWidth * 0.5, 0, dVal)!,
                                        0,
                                      ),
                                      child: Transform.rotate(
                                        angle: lerpDouble(
                                          0,
                                          21.47 * math.pi / 180,
                                          linearVal,
                                        )!,
                                        child: _buildGreenIconBox(
                                          _categoryAssets["icon1"], // Use icon2 for the second one
                                          screenWidth,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Left Green Box (Slides left/right on entry/exit)
                                  Positioned(
                                    bottom: -16,
                                    left: -40,
                                    child: Transform.translate(
                                      offset: Offset(
                                        lerpDouble(
                                          -screenWidth * 0.5,
                                          0,
                                          dVal,
                                        )!,
                                        0,
                                      ),
                                      child: Transform.rotate(
                                        angle: lerpDouble(
                                          0,
                                          -25.87 * math.pi / 180,
                                          linearVal,
                                        )!,
                                        child: _buildGreenIconBox(
                                          _categoryAssets["icon2"], // Use icon2 for the second one
                                          screenWidth,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // --- THE ACTUAL BLURRED DATA BOX ---
                                  Transform.translate(
                                    offset: Offset(
                                      0,
                                      // Slides UP on entry, DOWN on exit
                                      lerpDouble(screenHeight * 1.2, 0, dVal)!,
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.65,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(19),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(19),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 5.0,
                                            sigmaY: 5.0,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: screenHeight * 0.03,
                                              horizontal: screenWidth * 0.05,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.colwhite
                                                  .withOpacity(0.60),
                                              borderRadius:
                                                  BorderRadius.circular(19),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .center, // Ensures center alignment
                                              children: [
                                                // FIXED: Wrapped in FittedBox to guarantee single-line fit
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "${_topCategories.isNotEmpty ? _topCategories.first['name'] : 'Other'} - ₹${NumberFormat('#,##0').format(_topCategories.isNotEmpty ? _topCategories.first['amount'] : 0)}",
                                                    textAlign: TextAlign.center,
                                                    maxLines:
                                                        1, // Prevents wrapping to the next line
                                                    style:
                                                        GoogleFonts.montserrat(
                                                          fontSize:
                                                              screenWidth *
                                                              0.06,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .colblack,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.015,
                                                ),
                                                Text(
                                                  "That's ${_totalExpense > 0 && _topCategories.isNotEmpty ? ((_topCategories.first['amount'] / _totalExpense) * 100).toInt() : 0}% of your total\nspending.",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.montserrat(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.subtext,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.12),

                            // Bottom Tip
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(screenHeight * 1.2, 0, dVal)!,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: screenHeight * 0.1,
                                ),
                                child: Text(
                                  _getCategoryTip(
                                    _topCategories.isNotEmpty
                                        ? _topCategories.first['name']
                                        : 'Other',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.subtext,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

            // ==========================================
            // LAYER 4: NEW TOP SPENDS SCREEN
            // ==========================================
            if (_currentPhase == WrapPhase.topSpends)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _topSpendsCtrl,
                  _topSpendsExitCtrl,
                ]),
                builder: (context, child) {
                  final intro = Curves.easeOutCubic.transform(
                    _topSpendsCtrl.value,
                  );
                  final exit = Curves.easeInCubic.transform(
                    _topSpendsExitCtrl.value,
                  );

                  final tVal = intro * (1 - exit);
                  final linearVal =
                      _topSpendsCtrl.value * (1 - _topSpendsExitCtrl.value);

                  if (exit == 1.0) return const SizedBox.shrink();

                  return Stack(
                    children: [
                      // Floating Images rendered behind the content so they don't block the list
                      Positioned(
                        top: screenHeight * 0.12,
                        left: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.13,
                          tVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, 14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/cash.png',
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight * 0.12,
                        right: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.13,
                          tVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, -14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/bag.png',
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),

                      SafeArea(
                        child: Column(
                          children: [
                            _buildInvisibleHeaderSpacer(
                              screenWidth,
                              screenHeight,
                            ),

                            // Exactly matching Layer 3's height gap for perfect replacement
                            SizedBox(height: screenHeight * 0.16),

                            // Header Text
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(-screenHeight * 0.6, 0, tVal)!,
                              ),
                              child: Text(
                                "Your top spends were",
                                style: GoogleFonts.montserrat(
                                  fontSize: screenWidth * 0.065,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.colblack,
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.05),

                            // Transaction Cards List
                            Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  lerpDouble(screenHeight * 1.2, 0, tVal)!,
                                ),
                                child: Container(
                                  width: screenWidth * 0.85,
                                  child: Column(
                                    children: _topTransactions.isEmpty
                                        ? [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: screenHeight * 0.05,
                                              ),
                                              child: Text(
                                                "No transactions recorded for this month.",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.montserrat(
                                                  color: AppColors.subtext,
                                                  fontSize: screenWidth * 0.04,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : _topTransactions
                                              .map(
                                                (tx) => _buildTransactionCard(
                                                  tx.receiverName,
                                                  (tx.type == 'Cash')
                                                      ? "Cash"
                                                      : "Bank account",
                                                  "- Rs. ${NumberFormat('#,##0').format(tx.amount)}",
                                                  DateFormat(
                                                    'E, d MMMM yyyy',
                                                  ).format(tx.dateTime),
                                                  TransactionService()
                                                      .getIconForCategory(
                                                        tx.category,
                                                      ),
                                                  screenWidth,
                                                  screenHeight,
                                                ),
                                              )
                                              .toList(),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // Bottom Tip
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(screenHeight * 1.2, 0, tVal)!,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: screenHeight * 0.1,
                                ),
                                child: Text(
                                  "Going early to bed can be a\nsolution for this!",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.subtext,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            // ==========================================
            // LAYER 5: STRONGEST DAY SCREEN
            // ==========================================
            if (_currentPhase == WrapPhase.strongestDay)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _strongestDayCtrl,
                  _strongestDayExitCtrl,
                ]),
                builder: (context, child) {
                  final intro = Curves.easeOutCubic.transform(
                    _strongestDayCtrl.value,
                  );
                  final exit = Curves.easeInCubic.transform(
                    _strongestDayExitCtrl.value,
                  );
                  final sVal = intro * (1 - exit);
                  final linearVal =
                      _strongestDayCtrl.value *
                      (1 - _strongestDayExitCtrl.value);
                  if (exit == 1.0) return const SizedBox.shrink();

                  return Stack(
                    children: [
                      // Floating Images (Calendar & Trophy)
                      Positioned(
                        top: screenHeight * 0.12,
                        left: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.15,
                          sVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, 14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/calendar.png',
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight * 0.12,
                        right: lerpDouble(
                          -screenWidth * 0.5,
                          -screenWidth * 0.15,
                          sVal,
                        ),
                        child: Transform.rotate(
                          angle: lerpDouble(0, -14 * math.pi / 180, linearVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/trophy.png',
                            width: screenWidth * 0.35,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                            _buildInvisibleHeaderSpacer(
                              screenWidth,
                              screenHeight,
                            ),
                            SizedBox(height: screenHeight * 0.16),

                            // Header Text
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(-screenHeight * 0.6, 0, sVal)!,
                              ),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Your ",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.060,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Strongest ",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.070,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "day",
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenWidth * 0.060,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.colblack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.04),

                            // Calendar Box
                            Align(
                              alignment: Alignment.center,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  lerpDouble(screenHeight * 1.2, 0, sVal)!,
                                ),
                                child: _buildCalendarCard(
                                  screenWidth: screenWidth,
                                  year: widget.targetMonth.year,
                                  month: widget.targetMonth.month,
                                  activeDay: _strongestDayData["day"],
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // Bottom Tip
                            Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(screenHeight * 1.2, 0, sVal)!,
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: screenHeight * 0.1,
                                ),
                                child: Text(
                                  "You spent only ${_strongestDayData["percentage"]}% of your\ndaily limit.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.subtext,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

            // ==========================================
            // LAYER 6: TREES GROWN SCREEN (NEW)
            // ==========================================
            if (_currentPhase == WrapPhase.treesGrown)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _treesGrownCtrl,
                  _treesGrownExitCtrl,
                ]),
                builder: (context, child) {
                  final intro = Curves.easeOutCubic.transform(
                    _treesGrownCtrl.value,
                  );
                  final exit = Curves.easeInCubic.transform(
                    _treesGrownExitCtrl.value,
                  );

                  if (exit == 1.0) return const SizedBox.shrink();

                  return SafeArea(
                    child: Column(
                      children: [
                        _buildInvisibleHeaderSpacer(screenWidth, screenHeight),
                        // Reduced gap to match your UI image exactly
                        SizedBox(height: screenHeight * 0.07),

                        // Header Text (Slides down from top)
                        Transform.translate(
                          offset: Offset(
                            0,
                            lerpDouble(-screenHeight * 0.6, 0, intro)! +
                                lerpDouble(0, -screenHeight * 0.6, exit)!,
                          ),
                          child: Text(
                            "You planted '${_forestStats["totalTreesGrown"]} Trees'",
                            style: GoogleFonts.montserrat(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colblack,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.01),

                        // FittedBox ensures it scales cleanly on small screens without overflow or scrolling
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment:
                                Alignment.topCenter, // <--- ADD THIS LINE HERE
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                lerpDouble(screenHeight * 1.2, 0, intro)! +
                                    lerpDouble(0, screenHeight * 1.2, exit)!,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Full Forest Image exactly as provided
                                  // 1. Full Forest Image with 60% Bottom Background Box
                                  SizedBox(
                                    width: screenWidth * 0.85,
                                    height:
                                        screenHeight *
                                        0.26, // Gives the stack a constrained height
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Background Box: Anchored to bottom, exactly 60% height
                                        FractionallySizedBox(
                                          heightFactor: 0.60,
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: _forestStatus.color,
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                            ),
                                          ),
                                        ),
                                        // Tree Image: Anchored to bottom, pokes out top of the box
                                        Image.asset(
                                          'assets/images/forest/${_forestStatus.image}',
                                          height:
                                              screenHeight *
                                              0.28, // Taller than the box
                                          fit: BoxFit.contain,
                                          alignment: Alignment.bottomCenter,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),

                                  // 2. White List Box
                                  Container(
                                    width: screenWidth * 0.85,
                                    padding: EdgeInsets.all(screenWidth * 0.05),
                                    margin: EdgeInsets.only(
                                      bottom: screenHeight * 0.04,
                                    ), // Breathing room at the bottom
                                    decoration: BoxDecoration(
                                      color: AppColors.colwhite,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: (_forestStats["treeCounts"] as List)
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            int idx = entry.key;
                                            var tree = entry.value;
                                            bool isLast =
                                                idx ==
                                                (_forestStats["treeCounts"]
                                                            as List)
                                                        .length -
                                                    1;

                                            return Padding(
                                              // Tightened spacing to match the UI image
                                              padding: EdgeInsets.only(
                                                bottom: isLast
                                                    ? 0
                                                    : screenHeight * 0.015,
                                              ),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/forest/${tree['image']}",
                                                    width: screenWidth * 0.08,
                                                    height: screenWidth * 0.08,
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.03,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      tree['name']!,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                            fontSize:
                                                                screenWidth *
                                                                0.035,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .colblack,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    "- ${tree['count']}",
                                                    style:
                                                        GoogleFonts.montserrat(
                                                          fontSize:
                                                              screenWidth *
                                                              0.035,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: AppColors
                                                              .colblack,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            // ==========================================
            // LAYER 7: SUMMARY SCREEN (GRAND FINALE)
            // ==========================================
            if (_currentPhase == WrapPhase.summary)
              AnimatedBuilder(
                animation: Listenable.merge([_summaryCtrl, _finalExitCtrl]),
                builder: (context, child) {
                  final intro = Curves.easeOutCubic.transform(
                    _summaryCtrl.value,
                  );
                  final exit = Curves.easeInCubic.transform(
                    _finalExitCtrl.value,
                  );

                  return Opacity(
                    // Fade out the entire layer during final transition
                    opacity: (1.0 - exit).clamp(0.0, 1.0),
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildInvisibleHeaderSpacer(
                            screenWidth,
                            screenHeight,
                          ),
                          SizedBox(height: screenHeight * 0.05),

                          // Header Text
                          Transform.translate(
                            // On exit, text slides UP
                            offset: Offset(
                              0,
                              lerpDouble(-screenHeight * 0.6, 0, intro)! +
                                  lerpDouble(0, -screenHeight * 0.6, exit)!,
                            ),
                            child: Text(
                              "$_monthName's Summary",
                              style: GoogleFonts.montserrat(
                                fontSize:
                                    screenWidth *
                                    0.060, // Exact 0.06 sizing required
                                fontWeight:
                                    FontWeight.w600, // 600 weight required
                                color: AppColors.colblack,
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          Expanded(
                            // Using FittedBox + Constrained width ensures NO scrolling, perfectly scaling to fit any screen!
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                // Main content slides UP on entry, DOWN on final exit
                                offset: Offset(
                                  0,
                                  lerpDouble(screenHeight * 1.2, 0, intro)! +
                                      lerpDouble(0, screenHeight * 1.2, exit)!,
                                ),
                                child: SizedBox(
                                  width:
                                      screenWidth *
                                      0.85, // Enforces exact layout constraint for internal elements
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSummaryCard(
                                        "$_monthName's Expense",
                                        "Rs. ${NumberFormat('#,##0').format(_totalExpense)}",
                                        screenWidth,
                                        screenHeight,
                                        isExpense: true,
                                        forestStatus: _forestStatus,
                                      ),
                                      SizedBox(height: screenHeight * 0.015),
                                      _buildSummaryCard(
                                        "Average Daily Expense",
                                        "Rs. ${NumberFormat('#,##0').format(_totalExpense / _insights.daysInMonth(widget.targetMonth))} / ${NumberFormat('#,##0').format(widget.dailyLimit)}",
                                        screenWidth,
                                        screenHeight,
                                      ),

                                      SizedBox(height: screenHeight * 0.03),
                                      _buildMultiSegmentProgressBar(
                                        screenWidth,
                                      ),
                                      SizedBox(height: screenHeight * 0.03),
                                      _buildCategoryList(
                                        screenWidth,
                                        screenHeight,
                                      ),

                                      SizedBox(height: screenHeight * 0.04),

                                      // Go To Forest Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: screenHeight * 0.065,
                                        child: ElevatedButton(
                                          onPressed: _goToForestFinalTransition,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            "Go to Forest",
                                            style: GoogleFonts.montserrat(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.colwhite,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: screenHeight * 0.05,
                                      ), // Bottom padding
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  // --- Helper Widgets ---

  // Perfectly reserves the space of the persistent header so Layer 3 & 4 content align properly
  Widget _buildInvisibleHeaderSpacer(double screenWidth, double screenHeight) {
    return Opacity(
      opacity: 0.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: screenHeight * 0.05),
          Text(
            "$_monthName Spentwrap",
            style: GoogleFonts.montserrat(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Container(height: 5), // Dash height
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    String title,
    String subtitle,
    String amount,
    String date,
    IconData icon,
    double screenWidth,
    double screenHeight, {
    bool isIncome = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.016),
      width: double.infinity,
      // FIXED: Used BoxConstraints instead of fixed height so inner paddings respond cleanly
      constraints: BoxConstraints(minHeight: screenHeight * 0.084),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            // Responsive box width/height
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
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
              icon,
              color: AppColors.colwhite,
              // Responsive icon size
              size: screenWidth * 0.055,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtext,
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
                amount,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
              ),
              SizedBox(height: 2),
              Text(
                date,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.025,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Responsive Box
  Widget _buildGreenIconBox(IconData icon, double screenWidth) {
    return Container(
      width: screenWidth * 0.14, // Responsive box size
      height: screenWidth * 0.14,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: PhosphorIcon(
          icon,
          color: AppColors.colwhite,
          size: screenWidth * 0.08,
        ),
      ), // Responsive icon size
    );
  }

  // --- Dynamic Calendar Engine ---
  Widget _buildCalendarCard({
    required double screenWidth,
    required int year,
    required int month,
    required int activeDay,
  }) {
    final daysOfWeek = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    // Core DateTime Math for generating the grid
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int daysInMonth = DateTime(
      year,
      month + 1,
      0,
    ).day; // Hack to get last day of month
    int firstWeekday = firstDayOfMonth.weekday; // Monday = 1, Sunday = 7

    List<String> calendarSlots = [];

    // 1. Add empty strings for offset days before the 1st
    for (int i = 1; i < firstWeekday; i++) {
      calendarSlots.add('');
    }

    // 2. Add the actual numerical days
    for (int i = 1; i <= daysInMonth; i++) {
      calendarSlots.add(i.toString());
    }

    // 3. Add empty strings at the end to complete the last row (make it a multiple of 7)
    while (calendarSlots.length % 7 != 0) {
      calendarSlots.add('');
    }

    List<Widget> columnChildren = [];

    // --- Header Row (Mo, Tu, We, ...) ---
    columnChildren.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: daysOfWeek
            .map((day) => _buildCalText(day, screenWidth, isHeader: true))
            .toList(),
      ),
    );
    columnChildren.add(SizedBox(height: screenWidth * 0.04));

    // --- Loop through the 1D calendar slots list and slice it into rows of 7 ---
    for (int i = 0; i < calendarSlots.length; i += 7) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < 7; j++) {
        String dayStr = calendarSlots[i + j];

        // Highlight active day logic
        if (dayStr == activeDay.toString()) {
          rowChildren.add(_buildCalActive(dayStr, screenWidth));
        } else {
          rowChildren.add(_buildCalText(dayStr, screenWidth));
        }
      }

      columnChildren.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowChildren,
        ),
      );

      // Add vertical gap between rows, except for the very last row
      if (i + 7 < calendarSlots.length) {
        columnChildren.add(SizedBox(height: screenWidth * 0.04));
      }
    }

    // Return the completed outer container with the dynamic rows inside
    return Container(
      width: screenWidth * 0.75,
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        color: AppColors.colwhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: columnChildren),
    );
  }

  Widget _buildCalText(
    String text,
    double screenWidth, {
    bool isHeader = false,
  }) {
    return SizedBox(
      width: screenWidth * 0.07,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: screenWidth * 0.035,
            fontWeight: isHeader ? FontWeight.w500 : FontWeight.w500,
            color: isHeader ? AppColors.colblack : AppColors.subtext,
          ),
        ),
      ),
    );
  }

  Widget _buildCalActive(String text, double screenWidth) {
    return Container(
      width: screenWidth * 0.07,
      height: screenWidth * 0.07,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w500,
            color: AppColors.colwhite,
          ),
        ),
      ),
    );
  }

  // Helper Widget: Responsive Hollow Background Text
  Widget _buildHollowText(double screenWidth) {
    return Text(
      "WRAP",
      style: TextStyle(
        fontFamily: 'CalcioDemo',
        fontSize: screenWidth * 0.4, // Responsive massive background size
        letterSpacing: 1.0,
        height: 1.0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.colwhite.withOpacity(0.15),
      ),
    );
  }
  // --- Layer 7 Custom Widgets ---

  Widget _buildSummaryCard(
    String title,
    String value,
    double screenWidth,
    double screenHeight, {
    bool isExpense = false,
    ForestStatus? forestStatus,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight * 0.084),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
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
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtext,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w700,
                  color: AppColors.colblack,
                ),
              ),
            ],
          ),
          if (isExpense && forestStatus != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.005,
              ),
              decoration: BoxDecoration(
                color: forestStatus.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    forestStatus.icon,
                    color: AppColors.colwhite,
                    size: screenWidth * 0.035,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    forestStatus.label,
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth * 0.03,
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

  Widget _buildMultiSegmentProgressBar(double screenWidth) {
    // FIXED: Safely parsing the amount as a double instead of an int,
    // and initializing the fold sum to 0.0 instead of 0
    double total = _sortedCategories.fold(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    double cumulativeSum = 0.0;
    List<Widget> barLayers = [];

    for (int i = 0; i < _sortedCategories.length; i++) {
      var cat = _sortedCategories[i];

      // FIXED: Safely parse as double here as well
      cumulativeSum += (cat['amount'] as num).toDouble();

      // Prevent division by zero if total expenses are 0
      double percentage = total > 0 ? (cumulativeSum / total) : 0.0;

      barLayers.insert(
        0,
        FractionallySizedBox(
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
        ),
      );
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

  Widget _buildCategoryList(double screenWidth, double screenHeight) {
    return Column(
      children: _sortedCategories
          .map(
            (cat) => Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.02),
              child: Row(
                children: [
                  Container(
                    width: screenWidth * 0.05,
                    height: screenWidth * 0.05,
                    decoration: BoxDecoration(
                      color: cat['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.035),
                  Expanded(
                    child: Text(
                      cat['name'],
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                  ),
                  Text(
                    "- Rs. ${NumberFormat('#,##0').format(cat['amount'])}",
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth * 0.038,
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
}
