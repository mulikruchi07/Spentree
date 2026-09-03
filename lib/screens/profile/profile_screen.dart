import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/biometric_service.dart';
import 'package:spentree/core/entitlement_service.dart';
import 'package:spentree/core/pro_upgrade_sheet.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/buckets/buckets_screen.dart';
import 'package:spentree/screens/buckets/slide_route.dart';
import 'package:spentree/screens/budget/budgets_screen.dart';
import 'package:spentree/screens/profile/account_screen.dart';
import 'package:spentree/screens/subscription/already_subscribed_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'data_privacy_screen.dart';
import 'helpdesk_screen.dart';
import '../../core/user_profile.dart';
import 'package:spentree/screens/private/private_transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _plantingSince = "";

  @override
  void initState() {
    super.initState();
    _loadPlantingSince();
  }

  void _loadPlantingSince() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final created = DateTime.parse(user.createdAt).toLocal();

    setState(() {
      _plantingSince =
          "Planting since ${_monthName(created.month)} ${created.year}";
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return ListenableBuilder(
          listenable: EntitlementService(),
          builder: (context, _) {
            final bool isPro = EntitlementService().isProForCurrentUser;

            return Scaffold(
              backgroundColor: AppColors.bgWhite,
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 70),

                      // ── Header ───────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My",
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.colblack,
                                ),
                              ),
                              Text(
                                "Profile",
                                style: GoogleFonts.montserrat(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.colblack,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Padding(padding: const EdgeInsets.only(bottom: 8.0)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── User Card ────────────────────────────────────────────
                      ValueListenableBuilder<UserProfile>(
                        valueListenable: userProfileNotifier,
                        builder: (context, profile, _) {
                          return Material(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AccountScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(15),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.inputFill,
                                        border: Border.all(
                                          color: const Color.fromARGB(
                                            255,
                                            182,
                                            181,
                                            181,
                                          ).withOpacity(0.5),
                                          width: 1.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: profile.imageBytes != null
                                          ? Image.memory(
                                              profile.imageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(
                                              child: Icon(
                                                PhosphorIconsRegular.user,
                                                size: 35,
                                                color: AppColors.grey600,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  profile.firstName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.colblack,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isPro) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors
                                                            .primaryGreen,
                                                      ),
                                                  child: Icon(
                                                    PhosphorIconsFill.star,
                                                    size: 12,
                                                    color: AppColors.colwhite,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _plantingSince,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.white500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.desctext,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Settings List ────────────────────────────────────────
                      _buildProSettingsItem(context, isPro),
                      _buildSettingsItem(
                        PhosphorIconsRegular.shieldCheck,
                        "Data & Privacy",
                        "Manage your data & privacy",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DataPrivacyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        PhosphorIconsRegular.question,
                        "Helpdesk & FAQ",
                        "Further secure your account for safety",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpdeskScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        PhosphorIconsRegular.info,
                        "About Us",
                        "Further secure your account for safety",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsItem(
                        PhosphorIconsRegular.envelopeSimple,
                        "Contact Us",
                        "Get in touch with us",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ContactScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      Divider(color: AppColors.divider, thickness: 1),
                      const SizedBox(height: 20),

                      // ── Footer ───────────────────────────────────────────────
                      Center(
                        child: Text(
                          "Planted with love in Mumbai, India",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String t,
    String s,
    VoidCallback tap,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.colIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppColors.colblack),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.desctext,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.desctext),
          ],
        ),
      ),
    ),
  );

  Widget _buildProSettingsItem(BuildContext context, bool isPro) {
    if (!isPro) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            showProUpgradeSheet(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.colwhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIconsFill.star,
                    size: 28,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Spentree Pro",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colwhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Unlock premium features & rewards",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.colwhite.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppColors.colwhite),
              ],
            ),
          ),
        ),
      );
    }

    // Expanded Pro Features Box
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlreadySubscribedScreen(),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.colwhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsFill.star,
                      size: 28,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Spentree Pro",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colwhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Manage your active membership",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.colwhite.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.colwhite),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: AppColors.colwhite.withOpacity(0.3),
              thickness: 1,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildProFeatureCard(
            title: "Smart Budgets",
            subtitle: "Set monthly limits for every category.",
            icon: PhosphorIconsRegular.treeStructure,
            onTap: () {
              if (EntitlementService().isProForCurrentUser) {
                Navigator.push(context, slideRoute(const BudgetsScreen()));
              } else {
                showProUpgradeSheet(context);
              }
            },
          ),
          _buildProFeatureCard(
            title: "Personal Transactions",
            subtitle: "Track personal expenses privately.",
            icon: PhosphorIconsRegular.vault,
            onTap: () {
              if (EntitlementService().isProForCurrentUser) {
                Navigator.push(context, slideRoute(const PrivateTransactionsScreen()));
              } else {
                showProUpgradeSheet(context);
              }
            },
          ),
          _buildProFeatureCard(
            title: "Create Buckets",
            subtitle: "Group expenses by events & more.",
            icon: PhosphorIconsRegular.archive,
            onTap: () {
              if (EntitlementService().isProForCurrentUser) {
                Navigator.push(context, slideRoute(const BucketsScreen()));
              } else {
                showProUpgradeSheet(context);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F8E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.colwhite, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.desctext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.desctext),
            ],
          ),
        ),
      ),
    );
  }
}
