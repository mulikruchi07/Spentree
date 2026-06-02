import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_style.dart';
import '../auth/sign_up_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  int _textIndex = 0;
  late Timer _timer;
  late AnimationController _rotationController;

  final List<String> _loadingTexts = [
    "Personalizing your forest...",
    "Syncing your spending...",
    "Growing your progress...",
    "Preparing your insights...",
    "Almost there...",
  ];

  @override
  void initState() {
    super.initState();

    // 1. Setup Rotation Animation (Slower & Smoother)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // 2 Seconds for full rotation
    )..repeat(); // Loop forever

    // 2. Start Text Sequence
    _startLoadingSequence();
  }

  void _startLoadingSequence() {
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (timer) {
      if (_textIndex < _loadingTexts.length - 1) {
        setState(() {
          _textIndex++;
        });
      } else {
        _timer.cancel();
        _navigateToNext();
      }
    });
  }

  void _navigateToNext() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- CUSTOM ROTATING WHEEL ---
              RotationTransition(
                turns: _rotationController,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: 0.25, // Static 75% Arc (Creates the "C" shape)
                    strokeWidth: 8, // Thicker stroke
                    strokeCap: StrokeCap.round, // Curved edges
                    color: AppColors.primaryGreen,
                    backgroundColor:
                        AppColors.inputFill, // Light grey track behind
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- ANIMATED TEXT ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _loadingTexts[_textIndex],
                  key: ValueKey<String>(_loadingTexts[_textIndex]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
