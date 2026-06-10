import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spentree/core/app_style.dart';
import '../dashboard/dashboard_screen.dart';

class FeaturesUnlockedScreen extends StatelessWidget {
  const FeaturesUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final animation =
            ModalRoute.of(context)?.animation ??
            const AlwaysStoppedAnimation(1.0);
        final screenHeight = MediaQuery.of(context).size.height;
        final safePadding = MediaQuery.of(context).padding;

        // 1. Butter-smooth green fade
        final greenFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
          ),
        );

        // 2. Dashboard Button slides up securely
        final buttonSlideUp = Tween<double>(begin: screenHeight, end: 0.0)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
              ),
            );

        // 3. Cards slide up from deep below
        final listSlideUp = Tween<double>(begin: screenHeight * 1.5, end: 0.0)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
              ),
            );

        // Decorative ornaments
        final crownSlide =
            Tween<Offset>(
              begin: const Offset(-1.5, -0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final crownRotate = Tween<double>(begin: -0.5, end: 0.2).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        final diamondSlide =
            Tween<Offset>(
              begin: const Offset(1.5, -0.5),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final diamondRotate = Tween<double>(begin: 0.5, end: -0.2).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: Stack(
            children: [
              // ==========================================
              // LAYER 1: BASE WHITE SCREEN & ORNAMENTS
              // ==========================================
              Positioned.fill(child: Container(color: AppColors.bgWhite)),

              Positioned(
                top: 15,
                left: -20,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return SlideTransition(
                      position: crownSlide,
                      child: Transform.rotate(
                        angle: crownRotate.value,
                        child: Image.asset(
                          'assets/images/subs/crown.png',
                          width: 90,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: safePadding.top + 90,
                right: -30,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return SlideTransition(
                      position: diamondSlide,
                      child: Transform.rotate(
                        angle: diamondRotate.value,
                        child: Image.asset(
                          'assets/images/subs/diamond.png',
                          width: 90,
                          errorBuilder: (c, e, s) => const SizedBox(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ==========================================
              // LAYER 2: PINNED HEADER & SCROLLABLE LIST
              // ==========================================
              Positioned(
                top: 180,
                bottom: 0,
                left: 24,
                right: 24,
                child: AnimatedBuilder(
                  animation: listSlideUp,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, listSlideUp.value),
                    child: child,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Features Unlocked",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500, // Medium
                              color: AppColors.colblack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 140),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFeatureCard(
                                PhosphorIcons.clockCounterClockwise,
                                "Unlimited expense history",
                                "Access complete spending archive.",
                              ),
                              _buildFeatureCard(
                                PhosphorIcons.chartBar,
                                "Advanced analytics",
                                "Track deeper spending trends.",
                              ),
                              _buildFeatureCard(
                                PhosphorIcons.tree,
                                "Forest health insights",
                                "Understand your financial growth.",
                              ),
                              _buildFeatureCard(
                                PhosphorIcons.hourglass,
                                "Time-based pattern",
                                "Spot daily and monthly habits.",
                              ),
                              _buildFeatureCard(
                                PhosphorIcons.brain,
                                "Behavioural insights",
                                "See where money leaks.",
                              ),
                              _buildFeatureCard(
                                PhosphorIcons.tag,
                                "Member only deals",
                                "Unlock exclusive partner rewards.",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // LAYER 3: FIXED DASHBOARD BUTTON
              // ==========================================
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: buttonSlideUp,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, buttonSlideUp.value),
                    child: child,
                  ),
                  child: Container(
                    color: AppColors.bgWhite,
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 24,
                      right: 24,
                      bottom: safePadding.bottom > 0
                          ? safePadding.bottom + 8
                          : 38,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                "Go to Dashboard",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500, // Medium
                                  color: AppColors.colwhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Trial ends on 27 Feb 2026 • Cancel anytime from Settings",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w400, // Regular
                            color: const Color(0xFF808080),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================
              // LAYER 4: FADING GREEN OVERLAY
              // ==========================================
              IgnorePointer(
                child: FadeTransition(
                  opacity: greenFadeOut,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              // ==========================================
              // LAYER 5: FIXED TEXT HEROES (The Cross-Fade Fix)
              // ==========================================
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 70.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: 'shared_welcome_title',
                          flightShuttleBuilder:
                              (
                                flightContext,
                                flightAnimation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                return AnimatedBuilder(
                                  animation: flightAnimation,
                                  builder: (context, child) {
                                    // THE CROSS-FADE FIX: Overlays the White and Black text and perfectly cross-fades their opacities!
                                    // (.clamp ensures the opacity never accidentally goes below 0.0 or above 1.0)
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Fades OUT the White Text
                                        Opacity(
                                          opacity: (1.0 - flightAnimation.value)
                                              .clamp(0.0, 1.0),
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
                                        // Fades IN the Black Text
                                        Opacity(
                                          opacity: flightAnimation.value.clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: Text(
                                              "Welcome Pranav",
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.colblack,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              "Welcome Pranav",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colblack,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Hero(
                          tag: 'shared_welcome_subtitle',
                          flightShuttleBuilder:
                              (
                                flightContext,
                                flightAnimation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                return AnimatedBuilder(
                                  animation: flightAnimation,
                                  builder: (context, child) {
                                    // THE CROSS-FADE FIX for Subtitle
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Fades OUT the Off-White Text
                                        Opacity(
                                          opacity: (1.0 - flightAnimation.value)
                                              .clamp(0.0, 1.0),
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
                                        // Fades IN the Grey Text
                                        Opacity(
                                          opacity: flightAnimation.value.clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: Text(
                                              "You've unlocked deeper clarity and\nsmarter growth.",
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF808080),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              "You've unlocked deeper clarity and\nsmarter growth.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF808080),
                                height: 1.4,
                              ),
                            ),
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
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.navbar,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.colwhite, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFABABAB),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFABABAB)),
        ],
      ),
    );
  }
}
