import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/entitlement_service.dart';
import 'package:spentree/core/pro_upgrade_sheet.dart';
import 'package:spentree/core/user_profile.dart';
import 'welcome_screen.dart';
import '../../core/system_ui_service.dart'; // FIX: opaque nav bar on this screen

class PaymentSuccessfulScreen extends StatefulWidget {
  const PaymentSuccessfulScreen({super.key});

  @override
  State<PaymentSuccessfulScreen> createState() =>
      _PaymentSuccessfulScreenState();
}

class _PaymentSuccessfulScreenState extends State<PaymentSuccessfulScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemUIService.applyNavBarStyle(
      context,
    ); // FIX: fires on first build & theme changes
  }

  @override
  void initState() {
    super.initState();
    // Holds the screen for 1.5 seconds, then starts the SLOW, gradual expansion
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            opaque: false,
            transitionDuration: const Duration(
              milliseconds: 1500,
            ), // Smooth 1.5s transition
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, animation, __, child) => child,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    final entitlement = EntitlementService();
    final trialDays = entitlement.trialPlan == 'annual' ? 30 : 7;
    final trialEndsText = entitlement.trialEndsAt != null
        ? formatTrialDate(entitlement.trialEndsAt!)
        : null;
    final nextBillingText = entitlement.nextBillingAt != null
        ? formatTrialDate(entitlement.nextBillingAt!)
        : null;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                // HIDDEN PRELOADER
                Opacity(
                  opacity: 0.0,
                  child: Text(
                    "Preload",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),

                // MAIN CONTENT
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Hero(
                            tag: 'bg_circle',
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen.withOpacity(
                                      0.15,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'checkmark_circle',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.colwhite,
                                    width: 2.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: AppColors.colwhite,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 31),
                      Text(
                        "Payment Successful",
                        style: GoogleFonts.montserrat(
                          fontSize: 22.74,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        // Cancellation-policy line removed — Spentree has no
                        // cancellation flow yet, so we don't claim one exists.
                        "Your $trialDays-day Pro trial has started successfully",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF787878),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (trialEndsText != null)
                        Text(
                          "Trial ends: $trialEndsText",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF787878),
                          ),
                        ),
                      if (nextBillingText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Next billing date: $nextBillingText",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF787878),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ==========================================
                // OFF-SCREEN HEROS (Triggers the slide up!)
                // ==========================================
                Positioned(
                  top: MediaQuery.of(context)
                      .size
                      .height, // Places it completely off-screen at the bottom
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'shared_welcome_title',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            "Welcome ${userProfileNotifier.value.firstName}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors
                                  .transparent, // Invisible here so it smoothly transitions to white
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
                              color: Colors.transparent,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
