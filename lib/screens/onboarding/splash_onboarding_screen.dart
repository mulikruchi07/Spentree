import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_screen.dart';

class SplashOnboardingScreen extends StatefulWidget {
  const SplashOnboardingScreen({super.key});

  @override
  State<SplashOnboardingScreen> createState() => _SplashOnboardingScreenState();
}

class _SplashOnboardingScreenState extends State<SplashOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Alignment> _textAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _textAlignmentAnimation =
        Tween<Alignment>(
          begin: const Alignment(0.0, 0.15),
          end: Alignment.center,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.8, curve: Curves.easeIn),
      ),
    );

    _startAnimationSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/logo-name.png"), context);
    precacheImage(const AssetImage("assets/images/bg_room.png"), context);
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) await _controller.forward();

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1200),
            pageBuilder: (_, __, ___) => const OnboardingScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  Image.asset(
                    "assets/logo.png",
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(flex: 3),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HERO: Logo Flight Start
                      Hero(
                        tag: 'logo-image',
                        flightShuttleBuilder:
                            (
                              flightContext,
                              animation,
                              direction,
                              fromContext,
                              toContext,
                            ) {
                              return Material(
                                color: Colors.transparent,
                                child: Image.asset(
                                  "assets/logo-name.png",
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                        child: Image.asset(
                          "assets/appname.png",
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Grow trees, not expenses",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          // Green Dot Layer
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        if (_scaleAnimation.value == 0)
                          return const SizedBox.shrink();
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(flex: 5),
              ],
            ),
          ),
          // Welcome Text Layer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: _textAlignmentAnimation.value,
                child: Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Hero(
                    tag: 'welcome-text',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        "Welcome to SpenTree",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
