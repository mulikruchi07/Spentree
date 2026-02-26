import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/app_style.dart';

// Defines the current state of our animation sequence
enum WrapPhase { intro, transition, details, topSpends }

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

    // New Controllers
    _detailsExitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _topSpendsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 4. Details Screen Entry Animation
    _detailsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 5-Second Progress Bar Timer
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // When the Details screen finishes entering, start the 5s progress bar
    _detailsCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressCtrl.forward();
      }
    });

    // When the 5s progress bar finishes on the Details screen, transition to Top Spends
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _currentPhase == WrapPhase.details) {
        _transitionToTopSpends();
      }
    });

    // When the Top Spends screen finishes entering, start the progress bar again for the next slide
    _topSpendsCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset timer, increment dash index, and start 5s timer again
        _progressCtrl.reset();
        setState(() => _activeProgressIndex = 1);
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
    _progressCtrl.dispose();
    super.dispose();
  }

  // --- TRIGGERED WHEN "CHECKOUT" IS CLICKED ---
  void _startCheckoutTransition() {
    // 1. Slide everything away (except title)
    _exitCtrl.forward().then((_) {
      // 2. Start the circle drop transition
      setState(() => _currentPhase = WrapPhase.transition);
      _circleCtrl.forward().then((_) {
        // 3. Circle covered screen. Switch background to white and bring in details
        setState(() => _currentPhase = WrapPhase.details);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _detailsCtrl.forward();
        });
      });
    });
  }

  // --- TRANSITION FROM DETAILS TO TOP SPENDS ---
  void _transitionToTopSpends() {
    // 1. Slide old elements out
    _detailsExitCtrl.forward().then((_) {
      // 2. Change phase to render new elements
      setState(() => _currentPhase = WrapPhase.topSpends);
      // 3. Slide new elements in
      _topSpendsCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topTextCenterY = screenHeight * 0.100;

    return Scaffold(
      backgroundColor: _currentPhase == WrapPhase.details
          ? Colors.white
          : AppColors.primaryGreen,
      body: Stack(
        children: [
          // ==========================================
          // LAYER 1: INTRO SCREEN (Only visible initially)
          // ==========================================
          if (_currentPhase != WrapPhase.details)
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
                        child: Opacity(
                          opacity: exitDownVal.clamp(0.0, 1.0),
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
                                            color: Colors.white.withOpacity(
                                              0.46,
                                            ),
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
          // LAYER 3: NEW DETAILS SCREEN
          // ==========================================
          if (_currentPhase == WrapPhase.details ||
              _currentPhase == WrapPhase.topSpends)
            AnimatedBuilder(
              animation: Listenable.merge([_detailsCtrl, _progressCtrl]),
              builder: (context, child) {
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
          if (_currentPhase == WrapPhase.details ||
              _currentPhase == WrapPhase.topSpends)
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
                final linearVal = _detailsCtrl.value; // For rotation

                // Hide completely when exit is finished to make way for Layer 4
                if (exit == 1.0) return const SizedBox.shrink();

                return Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          // Invisible placeholder to push content down past the fixed header
                          SizedBox(
                            height:
                                screenHeight * 0.05 +
                                screenHeight * 0.03 +
                                5 +
                                26,
                          ),
                          SizedBox(height: screenHeight * 0.12),

                          // Biggest Spending Zone Text (Slides down initially, slides UP on exit)
                          // We map the exit differently here so it goes UP to -screenHeight * 0.6 instead of back down.

                          // Biggest Spending Zone Text
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
                          // SizedBox(height: screenHeight * 0.05),

                          // --- Center Data Box & Icons ---
                          Align(
                            alignment: Alignment.center,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Top Right Green Box
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

                                // Bottom Left Green Box
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
                                    lerpDouble(screenHeight * 0.6, 0, dVal)!,
                                  ),
                                  child: Container(
                                    width:
                                        screenWidth * 0.65, // Responsive width
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

                    // --- Floating Images (Burger & Fries) ---
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
                          width: screenWidth * 0.35, // Responsive size
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
                          width: screenWidth * 0.35, // Responsive size
                        ),
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
              animation: _topSpendsCtrl,
              builder: (context, child) {
                final tVal = Curves.easeOutCubic.transform(
                  _topSpendsCtrl.value,
                );
                final linearVal = _topSpendsCtrl.value;

                return Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          // Push content below the fixed header
                          SizedBox(
                            height:
                                screenHeight * 0.05 +
                                screenHeight * 0.03 +
                                5 +
                                26,
                          ),
                          SizedBox(height: screenHeight * 0.16),

                          // Header Text (Slides down from top)
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(-screenHeight * 0.6, 0, tVal)!,
                            ),
                            child: Text(
                              "Your top spends were",
                              style: GoogleFonts.montserrat(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D2B3F),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // Transaction Cards List (Slides up from bottom)
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
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildTransactionCard(
                                      "D-Mart",
                                      "Bank account",
                                      "- Rs. 2000",
                                      "Fri, 11 April 2025",
                                      PhosphorIcons.shoppingCart(),
                                      screenWidth,
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                    _buildTransactionCard(
                                      "Unknown Source",
                                      "Bank account",
                                      "+ Rs. 2000",
                                      "Fri, 11 April 2025",
                                      PhosphorIcons.currencyInr(),
                                      screenWidth,
                                      isIncome: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.12),

                          // Bottom Tip
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(screenHeight * 0.5, 0, tVal)!,
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: screenHeight * 0.12,
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

                    // --- Floating Images (Cash & Bag) ---
                    Positioned(
                      top: screenHeight * 0.12,
                      left: lerpDouble(
                        -screenWidth * 0.5,
                        -screenWidth * 0.15,
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
                        -screenWidth * 0.15,
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
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTransactionCard(
    String title,
    String subtitle,
    String amount,
    String date,
    IconData icon,
    double screenWidth, {
    bool isIncome = false,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w700,
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
            children: [
              Text(
                amount,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.primaryGreen : Colors.black,
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

  // Responsive  Box
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
