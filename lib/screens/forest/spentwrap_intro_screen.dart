import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/app_style.dart';

class SpentWrapScreen extends StatefulWidget {
  const SpentWrapScreen({super.key});

  @override
  State<SpentWrapScreen> createState() => _SpentWrapScreenState();
}

class _SpentWrapScreenState extends State<SpentWrapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _curvedAnim;

  @override
  void initState() {
    super.initState();
    
    // Controls the entire choreographed animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), // Smooth 1.4s duration
    );

    // EaseOutCubic makes it start fast and smoothly decelerate into place
    _curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic, 
    );

    // Added 2.5 second delay so the user can easily read the giant "SPENTWRAP"
    // text before the animated elements slide into place.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate exact asset sizes based on Figma proportions
    final double treeWidth = screenWidth * 0.55;
    final double forestWidth = screenWidth * 1.45; // Based on 564/290 ratio relative to tree

    // Calculate the exact vertical center for the top SPENTWRAP text
    // Alignment(0, -0.65) places the center of the text at 17.5% from the top of the screen.
    final double topTextCenterY = screenHeight * 0.100; 

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: AnimatedBuilder(
        animation: _curvedAnim,
        builder: (context, child) {
          final val = _curvedAnim.value;

          return Stack(
            children: [
              // --- 1. Background Hollow "WRAP" Texts ---
              // Top Left WRAP (Aligned to 50% height of the SPENTWRAP text)
              Positioned(
                top: screenHeight * 0.20,
                left: lerpDouble(-screenWidth, -100, val), // Peeps partially on screen
                child: Opacity(
                  opacity: val, // Fades in while sliding
                  child: _buildHollowText(),
                ),
              ),

              // Bottom Right WRAP (Moved slightly up per requirements)
              Positioned(
                bottom: screenHeight * 0.16, 
                // Peeps partially on screen
                right: lerpDouble(-screenWidth, -screenWidth * 0.10, val), 
                child: Opacity(
                  opacity: val,
                  child: _buildHollowText(),
                ),
              ),

              // --- 2. Floating 3D Assets ---
              // Top Right Tree 
              Positioned(
                top: screenHeight * 0.15,
                // Slides from off-screen right to exactly 50% visible
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
                // Bottom 10% cutoff 
                bottom: -screenHeight * 0.002, 
                // Slides from off-screen left to exactly 35% visible (65% hidden)
                left: lerpDouble(-forestWidth, -(forestWidth * 0.60), val),
                width: forestWidth,
                child: Opacity(
                  opacity: val,
                  child: Image.asset(
                    'assets/images/full_forest_iso.png', 
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // --- 3. The Main Center Data Card ---
              Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, 200 * (1 - val)),
                  child: Opacity(
                    opacity: val,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      // 2. ClipRRect ensures the blur stays inside the rounded corners
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        // 3. BackdropFilter applies the glassmorphism blur
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Adjust sigma for more/less blur
                          child: Container(
                            // Equal padding from all 4 sides
                            padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        // 000000 with 40% opacity as requested (No box shadow)
                        color: Colors.black.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Circular Icon Badge
                          Container(
                            padding: const EdgeInsets.all(13), // Keeps the circle tight
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIcons.presentationChart(), // Exactly 34 size
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 19),
                          
                          // Titles
                          Text(
                            "September Spentwrap",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w600, // SemiBold
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "See your performance in the\nlast month",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w500, // Medium
                              color: Colors.white.withOpacity(0.46), // White 46% opacity
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Checkout Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {}, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Checkout",
                                style: GoogleFonts.poppins(
                                  fontSize: 17, // Increased text size
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
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.6), 
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "Remind me later", // Updated text
                                style: GoogleFonts.poppins(
                                  fontSize: 17, // Increased text size
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

              // --- 4. Main SPENTWRAP Title ---
              Align(
                // Moves from dead center to exactly between the top edge and center box
                alignment: Alignment.lerp(
                  Alignment.center,
                  const Alignment(0, -0.70),
                  val,
                )!,
                child: Text(
                  "SPENTWRAP",
                  style: TextStyle(
                    fontFamily: 'CalcioDemo',
                    // Starts at 75, shrinks smoothly to exactly 56 (larger than before)
                    fontSize: lerpDouble(75, 60, val),
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
    );
  }

  // --- Helper Widget: Hollow Text with Stroke ---
  Widget _buildHollowText() {
    return Text(
      "WRAP",
      style: TextStyle(
        fontFamily: 'CalcioDemo',
        fontSize: 160, // Massive background size
        letterSpacing: 1.0,
        height: 1.0,
        // The magic properties that make the text outline-only
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.15), // Faint white outline
      ),
    );
  }
}