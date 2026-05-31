import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';
import 'features_unlocked_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _textSlideController;

  @override
  void initState() {
    super.initState();

    // PERFECT SYNC: Matches the 1500ms circle expansion from the first screen exactly
    _textSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Starts sliding the instant the screen is built (perfectly parallel with the circle expansion)
    _textSlideController.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            // LAG FIX: opaque: true tells Flutter to stop rendering the massive 40x circle
            // underneath the next screen. This frees up the GPU and makes the green fade buttery smooth!
            opaque: true,
            transitionDuration: const Duration(milliseconds: 1200),
            pageBuilder: (_, __, ___) => const FeaturesUnlockedScreen(),
            transitionsBuilder: (_, animation, __, child) => child,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _textSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ==========================================
          // LAYER 1: IN-PLACE EXPANDING CIRCLE & FADING CHECKMARK
          // ==========================================
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // The Expanding Circle
                    Hero(
                      tag: 'bg_circle',
                      flightShuttleBuilder:
                          (context, animation, direction, from, to) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (context, child) {
                                final scale =
                                    Tween<double>(
                                      begin: 1.0,
                                      end: 40.0,
                                    ).evaluate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOutCubic,
                                      ),
                                    );
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                      child: Transform.scale(
                        scale: 40.0,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // The Fading Checkmark
                    Hero(
                      tag: 'checkmark_circle',
                      flightShuttleBuilder:
                          (context, animation, direction, from, to) {
                            return FadeTransition(
                              opacity: Tween<double>(begin: 1.0, end: 0.0)
                                  .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                              child: from.widget,
                            );
                          },
                      child: const SizedBox(width: 70, height: 70),
                    ),
                  ],
                ),

                // INVISIBLE DUMMY TEXT: Locks the circle in the absolute center so it never slides down
                const SizedBox(height: 31),
                Text(
                  "Payment Successful",
                  style: GoogleFonts.montserrat(
                    fontSize: 22.74,
                    color: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  "Your 7-day Pro trial has started successfully\nCancel anytime from settings",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.transparent,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Next billing date: 06 Mar 2026",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // LAYER 2: THE VISIBLE SLIDING TEXT (TO EXACT MIDDLE)
          // ==========================================
          Align(
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _textSlideController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    Tween<double>(
                          begin:
                              screenHeight, // Starts fully off-screen at the bottom
                          end: 0.0, // Stops perfectly dead center
                        )
                        .animate(
                          CurvedAnimation(
                            parent: _textSlideController,
                            curve: Curves.easeOutCubic,
                          ),
                        )
                        .value,
                  ),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'shared_welcome_title',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        "Welcome Pranav",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colwhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Hero(
                    tag: 'shared_welcome_subtitle',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        "You've unlocked deeper clarity and\nsmarter growth.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inputFill,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
