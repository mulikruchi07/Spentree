// import 'dart:ui';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import '../../core/app_style.dart';

// // Defines the current state of our animation sequence
// enum WrapPhase { intro, transition, details }

// class SpentWrapScreen extends StatefulWidget {
//   const SpentWrapScreen({super.key});

//   @override
//   State<SpentWrapScreen> createState() => _SpentWrapScreenState();
// }

// class _SpentWrapScreenState extends State<SpentWrapScreen>
//     with TickerProviderStateMixin {
//   // --- Controllers for the 4-part Choreography ---
//   late AnimationController _introCtrl;
//   late AnimationController _exitCtrl;
//   late AnimationController _circleCtrl;
//   late AnimationController _detailsCtrl;

//   WrapPhase _currentPhase = WrapPhase.intro;

//   @override
//   void initState() {
//     super.initState();

//     // 1. Intro Entry Animation (1.4s)
//     _introCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     );

//     // 2. Intro Exit Animation (When checkout is clicked)
//     _exitCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     // 3. White Circle Drop & Expand Transition
//     _circleCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1200),
//     );

//     // 4. Details Screen Entry Animation
//     _detailsCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     );

//     // Initial 2.5 second delay so the user reads "SPENTWRAP"
//     Future.delayed(const Duration(milliseconds: 2500), () {
//       if (mounted) _introCtrl.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _introCtrl.dispose();
//     _exitCtrl.dispose();
//     _circleCtrl.dispose();
//     _detailsCtrl.dispose();
//     super.dispose();
//   }

//   // --- TRIGGERED WHEN "CHECKOUT" IS CLICKED ---
//   void _startCheckoutTransition() {
//     // 1. Slide everything away (except title)
//     _exitCtrl.forward().then((_) {
//       // 2. Start the circle drop transition
//       setState(() => _currentPhase = WrapPhase.transition);
//       _circleCtrl.forward().then((_) {
//         // 3. Circle covered screen. Switch background to white and bring in details
//         setState(() => _currentPhase = WrapPhase.details);
//         Future.delayed(const Duration(milliseconds: 400), () {
//           if (mounted) _detailsCtrl.forward();
//         });
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final double topTextCenterY = screenHeight * 0.100;

//     return Scaffold(
//       backgroundColor: _currentPhase == WrapPhase.details
//           ? Colors.white
//           : AppColors.primaryGreen,
//       body: Stack(
//         children: [
//           // ==========================================
//           // LAYER 1: INTRO SCREEN (Only visible initially)
//           // ==========================================
//           if (_currentPhase != WrapPhase.details)
//             AnimatedBuilder(
//               animation: Listenable.merge([_introCtrl, _exitCtrl]),
//               builder: (context, child) {
//                 final intro = Curves.easeOutCubic.transform(_introCtrl.value);
//                 final exit = Curves.easeIn.transform(_exitCtrl.value);

//                 final val = intro * (1 - exit);
//                 final exitDownVal = intro - exit;

//                 final double treeWidth = screenWidth * 0.55;
//                 final double forestWidth = screenWidth * 1.45;

//                 return Stack(
//                   children: [
//                     // --- Hollow "WRAP" Texts ---
//                     Positioned(
//                       top: screenHeight * 0.20,
//                       left: lerpDouble(-screenWidth, -100, val),
//                       child: Opacity(opacity: val, child: _buildHollowText()),
//                     ),
//                     Positioned(
//                       bottom: screenHeight * 0.16,
//                       right: lerpDouble(-screenWidth, -screenWidth * 0.10, val),
//                       child: Opacity(opacity: val, child: _buildHollowText()),
//                     ),

//                     // --- 2. Floating 3D Assets ---
//                     Positioned(
//                       top: screenHeight * 0.15,
//                       right: lerpDouble(-treeWidth, -(treeWidth * 0.50), val),
//                       width: treeWidth,
//                       child: Opacity(
//                         opacity: val,
//                         child: Image.asset(
//                           'assets/images/tree_1.png',
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       bottom: -screenHeight * 0.002,
//                       left: lerpDouble(
//                         -forestWidth,
//                         -(forestWidth * 0.60),
//                         val,
//                       ),
//                       width: forestWidth,
//                       child: Opacity(
//                         opacity: val,
//                         child: Image.asset(
//                           'assets/images/full_forest_iso.png',
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),

//                     // --- Center Data Card ---
//                     Align(
//                       alignment: Alignment.center,
//                       child: Transform.translate(
//                         offset: Offset(0, 1000 * (1 - exitDownVal)),
//                         child: Opacity(
//                           opacity: exitDownVal.clamp(0.0, 1.0),
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 32),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(24),
//                               child: BackdropFilter(
//                                 filter: ImageFilter.blur(
//                                   sigmaX: 15.0,
//                                   sigmaY: 15.0,
//                                 ),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withOpacity(0.40),
//                                     borderRadius: BorderRadius.circular(24),
//                                   ),
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.all(13),
//                                         decoration: const BoxDecoration(
//                                           color: AppColors.primaryGreen,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: Icon(
//                                           PhosphorIcons.presentationChart(),
//                                           color: Colors.white,
//                                           size: 44,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 19),
//                                       Text(
//                                         "September Spentwrap",
//                                         textAlign: TextAlign.center,
//                                         style: GoogleFonts.montserrat(
//                                           fontSize: 24,
//                                           fontWeight: FontWeight.w600,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         "See your performance in the\nlast month",
//                                         textAlign: TextAlign.center,
//                                         style: GoogleFonts.montserrat(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w500,
//                                           color: Colors.white.withOpacity(0.46),
//                                           height: 1.4,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 15),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 54,
//                                         child: ElevatedButton(
//                                           onPressed: _startCheckoutTransition,
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 AppColors.primaryGreen,
//                                             elevation: 0,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(14),
//                                             ),
//                                           ),
//                                           child: Text(
//                                             "Checkout",
//                                             style: GoogleFonts.montserrat(
//                                               fontSize: 17,
//                                               fontWeight: FontWeight.w400,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 7),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 54,
//                                         child: OutlinedButton(
//                                           onPressed: () =>
//                                               Navigator.pop(context),
//                                           style: OutlinedButton.styleFrom(
//                                             side: BorderSide(
//                                               color: Colors.white.withOpacity(
//                                                 0.6,
//                                               ),
//                                               width: 1,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(14),
//                                             ),
//                                           ),
//                                           child: Text(
//                                             "Remind me later",
//                                             style: GoogleFonts.montserrat(
//                                               fontSize: 17,
//                                               fontWeight: FontWeight.w400,
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                     // --- SPENTWRAP Title ---
//                     Align(
//                       alignment: Alignment.lerp(
//                         Alignment.center,
//                         const Alignment(0, -0.70),
//                         intro,
//                       )!,
//                       child: Text(
//                         "SPENTWRAP",
//                         style: TextStyle(
//                           fontFamily: 'CalcioDemo',
//                           fontSize: lerpDouble(75, 60, intro),
//                           color: Colors.white,
//                           letterSpacing: 2.0,
//                           height: 1.0,
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),

//           // ==========================================
//           // LAYER 2: CIRCLE TRANSITION
//           // ==========================================
//           if (_currentPhase == WrapPhase.transition)
//             AnimatedBuilder(
//               animation: _circleCtrl,
//               builder: (context, child) {
//                 final circleVal = _circleCtrl.value;

//                 double dropProgress = Curves.easeOutCubic.transform(
//                   (circleVal / 0.5).clamp(0.0, 1.0),
//                 );
//                 double expandProgress = Curves.easeInCirc.transform(
//                   ((circleVal - 0.5) / 0.5).clamp(0.0, 1.0),
//                 );

//                 double circleY = lerpDouble(
//                   topTextCenterY + 40,
//                   screenHeight / 2,
//                   dropProgress,
//                 )!;
//                 double scale = lerpDouble(1.0, 80.0, expandProgress)!;

//                 return Positioned(
//                   top: circleY - 10,
//                   left: screenWidth / 2 - 10,
//                   child: Opacity(
//                     opacity: dropProgress,
//                     child: Transform.scale(
//                       scale: scale,
//                       child: Container(
//                         width: 20,
//                         height: 20,
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),

//           // ==========================================
//           // LAYER 3: NEW DETAILS SCREEN
//           // ==========================================
//           if (_currentPhase == WrapPhase.details)
//             AnimatedBuilder(
//               animation: _detailsCtrl,
//               builder: (context, child) {
//                 // Curved value for sliding (smooth deceleration)
//                 final dVal = Curves.easeOutCubic.transform(_detailsCtrl.value);
//                 // Linear value for rotation (steady, highly visible spin while sliding)
//                 final linearVal = _detailsCtrl.value;

//                 return Stack(
//                   children: [
//                     // --- Text Content & Center Box ---
//                     SafeArea(
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 50),

//                           // Header & Dashes (Starts at top margin)
//                           Transform.translate(
//                             offset: Offset(
//                               0,
//                               lerpDouble(-screenHeight * 0.3, 0, dVal)!,
//                             ),
//                             child: Column(
//                               children: [
//                                 Text(
//                                   "April Spentwrap",
//                                   style: GoogleFonts.montserrat(
//                                     fontSize: 18.43,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 26),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: List.generate(
//                                     5,
//                                     (index) => Container(
//                                       margin: const EdgeInsets.symmetric(
//                                         horizontal: 4,
//                                       ),
//                                       width: 45,
//                                       height: 5,
//                                       decoration: BoxDecoration(
//                                         color: index == 0
//                                             ? AppColors.primaryGreen
//                                             : AppColors.inputFill,
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(height: 135),

//                           // Biggest Spending Zone Text (Starts higher, moves FASTER)
//                           Transform.translate(
//                             offset: Offset(
//                               0,
//                               lerpDouble(-screenHeight * 0.6, 0, dVal)!,
//                             ),
//                             child: RichText(
//                               textAlign: TextAlign.center,
//                               text: TextSpan(
//                                 children: [
//                                   TextSpan(
//                                     text: "Your ",
//                                     style: GoogleFonts.montserrat(
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.w600,
//                                       color: const Color(0xFF2D2B3F),
//                                     ),
//                                   ),
//                                   TextSpan(
//                                     text: "BIGGEST\n",
//                                     style: GoogleFonts.montserrat(
//                                       fontSize: 40,
//                                       fontWeight: FontWeight.w700,
//                                       height: 1.1,
//                                       color: const Color(0xFF2D2B3F),
//                                     ),
//                                   ),
//                                   TextSpan(
//                                     text: "spending zone",
//                                     style: GoogleFonts.montserrat(
//                                       fontSize: 24,
//                                       fontWeight: FontWeight.w600,
//                                       color: const Color(0xFF2D2B3F),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),

//                           const SizedBox(height: 51),

//                           // --- Center Data Box & Icons ---
//                           Align(
//                             alignment: Alignment.center,
//                             child: Stack(
//                               clipBehavior: Clip.none,
//                               alignment: Alignment.center,
//                               children: [
//                                 // --- ICONS RENDERED BEHIND THE BLURRED BOX ---
//                                 // Top Right Green Box (Pure horizontal slide, steady rotation)
//                                 Positioned(
//                                   top: -26,
//                                   right: -40,
//                                   child: Transform.translate(
//                                     offset: Offset(
//                                       lerpDouble(screenWidth * 0.5, 0, dVal)!,
//                                       0,
//                                     ),
//                                     child: Transform.rotate(
//                                       angle: lerpDouble(
//                                         0,
//                                         21.47 * math.pi / 180,
//                                         linearVal,
//                                       )!,
//                                       child: _buildGreenIconBox(
//                                         PhosphorIcons.bowlSteam(),
//                                       ),
//                                     ),
//                                   ),
//                                 ),

//                                 // Bottom Left Green Box (Pure horizontal slide, steady rotation)
//                                 Positioned(
//                                   bottom: -16,
//                                   left: -40,
//                                   child: Transform.translate(
//                                     offset: Offset(
//                                       lerpDouble(-screenWidth * 0.5, 0, dVal)!,
//                                       0,
//                                     ),
//                                     child: Transform.rotate(
//                                       angle: lerpDouble(
//                                         0,
//                                         -25.87 * math.pi / 180,
//                                         linearVal,
//                                       )!,
//                                       child: _buildGreenIconBox(
//                                         PhosphorIconsRegular.wine,
//                                       ),
//                                     ),
//                                   ),
//                                 ),

//                                 Transform.translate(
//                                   offset: Offset(
//                                     0,
//                                     lerpDouble(screenHeight * 0.6, 0, dVal)!,
//                                   ),
//                                   child: Container(
//                                     width: screenWidth - 140,
//                                     // 1. OUTER CONTAINER FOR THE DROP SHADOW
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(19),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black.withOpacity(
//                                             0.1,
//                                           ), // Soft drop shadow
//                                           blurRadius: 30,
//                                           spreadRadius: 5,
//                                           offset: const Offset(
//                                             0,
//                                             10,
//                                           ), // Casts smoothly towards the edges
//                                         ),
//                                       ],
//                                     ),
//                                     // 2. CLIP RECT TO KEEP THE BLUR INSIDE THE CORNERS
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(9),
//                                       child: BackdropFilter(
//                                         // Strong blur so the icons behind it are heavily frosted
//                                         filter: ImageFilter.blur(
//                                           sigmaX: 5.0,
//                                           sigmaY: 5.0,
//                                         ),
//                                         child: Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             vertical: 25,
//                                             horizontal: 20,
//                                           ),
//                                           // 3. INNER CONTAINER (No border, mostly white)
//                                           decoration: BoxDecoration(
//                                             // 65% white gives it a solid bright look while still allowing the frosted icons to peek through
//                                             color: Colors.white.withOpacity(
//                                               0.60,
//                                             ),
//                                             borderRadius: BorderRadius.circular(
//                                               19,
//                                             ),
//                                             // BORDER REMOVED HERE
//                                           ),
//                                           child: Column(
//                                             children: [
//                                               Text(
//                                                 "Food - ₹8,200",
//                                                 style: GoogleFonts.montserrat(
//                                                   fontSize: 24,
//                                                   fontWeight: FontWeight.w600,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 18),
//                                               Text(
//                                                 "That's 33% of your total\nspending.",
//                                                 textAlign: TextAlign.center,
//                                                 style: GoogleFonts.montserrat(
//                                                   fontSize: 15,
//                                                   fontWeight: FontWeight.w500,
//                                                   color: Colors.grey.shade700,
//                                                   height: 1.4,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(height: 130),

//                           // Bottom Tip (Slides up from OUTSIDE bottom margin)
//                           Transform.translate(
//                             offset: Offset(
//                               0,
//                               lerpDouble(screenHeight * 0.5, 0, dVal)!,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.only(bottom: 112.0),
//                               child: Text(
//                                 "Maybe you should join\ncooking classes",
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.montserrat(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey.shade500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // --- Floating Images (Burger & Fries) ---
//                     // Top Left Burger (Slides horizontally from OUTSIDE left margin, steady rotation)
//                     Positioned(
//                       top: screenHeight * 0.12,
//                       left: lerpDouble(-screenWidth, -60, dVal),
//                       child: Transform.rotate(
//                         angle: lerpDouble(0, 14 * math.pi / 180, linearVal)!,
//                         child: Image.asset(
//                           'assets/images/forest/spentwrap/food1.png',
//                           width: 150,
//                         ),
//                       ),
//                     ),

//                     // Bottom Right Fries (Slides horizontally from OUTSIDE right margin, steady rotation)
//                     Positioned(
//                       bottom: screenHeight * 0.12,
//                       right: lerpDouble(-screenWidth, -60, dVal),
//                       child: Transform.rotate(
//                         angle: lerpDouble(0, -14 * math.pi / 180, linearVal)!,
//                         child: Image.asset(
//                           'assets/images/forest/spentwrap/food2.png',
//                           width: 150,
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   // Helper Widget: Exact 52x52 Box with 28px Icon
//   Widget _buildGreenIconBox(IconData icon) {
//     return Container(
//       width: 58,
//       height: 58,
//       decoration: BoxDecoration(
//         color: AppColors.primaryGreen,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 9,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Center(child: PhosphorIcon(icon, color: Colors.white, size: 32)),
//     );
//   }

//   // Helper Widget: Hollow Background Text
//   Widget _buildHollowText() {
//     return Text(
//       "WRAP",
//       style: TextStyle(
//         fontFamily: 'CalcioDemo',
//         fontSize: 160,
//         letterSpacing: 1.0,
//         height: 1.0,
//         foreground: Paint()
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 1.2
//           ..color = Colors.white.withOpacity(0.15),
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
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _detailsCtrl.forward();
        });
      });
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
          // LAYER 3: NEW DETAILS SCREEN
          // ==========================================
          if (_currentPhase == WrapPhase.details)
            AnimatedBuilder(
              animation: _detailsCtrl,
              builder: (context, child) {
                final dVal = Curves.easeOutCubic.transform(_detailsCtrl.value);
                final linearVal = _detailsCtrl.value;

                return Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.05),

                          // Header (Slides down from top)
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(-screenHeight * 0.3, 0, dVal)!,
                            ),
                            child: Column(
                              children: [
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
                                  children: List.generate(
                                    5,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: screenWidth * 0.1,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? AppColors.primaryGreen
                                            : AppColors.inputFill,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.14),

                          // Biggest Spending Zone Text
                          Transform.translate(
                            offset: Offset(
                              0,
                              lerpDouble(-screenHeight * 0.6, 0, dVal)!,
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
        ],
      ),
    );
  }

  // Helper Widget: Responsive Green Icon Box
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
