// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import '../../core/app_style.dart';

// class SpentWrapScreen extends StatefulWidget {
//   const SpentWrapScreen({super.key});

//   @override
//   State<SpentWrapScreen> createState() => _SpentWrapScreenState();
// }

// class _SpentWrapScreenState extends State<SpentWrapScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animController;
//   late Animation<double> _curvedAnim;

//   @override
//   void initState() {
//     super.initState();

//     // Controls the entire choreographed animation
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400), // Smooth 1.4s duration
//     );

//     // EaseOutCubic makes it start fast and smoothly decelerate into place
//     _curvedAnim = CurvedAnimation(
//       parent: _animController,
//       curve: Curves.easeOutCubic,
//     );

//     // Added 2.5 second delay so the user can easily read the giant "SPENTWRAP"
//     // text before the animated elements slide into place.
//     Future.delayed(const Duration(milliseconds: 2500), () {
//       if (mounted) _animController.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     // Calculate exact asset sizes based on Figma proportions
//     final double treeWidth = screenWidth * 0.55;
//     final double forestWidth = screenWidth * 1.45; // Based on 564/290 ratio relative to tree

//     // Calculate the exact vertical center for the top SPENTWRAP text
//     // Alignment(0, -0.65) places the center of the text at 17.5% from the top of the screen.
//     final double topTextCenterY = screenHeight * 0.100;

//     return Scaffold(
//       backgroundColor: AppColors.primaryGreen,
//       body: AnimatedBuilder(
//         animation: _curvedAnim,
//         builder: (context, child) {
//           final val = _curvedAnim.value;

//           return Stack(
//             children: [
//               // --- 1. Background Hollow "WRAP" Texts ---
//               // Top Left WRAP (Aligned to 50% height of the SPENTWRAP text)
//               Positioned(
//                 top: screenHeight * 0.20,
//                 left: lerpDouble(-screenWidth, -100, val), // Peeps partially on screen
//                 child: Opacity(
//                   opacity: val, // Fades in while sliding
//                   child: _buildHollowText(),
//                 ),
//               ),

//               // Bottom Right WRAP (Moved slightly up per requirements)
//               Positioned(
//                 bottom: screenHeight * 0.16,
//                 // Peeps partially on screen
//                 right: lerpDouble(-screenWidth, -screenWidth * 0.10, val),
//                 child: Opacity(
//                   opacity: val,
//                   child: _buildHollowText(),
//                 ),
//               ),

//               // --- 2. Floating 3D Assets ---
//               // Top Right Tree
//               Positioned(
//                 top: screenHeight * 0.15,
//                 // Slides from off-screen right to exactly 50% visible
//                 right: lerpDouble(-treeWidth, -(treeWidth * 0.50), val),
//                 width: treeWidth,
//                 child: Opacity(
//                   opacity: val,
//                   child: Image.asset(
//                     'assets/images/tree_1.png',
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),

//               // Bottom Left Forest
//               Positioned(
//                 // Bottom 10% cutoff
//                 bottom: -screenHeight * 0.002,
//                 // Slides from off-screen left to exactly 35% visible (65% hidden)
//                 left: lerpDouble(-forestWidth, -(forestWidth * 0.60), val),
//                 width: forestWidth,
//                 child: Opacity(
//                   opacity: val,
//                   child: Image.asset(
//                     'assets/images/full_forest_iso.png',
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//               ),

//               // --- 3. The Main Center Data Card ---
//               Align(
//                 alignment: Alignment.center,
//                 child: Transform.translate(
//                   offset: Offset(0, 200 * (1 - val)),
//                   child: Opacity(
//                     opacity: val,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 32),
//                       // 2. ClipRRect ensures the blur stays inside the rounded corners
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(24),
//                         // 3. BackdropFilter applies the glassmorphism blur
//                         child: BackdropFilter(
//                           filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Adjust sigma for more/less blur
//                           child: Container(
//                             // Equal padding from all 4 sides
//                             padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         // 000000 with 40% opacity as requested (No box shadow)
//                         color: Colors.black.withOpacity(0.40),
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Top Circular Icon Badge
//                           Container(
//                             padding: const EdgeInsets.all(13), // Keeps the circle tight
//                             decoration: const BoxDecoration(
//                               color: AppColors.primaryGreen,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               PhosphorIcons.presentationChart(), // Exactly 34 size
//                               color: Colors.white,
//                               size: 44,
//                             ),
//                           ),
//                           const SizedBox(height: 19),

//                           // Titles
//                           Text(
//                             "September Spentwrap",
//                             textAlign: TextAlign.center,
//                             style: GoogleFonts.montserrat(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600, // SemiBold
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             "See your performance in the\nlast month",
//                             textAlign: TextAlign.center,
//                             style: GoogleFonts.montserrat(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w500, // Medium
//                               color: Colors.white.withOpacity(0.46), // White 46% opacity
//                               height: 1.4,
//                             ),
//                           ),
//                           const SizedBox(height: 15),

//                           // Checkout Button
//                           SizedBox(
//                             width: double.infinity,
//                             height: 54,
//                             child: ElevatedButton(
//                               onPressed: () {},
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.primaryGreen,
//                                 elevation: 0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(14),
//                                 ),
//                               ),
//                               child: Text(
//                                 "Checkout",
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 17, // Increased text size
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 7),

//                           // Remind me later Button
//                           SizedBox(
//                             width: double.infinity,
//                             height: 54,
//                             child: OutlinedButton(
//                               onPressed: () => Navigator.pop(context),
//                               style: OutlinedButton.styleFrom(
//                                 side: BorderSide(
//                                   color: Colors.white.withOpacity(0.6),
//                                   width: 1,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(14),
//                                 ),
//                               ),
//                               child: Text(
//                                 "Remind me later", // Updated text
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 17, // Increased text size
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               // --- 4. Main SPENTWRAP Title ---
//               Align(
//                 // Moves from dead center to exactly between the top edge and center box
//                 alignment: Alignment.lerp(
//                   Alignment.center,
//                   const Alignment(0, -0.70),
//                   val,
//                 )!,
//                 child: Text(
//                   "SPENTWRAP",
//                   style: TextStyle(
//                     fontFamily: 'CalcioDemo',
//                     // Starts at 75, shrinks smoothly to exactly 56 (larger than before)
//                     fontSize: lerpDouble(75, 60, val),
//                     color: Colors.white,
//                     letterSpacing: 2.0,
//                     height: 1.0,
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // --- Helper Widget: Hollow Text with Stroke ---
//   Widget _buildHollowText() {
//     return Text(
//       "WRAP",
//       style: TextStyle(
//         fontFamily: 'CalcioDemo',
//         fontSize: 160, // Massive background size
//         letterSpacing: 1.0,
//         height: 1.0,
//         // The magic properties that make the text outline-only
//         foreground: Paint()
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 1.2
//           ..color = Colors.white.withOpacity(0.15), // Faint white outline
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/app_style.dart';

// Defines the current state of our animation sequence
enum WrapPhase { intro, transition, details }

class SpentWrapScreen extends StatefulWidget {
  const SpentWrapScreen({super.key});

  @override
  State<SpentWrapScreen> createState() => _SpentWrapScreenState();
}

class _SpentWrapScreenState extends State<SpentWrapScreen>
    with TickerProviderStateMixin {
  // --- Controllers for the 4-part Choreography ---
  late AnimationController _introCtrl;
  late AnimationController _exitCtrl;
  late AnimationController _circleCtrl;
  late AnimationController _detailsCtrl;

  WrapPhase _currentPhase = WrapPhase.intro;

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
        _detailsCtrl.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topTextCenterY = screenHeight * 0.100;

    return Scaffold(
      // The background snaps to white only when the circle has fully covered it
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
                // Curved Intro
                final intro = Curves.easeOutCubic.transform(_introCtrl.value);
                // Curved Exit (EaseIn makes it start slow and zip away)
                final exit = Curves.easeIn.transform(_exitCtrl.value);

                // For elements sliding OFF screen on checkout
                final val = intro * (1 - exit);

                // For elements sliding completely out the bottom
                final exitDownVal = intro - exit;

                final double treeWidth = screenWidth * 0.55;
                final double forestWidth = screenWidth * 1.45;

                return Stack(
                  children: [
                    // --- Hollow "WRAP" Texts ---
                    Positioned(
                      top: screenHeight * 0.20,
                      left: lerpDouble(-screenWidth, -100, val),
                      child: Opacity(opacity: val, child: _buildHollowText()),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.16,
                      right: lerpDouble(-screenWidth, -screenWidth * 0.10, val),
                      child: Opacity(opacity: val, child: _buildHollowText()),
                    ),

                    // --- 2. Floating 3D Assets ---
                    // Top Right Tree
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

                    // Bottom Left Forest
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
                        // Uses exitDownVal so it slides from bottom initially, and slides back down completely on exit
                        offset: Offset(0, 1000 * (1 - exitDownVal)),
                        child: Opacity(
                          // Ensure opacity doesn't drop below 0 to avoid errors
                          opacity: exitDownVal.clamp(0.0, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15.0,
                                  sigmaY: 15.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.40),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(13),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          PhosphorIcons.presentationChart(),
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                      ),
                                      const SizedBox(height: 19),
                                      Text(
                                        "September Spentwrap",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "See your performance in the\nlast month",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.46),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      // Checkout Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
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
                                            style: GoogleFonts.poppins(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),

                                      // Remind me later Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.white.withOpacity(
                                                0.6,
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
                                            style: GoogleFonts.poppins(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
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
                      // Uses intro ONLY so it stays locked in place when checking out
                      alignment: Alignment.lerp(
                        Alignment.center,
                        const Alignment(0, -0.70),
                        intro,
                      )!,
                      child: Text(
                        "SPENTWRAP",
                        style: TextStyle(
                          fontFamily: 'CalcioDemo',
                          fontSize: lerpDouble(75, 60, intro),
                          color: Colors.white,
                          letterSpacing: 2.0,
                          height: 1.0,
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
                double scale = lerpDouble(1.0, 80.0, expandProgress)!;

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
          if (_currentPhase == WrapPhase.details)
            AnimatedBuilder(
              animation: _detailsCtrl,
              builder: (context, child) {
                // Bespoke curve to match the butter-smooth intro style
                final dVal = Curves.easeOutCubic.transform(_detailsCtrl.value);

                return Stack(
                  children: [
                    // --- Text Content & Center Box ---
                    SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 50),

                          // Header (Slides down from top)
                          Transform.translate(
                            offset: Offset(0, -100 * (1 - dVal)),
                            child: Opacity(
                              opacity: dVal,
                              child: Column(
                                children: [
                                  Text(
                                    "April Spentwrap",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18.43,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 28), // Updated Gap
                                  // 5 Dashes
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      5,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: index == 0
                                              ? AppColors.primaryGreen
                                              : Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 120,
                                  ), // Updated Gap to text
                                  // Biggest Spending Zone Text
                                  Text(
                                    "Your",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24, // Updated size
                                      fontWeight: FontWeight.w600, // SemiBold
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  Text(
                                    "BIGGEST",
                                    style: GoogleFonts.poppins(
                                      fontSize: 40, // Updated size
                                      fontWeight: FontWeight.w700, // Bold
                                      height: 1.1,
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                  Text(
                                    "spending zone",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24, // Updated size
                                      fontWeight: FontWeight.w600, // SemiBold
                                      color: const Color(0xFF2D2B3F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Center Data Box sliding up (68% Blur requested)
                          Transform.translate(
                            offset: Offset(0, 150 * (1 - dVal)),
                            child: Opacity(
                              opacity: dVal,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  // The actual Data Box
                                  Container(
                                    // Reduced width to match right image design
                                    width: screenWidth - 100,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 40,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        // Slight normal shadow, not green
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Food - ₹8,200",
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight:
                                                FontWeight.w600, // SemiBold
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "That's 33% of your total\nspending.",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey.shade500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Top Right Green Box (Bowl Icon) (Rotates Clockwise +21.47)
                                  Positioned(
                                    top: -20, // Corner positioning
                                    right: -20,
                                    child: Transform.rotate(
                                      angle: lerpDouble(
                                        0,
                                        21.47 * math.pi / 180,
                                        dVal,
                                      )!,
                                      child: _buildGreenIconBox(
                                        PhosphorIconsRegular
                                            .bowlFood, // Inner icon
                                      ),
                                    ),
                                  ),

                                  // Bottom Left Green Box (Wine Icon) (Rotates Anti-Clockwise -25.87)
                                  Positioned(
                                    bottom: -20, // Corner positioning
                                    left: -20,
                                    child: Transform.rotate(
                                      angle: lerpDouble(
                                        0,
                                        -25.87 * math.pi / 180,
                                        dVal,
                                      )!,
                                      child: _buildGreenIconBox(
                                        PhosphorIconsRegular.wine, // Inner icon
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom Tip sliding up
                          Transform.translate(
                            offset: Offset(0, 100 * (1 - dVal)),
                            child: Opacity(
                              opacity: dVal,
                              child: Padding(
                                // Exactly 112 gap distance
                                padding: const EdgeInsets.only(bottom: 112.0),
                                child: Text(
                                  "Maybe you should join\ncooking classes",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Floating Images (Burger & Fries) ---
                    // Top Left Burger (Rotates Clockwise 14 deg) - Moved Up
                    Positioned(
                      top: screenHeight * 0.12,
                      left: lerpDouble(-150, -60, dVal), // 50% peep
                      child: Opacity(
                        opacity: dVal,
                        child: Transform.rotate(
                          angle: lerpDouble(0, 14 * math.pi / 180, dVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/food1.png',
                            width: 150,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Right Fries (Rotates Anti-Clockwise 14 deg) - Moved Up
                    Positioned(
                      bottom: screenHeight * 0.12,
                      right: lerpDouble(-150, -60, dVal), // 50% peep
                      child: Opacity(
                        opacity: dVal,
                        child: Transform.rotate(
                          angle: lerpDouble(0, -14 * math.pi / 180, dVal)!,
                          child: Image.asset(
                            'assets/images/forest/spentwrap/food2.png',
                            width: 150,
                          ),
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

  // Helper Widget: Green Icon Box with soft shadow
  Widget _buildGreenIconBox(IconData icon) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Normal slight shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: PhosphorIcon(icon, color: Colors.white, size: 28)),
    );
  }

  // Helper Widget: Hollow Background Text
  Widget _buildHollowText() {
    return Text(
      "WRAP",
      style: TextStyle(
        fontFamily: 'CalcioDemo',
        fontSize: 160,
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
