import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/app_style.dart';

// Added the 4th phase for Top Spends
enum WrapPhase { intro, transition, details, topSpends, strongestDay }

class SpentWrapScreen extends StatefulWidget {
  const SpentWrapScreen({super.key});

  @override
  State<SpentWrapScreen> createState() => _SpentWrapScreenState();
}

class _SpentWrapScreenState extends State<SpentWrapScreen>
    with TickerProviderStateMixin {
  // --- Controllers for the Choreography ---
  late AnimationController _introCtrl;
  late AnimationController _exitCtrl;
  late AnimationController _circleCtrl;

  // Layer 3 (Details) Entry & Exit
  late AnimationController _detailsCtrl;
  late AnimationController _detailsExitCtrl;

  // Layer 4 (Top Spends) Entry
  late AnimationController _topSpendsCtrl;
  late AnimationController _topSpendsExitCtrl;

  // Layer 5 (Strongest Day) Entry
  late AnimationController _strongestDayCtrl;

  // 5-second timer for the progress dashes
  late AnimationController _progressCtrl;

  WrapPhase _currentPhase = WrapPhase.intro;

  // Tracks which dash is currently active/filling (0 for Details, 1 for Top Spends)
  int _activeProgressIndex = 0;

  @override
  void initState() {
    super.initState();

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

    // NEW: 5-Second Progress Bar Timer
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Listener 1: When Layer 3 finishes entering, start the 5s progress bar
    _detailsCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressCtrl.forward();
      }
    });

    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentPhase == WrapPhase.details) {
          _transitionToTopSpends();
        } else if (_currentPhase == WrapPhase.topSpends) {
          _transitionToStrongestDay();
        }
      }
    });

    _topSpendsCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressCtrl.reset();
        setState(() => _activeProgressIndex = 1);
        _progressCtrl.forward();
      }
    });

    _strongestDayCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressCtrl.reset();
        setState(() => _activeProgressIndex = 2);
        _progressCtrl.forward();
      }
    });

    // Initial 2.5 second delay so the user reads "SPENTWRAP"
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _introCtrl.forward();
    });
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
    _progressCtrl.dispose();
    super.dispose();
  }

  // --- TRIGGERED WHEN "CHECKOUT" IS CLICKED ---
  void _startCheckoutTransition() {
    _exitCtrl.forward().then((_) {
      setState(() => _currentPhase = WrapPhase.transition);
      _circleCtrl.forward().then((_) {
        setState(() => _currentPhase = WrapPhase.details);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _detailsCtrl.forward();
        });
      });
    });
  }

  // --- TRANSITION FROM LAYER 3 TO LAYER 4 ---
  void _transitionToTopSpends() {
    // 1. Slide Layer 3 elements out
    _detailsExitCtrl.forward().then((_) {
      // 2. Change phase so Layer 4 renders
      setState(() => _currentPhase = WrapPhase.topSpends);
      // 3. Slide Layer 4 elements in
      _topSpendsCtrl.forward();
    });
  }

  void _transitionToStrongestDay() {
    _topSpendsExitCtrl.forward().then((_) {
      setState(() => _currentPhase = WrapPhase.strongestDay);
      _strongestDayCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topTextCenterY = screenHeight * 0.100;

    return Scaffold(
      backgroundColor:
          _currentPhase == WrapPhase.details ||
              _currentPhase == WrapPhase.topSpends ||
              _currentPhase == WrapPhase.strongestDay
          ? Colors.white
          : AppColors.primaryGreen,
      body: Stack(
        children: [
          // ==========================================
          // LAYER 1: INTRO SCREEN (Only visible initially)
          // ==========================================
          if (_currentPhase == WrapPhase.intro ||
              _currentPhase == WrapPhase.transition)
            AnimatedBuilder(
              animation: Listenable.merge([_introCtrl, _exitCtrl]),
              builder: (context, child) {
                final intro = Curves.easeOutCubic.transform(_introCtrl.value);
                final exit = Curves.easeIn.transform(_exitCtrl.value);

                final val = intro * (1 - exit);
                final exitDownVal = intro - exit;

                final double treeWidth = screenWidth * 0.55;
                final double forestWidth = screenWidth * 1.45;

                return Stack(
                  children: [
                    // --- Hollow "WRAP" Texts ---
                    Positioned(
                      top: screenHeight * 0.20,
                      left: lerpDouble(-screenWidth, -screenWidth * 0.25, val),
                      child: Opacity(
                        opacity: val,
                        child: _buildHollowText(screenWidth),
                      ),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.16,
                      right: lerpDouble(-screenWidth, -screenWidth * 0.10, val),
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
                          'assets/images/tree_1.png',
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
                          'assets/images/full_forest_iso.png',
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
                                  padding: EdgeInsets.all(screenWidth * 0.035),
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
                                          PhosphorIcons.presentationChart(),
                                          color: Colors.white,
                                          size: screenWidth * 0.1,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Text(
                                        "September Spentwrap",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: screenWidth * 0.055,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Text(
                                        "See your performance in the\nlast month",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.46),
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
                                              color: Colors.white,
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
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.white.withOpacity(
                                                1,
                                              ),
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
                                              color: Colors.white,
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
                      alignment: Alignment.lerp(
                        Alignment.center,
                        const Alignment(0, -0.70),
                        intro,
                      )!,
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
                            color: Colors.white,
                            letterSpacing: 2.0,
                            height: 1.0,
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
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
          if (_currentPhase == WrapPhase.details ||
              _currentPhase == WrapPhase.topSpends ||
              _currentPhase == WrapPhase.strongestDay)
            AnimatedBuilder(
              animation: Listenable.merge([_detailsCtrl, _progressCtrl]),
              builder: (context, child) {
                // Header ONLY animates in during the initial details entry.
                // It stays at value 1.0 permanently after that.
                final dVal = Curves.easeOutCubic.transform(_detailsCtrl.value);
                final pVal = _progressCtrl.value;

                return SafeArea(
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      lerpDouble(-screenHeight * 0.3, 0, dVal)!,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: screenHeight * 0.05),
                        Text(
                          "April Spentwrap",
                          style: GoogleFonts.montserrat(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
                              margin: const EdgeInsets.symmetric(horizontal: 4),
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
                                      borderRadius: BorderRadius.circular(4),
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
                final intro = Curves.easeOutCubic.transform(_detailsCtrl.value);
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
                          'assets/images/forest/spentwrap/food1.png',
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
                          'assets/images/forest/spentwrap/food2.png',
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
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "BIGGEST\n",
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenWidth * 0.1,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "spending zone",
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2D2B3F),
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
                                        PhosphorIcons.bowlSteam(),
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
                                      lerpDouble(-screenWidth * 0.5, 0, dVal)!,
                                      0,
                                    ),
                                    child: Transform.rotate(
                                      angle: lerpDouble(
                                        0,
                                        -25.87 * math.pi / 180,
                                        linearVal,
                                      )!,
                                      child: _buildGreenIconBox(
                                        PhosphorIconsRegular.wine,
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
                                    lerpDouble(screenHeight * 0.6, 0, dVal)!,
                                  ),
                                  child: Container(
                                    width: screenWidth * 0.65,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(19),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
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
                                            color: Colors.white.withOpacity(
                                              0.60,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              19,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                "Food - ₹8,200",
                                                style: GoogleFonts.montserrat(
                                                  fontSize: screenWidth * 0.06,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.015,
                                              ),
                                              Text(
                                                "That's 33% of your total\nspending.",
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: screenWidth * 0.035,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade700,
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
                              lerpDouble(screenHeight * 0.5, 0, dVal)!,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: screenHeight * 0.1,
                              ),
                              child: Text(
                                "Maybe you should join\ncooking classes",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
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
              animation: Listenable.merge([_topSpendsCtrl, _topSpendsExitCtrl]),
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
                                color: const Color(0xFF2D2B3F),
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
                                lerpDouble(screenHeight * 0.6, 0, tVal)!,
                              ),
                              child: Container(
                                width: screenWidth * 0.85,
                                child: Column(
                                  children: [
                                    _buildTransactionCard(
                                      "Shell Petroleum",
                                      "Bank account",
                                      "- Rs. 1500",
                                      "Fri, 11 April 2025",
                                      PhosphorIcons.gasPump(),
                                      screenWidth,
                                      screenHeight,
                                    ),
                                    _buildTransactionCard(
                                      "D-Mart",
                                      "Bank account",
                                      "- Rs. 2000",
                                      "Fri, 11 April 2025",
                                      PhosphorIcons.shoppingCart(),
                                      screenWidth,
                                      screenHeight,
                                    ),
                                    _buildTransactionCard(
                                      "Unknown Source",
                                      "Bank account",
                                      "+ Rs. 2000",
                                      "Fri, 11 April 2025",
                                      PhosphorIcons.currencyInr(),
                                      screenWidth,
                                      screenHeight,
                                      isIncome: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Bottom Tip
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(screenHeight * 0.5, 0, tVal)!,
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
                                  color: Colors.grey.shade500,
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
              animation: _strongestDayCtrl,
              builder: (context, child) {
                final sVal = Curves.easeOutCubic.transform(
                  _strongestDayCtrl.value,
                );
                final linearVal = _strongestDayCtrl.value;

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
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Strongest ",
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenWidth * 0.070,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "day",
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenWidth * 0.060,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2D2B3F),
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
                                lerpDouble(screenHeight * 0.6, 0, sVal)!,
                              ),
                              child: _buildCalendarCard(screenWidth: screenWidth, 
                                year: 2025,   // Set year dynamically here
                                month: 4,     // Set month dynamically here
                                activeDay: 4,),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Bottom Tip
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(screenHeight * 0.5, 0, sVal)!,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: screenHeight * 0.1,
                              ),
                              child: Text(
                                "You spent only 20% of your\ndaily limit.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
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
        ],
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
            "April Spentwrap",
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
      // Responsive vertical spacing
      margin: EdgeInsets.only(bottom: screenHeight * 0.016),
      width: double.infinity,
      // Responsive height
      height: screenHeight * 0.084,
      // Responsive padding
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.024),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            // Responsive box width/height
            width: screenWidth * 0.133,
            height: screenWidth * 0.133,
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
              color: Colors.white,
              // Responsive icon size
              size: screenWidth * 0.06,
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
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
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
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 2),
              Text(
                date,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.025,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
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
          color: Colors.white,
          size: screenWidth * 0.08,
        ),
      ), // Responsive icon size
    );
  }

  // --- Dynamic Calendar Engine ---
  Widget _buildCalendarCard({required double screenWidth, required int year, required int month, required int activeDay}) {
    final daysOfWeek = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    
    // Core DateTime Math for generating the grid
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int daysInMonth = DateTime(year, month + 1, 0).day; // Hack to get last day of month
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
        children: daysOfWeek.map((day) => _buildCalText(day, screenWidth, isHeader: true)).toList(),
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
        color: Colors.white,
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
        children: columnChildren,
      ),
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
            color: isHeader ? Colors.black : Colors.grey.shade600,
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
            color: Colors.white,
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
          ..color = Colors.white.withOpacity(0.15),
      ),
    );
  }
}
