// lib/screens/subscription/already_subscribed_screen.dart
//
// Shown when a user who is ALREADY Pro taps the "Spentree Pro" entry on the
// Profile screen. This is a deliberately static twin of
// FeaturesUnlockedScreen: same visual design (crown/diamond ornaments,
// feature cards, green CTA), but with:
//   - No Hero / fade / slide-in animations on the content itself.
//   - Only the HEADER (heading + "Features Unlocked" label, left-aligned)
//     is static/fixed. Everything else — the feature cards, "Go to
//     Dashboard", and "Cancel Subscription" — scrolls together as one
//     continuous list.
//   - Heading changed from "Welcome <name>" to "You have already
//     Subscribed", centered.
//   - This screen is pushed with the app's normal/default page transition
//     (same as AccountScreen, HelpdeskScreen, etc.) — see
//     profile_screen.dart, which does a plain MaterialPageRoute push.
//   - Both "Go to Dashboard" and "Cancel Subscription" are real Material
//     buttons (ElevatedButton / TextButton) so they get the same tactile
//     press/ripple feedback as the confirmation-popup buttons elsewhere in
//     this app (see the logout/delete confirmation dialog in
//     profile_screen.dart) — a plain GestureDetector+Container never gave
//     that feedback.
//   - "Cancel Subscription" has no border and no background fill — it only
//     shows color on press/tap (a TextButton overlay), per design. A TODO
//     marks where the real cancellation flow will be wired up later.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/system_ui_service.dart';

class AlreadySubscribedScreen extends StatelessWidget {
  const AlreadySubscribedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    SystemUIService.applyNavBarStyle(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        SystemUIService.applyNavBarStyle(context);
        final safePadding = MediaQuery.of(context).padding;

        return Scaffold(
          backgroundColor: AppColors.bgWhite,
          body: Stack(
            children: [
              // Decorative ornaments only — purely visual, positioned over
              // the whole screen. They never sit inside the Column, so
              // they can't affect layout, sizing, or scrolling. Each is
              // given a slight tilt to match the reference design (they
              // read as "straight" without this).
              Positioned(
                top: safePadding.top + 15,
                left: -30,
                child: Transform.rotate(
                  angle: 0.35, // ~ -20°, tilted like the reference crown.
                  child: Image.asset(
                    'assets/images/subs/crown.png',
                    width: 90,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                ),
              ),
              Positioned(
                top: safePadding.top + 90,
                right: -35,
                child: Transform.rotate(
                  angle: -0.26, // ~ +15°, tilted like the reference diamond.
                  child: Image.asset(
                    'assets/images/subs/diamond.png',
                    width: 90,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ==========================================
                    // STATIC HEADER — the ONLY part that never scrolls.
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "You have already\nSubscribed",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colblack,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            // Left-aligned, not centered.
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  PhosphorIconsFill.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  "Features Unlocked",
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.colblack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // ==========================================
                    // EVERYTHING BELOW SCROLLS TOGETHER: feature
                    // cards, Go to Dashboard, Cancel Subscription.
                    // ==========================================
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          0,
                          24,
                          safePadding.bottom > 0 ? safePadding.bottom + 24 : 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFeatureCard(
                              PhosphorIconsRegular.chartBar,
                              "Smart Budgets",
                              "Set monthly limits for every category.",
                            ),
                            _buildFeatureCard(
                              PhosphorIconsRegular.brain,
                              "Personalised Insights",
                              "Get personalized insights on your spending.",
                            ),
                            _buildFeatureCard(
                              Icons.inventory_2_outlined,
                              "Create Buckets",
                              "Group expenses by trips, events & more.",
                            ),
                            _buildFeatureCard(
                              Icons.ios_share_outlined,
                              "Unlimited Data Export",
                              "Export your complete spending history.",
                            ),
                            _buildFeatureCard(
                              PhosphorIconsRegular.tree,
                              "Extended Forest",
                              "Track your spending across 12 months.",
                            ),
                            _buildFeatureCard(
                              Icons.replay_outlined,
                              "Replay Spentwrap",
                              "Revisit your yearly financial recap anytime.",
                            ),

                            const SizedBox(height: 12),

                            // Go to Dashboard — solid green CTA, now a
                            // real ElevatedButton so it gets the same
                            // Material press/ripple feedback as the
                            // popup-dialog buttons elsewhere in the app.
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Returns to the app's root/dashboard
                                  // shell.
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Go to Dashboard",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.colwhite,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cancel Subscription — no border, no fill.
                            // Color only appears on press, via the
                            // TextButton's overlay/splash. TODO: wire this
                            // up to the real cancellation flow (e.g.
                            // deep-link into the App Store / Play Store
                            // subscription management page).
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: TextButton(
                                onPressed: () => _showCancelDialog(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.destructiveRed,
                                  backgroundColor: Colors.transparent,
                                  overlayColor: AppColors.destructiveRed
                                      .withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Cancel Subscription",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.destructiveRed,
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
              ),
            ],
          ),
        );
      },
    );
  }

  /// Same confirmation-dialog template used elsewhere in this app (see
  /// profile_screen.dart's confirmation popup) — same icon-circle, same
  /// title/message typography, same button colors and sizes. Kept short:
  /// one line of copy plus a checkbox, not a long paragraph.
  void _showCancelDialog(BuildContext context) {
    bool agreed = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.destructiveRed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        color: AppColors.colwhite,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Cancel Subscription?",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You'll lose Pro access right away.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.desctext,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => setDialogState(() => agreed = !agreed),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: agreed,
                              onChanged: (v) =>
                                  setDialogState(() => agreed = v ?? false),
                              activeColor: AppColors.destructiveRed,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "I agree to the cancellation policies",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.colblack,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        // TODO: wire this up to the real cancellation flow
                        // (e.g. deep-link into the App Store / Play Store
                        // subscription management page).
                        onPressed: agreed
                            ? () => Navigator.pop(dialogContext)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.destructiveRed,
                          disabledBackgroundColor: AppColors.destructiveRed
                              .withOpacity(0.35),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colwhite,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.inputFill,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Keep Subscription",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.destructiveRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Identical card styling to FeaturesUnlockedScreen's version — every
  /// text node has maxLines + overflow handling so this can never overflow
  /// or pixel-error regardless of device width or system font scale.
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
            alignment: Alignment.center,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
