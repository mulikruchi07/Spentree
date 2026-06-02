import 'dart:ui';
import 'package:flutter/gestures.dart'; // Added for clickable T&C links
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/screens/profile/privacy_screen.dart';
import 'package:spentree/screens/profile/terms_screen.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

// --- DATA MODEL FOR DYNAMIC RENDERING & STATE ---
class DealModel {
  final String id;
  final String brandLogo;
  final String productImage;
  final String offerTitle;
  final String offerSubtitle;
  final bool isClaimable;
  final String? description;
  final bool isBlurred;
  final bool isLockedWithSeeds;
  bool isCopied;

  DealModel({
    required this.id,
    required this.brandLogo,
    required this.productImage,
    required this.offerTitle,
    required this.offerSubtitle,
    required this.isClaimable,
    this.description,
    this.isBlurred = false,
    this.isLockedWithSeeds = false,
    this.isCopied = false,
  });
}

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with TickerProviderStateMixin {
  // --- MOCK DATA SETS ---

  late List<DealModel> _crowdFavourites = [
    DealModel(
      id: 'cf_1',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Flat 10% off',
      offerSubtitle: 'on motorsport\nsneakers',
      isClaimable: true,
    ),
    DealModel(
      id: 'cf_2',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Flat 15% off',
      offerSubtitle: 'on collection of\nsilver jewellery',
      isClaimable: true,
    ),
    DealModel(
      id: 'cf_3',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Upto 10% off',
      offerSubtitle: 'on face products',
      isClaimable: true,
    ),
    DealModel(
      id: 'cf_4',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Flat 20% off',
      offerSubtitle: 'on running shoes',
      isClaimable: false,
      isLockedWithSeeds: true,
    ),
    DealModel(
      id: 'cf_5',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Flat 25% off',
      offerSubtitle: 'on winter wear',
      isClaimable: false,
      isLockedWithSeeds: true,
    ),
    DealModel(
      id: 'cf_6',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Upto 50% off',
      offerSubtitle: 'on accessories',
      isClaimable: false,
      isLockedWithSeeds: true,
    ),
  ];

  late List<DealModel> _memberDrops = [
    DealModel(
      id: 'md_1',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Free Product',
      offerSubtitle: 'on purchase of 2499',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_2',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Upto 30% off',
      offerSubtitle: 'on Cherry Blossoms',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_3',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Flat 40% off',
      offerSubtitle: 'on electronics',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_4',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Buy 1 Get 1',
      offerSubtitle: 'on t-shirts',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_5',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Special Deal',
      offerSubtitle: 'Mystery box',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_6',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Special Deal',
      offerSubtitle: 'Mystery box',
      isClaimable: false,
    ),
    DealModel(
      id: 'md_7',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Special Deal',
      offerSubtitle: 'Mystery box',
      isClaimable: false,
    ),
  ];

  final DealModel _dealOfTheDay = DealModel(
    id: 'dotd_1',
    brandLogo: 'assets/images/deals/logo.png',
    productImage: 'assets/images/deals/items.png',
    offerTitle: 'Flat 50% off',
    offerSubtitle: 'on earphones',
    description:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna.',
    isClaimable: false,
  );

  bool _isBottomSheetOpen = false;
  late AnimationController _bottomSheetController;

  void _handleDealCopied(DealModel copiedDeal) {
    setState(() {
      copiedDeal.isCopied = true;
      int index = _crowdFavourites.indexWhere((d) => d.id == copiedDeal.id);
      if (index != -1) {
        _crowdFavourites.removeAt(index);
        int insertIndex = _crowdFavourites.indexWhere(
          (d) => d.isLockedWithSeeds,
        );
        if (insertIndex == -1) insertIndex = _crowdFavourites.length;
        _crowdFavourites.insert(insertIndex, copiedDeal);
      }
    });
  }

  void _openDealExpanded(BuildContext context, DealModel deal) {
    if (!deal.isClaimable && !deal.isCopied) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ExpandedDealOverlay(
            deal: deal,
            onCopied: () => _handleDealCopied(deal),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  // --- MEMBERSHIP BOTTOM SHEET ---
  void _showMembershipBottomSheet() {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Local state for the selectable plans inside the bottom sheet
        int selectedPlanIndex = 0; // 0 for Annual, 1 for Monthly

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: AppColors.colwhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scrollable Inner Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Spentree Pro",
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500, // Medium
                                  color: AppColors.colblack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Unlock smarter insights and grow your\nmoney with clarity.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12, // Reduced size
                              fontWeight: FontWeight.w400, // Regular
                              color: const Color(0xFF808080), // Specific grey
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Table Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Feature",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                  ),
                                ),
                              ), // SemiBold 14
                              SizedBox(
                                width: 60,
                                child: Center(
                                  child: Text(
                                    "Basic",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.colblack,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text(
                                    "Pro",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.colblack,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Reduced gap and exact divider spec
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(
                              color: Color(0xFF808080),
                              thickness: 0.5,
                            ),
                          ),

                          // Features Map
                          ...[
                            "Unlimited expense history",
                            "Advanced analytics",
                            "Forest health insights",
                            "Time-based pattern",
                            "Behavioural insights",
                            "Member only deals",
                          ].map(
                            (feature) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: 15.0,
                              ), // Reduced gap between context elements
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFF4F4F4F),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ), // Medium 12, 4f4f4f
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: Icon(
                                        Icons.close,
                                        color: const Color(0xFF717171),
                                        size: 20,
                                      ),
                                    ), // 717171 Cross
                                  ),
                                  const SizedBox(
                                    width: 50,
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        color: AppColors.primaryGreen,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Annual Plan Card (Selectable)
                          GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedPlanIndex = 0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navbar,
                                border: Border.all(
                                  color: selectedPlanIndex == 0
                                      ? AppColors.primaryGreen
                                      : const Color(0xFFD7D8D6),
                                  width: selectedPlanIndex == 0 ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selectedPlanIndex == 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Annual Plan",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: selectedPlanIndex == 0
                                          ? AppColors.primaryGreen
                                          : const Color(0xFFBABABA),
                                    ),
                                  ), // SemiBold 16
                                  const SizedBox(height: 4),
                                  Text(
                                    "30 days free - Then ₹1499/Year",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: selectedPlanIndex == 0
                                          ? AppColors.primaryGreen.withOpacity(
                                              0.8,
                                            )
                                          : const Color(0xFF808080),
                                    ),
                                  ), // Inter Regular 12
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ), // Decreased gap between buttons
                          // Monthly Plan Card (Selectable)
                          GestureDetector(
                            onTap: () {
                              setSheetState(() => selectedPlanIndex = 1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: selectedPlanIndex == 1
                                      ? AppColors.primaryGreen
                                      : const Color(0xFFD7D8D6),
                                  width: selectedPlanIndex == 1 ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: selectedPlanIndex == 1
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Monthly Plan",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: selectedPlanIndex == 1
                                          ? AppColors.primaryGreen
                                          : const Color(0xFFBABABA),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "7 days free - Then ₹199/Month",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: selectedPlanIndex == 1
                                          ? AppColors.primaryGreen.withOpacity(
                                              0.8,
                                            )
                                          : const Color(0xFF808080),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Green CTA Button
                          GestureDetector(
                            onTap: () {
                              // Handle subscription action here
                              debugPrint(
                                "Started Trial for Plan: $selectedPlanIndex",
                              );
                              Navigator.pop(
                                context,
                              ); // Optional: close sheet on start
                            },
                            child: Container(
                              height: 54,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  "Start 30 days free trial",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Clickable T&C Footer
                          // Clickable T&C Footer
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      "By placing this order, you agree to the ",
                                ),
                                TextSpan(
                                  text: "Terms of Service",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Open Terms Screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TermsScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy\nPolicy",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // Open Privacy Screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PrivacyScreen(),
                                        ),
                                      );
                                    },
                                ),
                                const TextSpan(
                                  text:
                                      ". Subscription automatically renews unless auto-renew is turned\noff at least 24-hours before the end of the current period.",
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _isBottomSheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Great",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    "Deals",
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            _buildSectionHeader("Crowd Favourites", showStar: false),
            const SizedBox(height: 24),
            SizedBox(
              height: 228,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _crowdFavourites.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15.0, bottom: 8),
                    child: _buildSmallDealCard(_crowdFavourites[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 34),

            _buildSectionHeader("Member only drops", showStar: true),
            const SizedBox(height: 14),
            SizedBox(
              height: 228,
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >
                      notification.metrics.maxScrollExtent + 40) {
                    _showMembershipBottomSheet();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _memberDrops.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 15.0, bottom: 8.0),
                      child: _buildSmallDealCard(_memberDrops[index]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 43),

            _buildSectionHeader("Deal of the day", showStar: true),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildBigDealCard(_dealOfTheDay),
            ),
            const SizedBox(height: 70),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildFooter(),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool showStar}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.colblack,
            ),
          ),
          if (showStar) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmallDealCard(DealModel deal) {
    const double cardWidth = 154.0;
    const double cardHeight = 202.0;
    const double cornerRadius = 11.44;
    const double dividerY = 122.0;

    String buttonText;
    Color buttonColor;
    if (deal.isCopied) {
      buttonText = "Copied";
      buttonColor = const Color(0xFFFFCC00);
    } else if (deal.isLockedWithSeeds) {
      buttonText = "Claim";
      buttonColor = AppColors.primaryGreen;
    } else if (deal.isClaimable) {
      buttonText = "Claim";
      buttonColor = AppColors.primaryGreen;
    } else {
      buttonText = "Unlock";
      buttonColor = const Color(0xFFBDBDBD);
    }

    Widget innerContent = Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 85.0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(cornerRadius),
              topRight: Radius.circular(cornerRadius),
            ),
            child: Image.asset(deal.productImage, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 93.0,
          left: 0,
          right: 0,
          height: 21.0,
          child: Center(
            child: Image.asset(
              deal.brandLogo,
              height: 21.0,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: dividerY - (0.48 / 2),
          left: 12,
          right: 12,
          child: CustomPaint(
            painter: SharedDottedLinePainter(isVertical: false),
            size: const Size(double.infinity, 1),
          ),
        ),
        Positioned(
          top: dividerY,
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deal.offerTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 10.84,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        deal.offerSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF656565),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (buttonText == "Unlock") {
                    _showMembershipBottomSheet();
                  } else if (buttonText == "Claim" || buttonText == "Copied") {
                    _openDealExpanded(context, deal);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15.0),
                  height: 26.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(7.38),
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.poppins(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colwhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (deal.isBlurred || deal.isLockedWithSeeds) {
      innerContent = ClipRect(
        child: Stack(
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10.4, sigmaY: 10.4),
              child: innerContent,
            ),
            Container(color: AppColors.bgWhite.withOpacity(0.4)),
          ],
        ),
      );
    }

    if (deal.isLockedWithSeeds) {
      innerContent = Stack(
        children: [
          innerContent, // The blurred card
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.lock, color: AppColors.unlockst, size: 28),
                const SizedBox(height: 4),
                Text(
                  "Unlocks at\nLevel 9",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500, // Medium
                    color: AppColors.unlockst,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Hero(
      tag: deal.id,
      child: Material(
        type: MaterialType.transparency,
        child: CustomPaint(
          painter: TicketOuterShadowPainter(cornerRadius: cornerRadius),
          child: ClipPath(
            clipper: TicketShapeClipper(
              cornerRadius: cornerRadius,
              cutoutRadius: 8.0,
              absoluteCutoutY: dividerY,
            ),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              color: AppColors.navbar,
              child: innerContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBigDealCard(DealModel deal) {
    const double cardHeight = 218.0;
    const double cornerRadius = 11.44;
    const double absoluteCutoutY = cardHeight / 2;

    Widget innerContent = Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.0),
                  child: Image.asset(deal.productImage, fit: BoxFit.cover),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 16.0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: constraints.maxWidth - 20,
                        height: cardHeight - 32,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              child: Image.asset(
                                deal.brandLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  deal.offerTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10.84,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  deal.offerSubtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9.03,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF656565),
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                              ),
                              child: SizedBox(
                                width: 145,
                                child: Text(
                                  deal.description ?? "",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    height: 1.3,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF656565),
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (!deal.isClaimable) {
                                  _showMembershipBottomSheet();
                                } else {
                                  _openDealExpanded(context, deal);
                                }
                              },
                              child: Container(
                                width: 145,
                                height: 26.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBDBDBD),
                                  borderRadius: BorderRadius.circular(7.38),
                                ),
                                child: Align(
                                  alignment: const Alignment(0, -0.15),
                                  child: Text(
                                    "Unlock",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.colwhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 12,
          bottom: 12,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              painter: SharedDottedLinePainter(isVertical: true),
              size: const Size(1, double.infinity),
            ),
          ),
        ),
      ],
    );

    if (deal.isBlurred) {
      innerContent = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 10.5, sigmaY: 10.5),
        child: innerContent,
      );
    }

    return Hero(
      tag: deal.id,
      child: Material(
        type: MaterialType.transparency,
        child: CustomPaint(
          painter: TicketOuterShadowPainter(cornerRadius: cornerRadius),
          child: ClipPath(
            clipper: TicketShapeClipper(
              cornerRadius: cornerRadius,
              cutoutRadius: 8.0,
              absoluteCutoutY: absoluteCutoutY,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              height: cardHeight,
              color: AppColors.navbar,
              child: innerContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.white500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
            children: [
              const TextSpan(
                text: "Designed by ",
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
              TextSpan(
                text: "Designer",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w200,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
            children: [
              const TextSpan(
                text: "Developed by ",
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
              TextSpan(
                text: "Developer",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w200,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// --- THE EXPANDED HERO OVERLAY ---
// -------------------------------------------------------------------------

class ExpandedDealOverlay extends StatefulWidget {
  final DealModel deal;
  final VoidCallback onCopied;

  const ExpandedDealOverlay({
    super.key,
    required this.deal,
    required this.onCopied,
  });

  @override
  State<ExpandedDealOverlay> createState() => _ExpandedDealOverlayState();
}

class _ExpandedDealOverlayState extends State<ExpandedDealOverlay> {
  late bool isCodeCopied;

  @override
  void initState() {
    super.initState();
    isCodeCopied = widget.deal.isCopied;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Great",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colblack,
                          ),
                        ),
                        Text(
                          "Deals",
                          style: GoogleFonts.montserrat(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildExpandedCard(context),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: _buildDetailsSection(),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedCard(BuildContext context) {
    const double cardHeight = 560.0;
    const double cornerRadius = 26.08;
    const double dividerY = 280.0;

    return Hero(
      tag: widget.deal.id,
      child: Material(
        type: MaterialType.transparency,
        child: CustomPaint(
          painter: TicketOuterShadowPainter(cornerRadius: cornerRadius),
          child: ClipPath(
            clipper: TicketShapeClipper(
              cornerRadius: cornerRadius,
              cutoutRadius: 10.0,
              absoluteCutoutY: dividerY,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width - 48,
              height: cardHeight,
              color: AppColors.navbar,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 190.0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(cornerRadius),
                        topRight: Radius.circular(cornerRadius),
                      ),
                      child: Image.asset(
                        widget.deal.productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 190.0,
                    left: 0,
                    right: 0,
                    height: dividerY - 190.0,
                    child: Center(
                      child: Image.asset(
                        widget.deal.brandLogo,
                        height: 44.0,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const SizedBox(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: dividerY - (1.09 / 2),
                    left: 20,
                    right: 20,
                    child: CustomPaint(
                      painter: SharedDottedLinePainter(
                        isVertical: false,
                        strokeWidth: 1.09,
                      ),
                      size: const Size(double.infinity, 1),
                    ),
                  ),
                  Positioned(
                    top: dividerY,
                    bottom: 0,
                    left: 20,
                    right: 20,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: cardHeight - dividerY,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.deal.offerTitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 19.33,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.deal.offerSubtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF656565),
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              height: 110.0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1F1),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "Special Code :",
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF656565),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              "***************",
                                              style: GoogleFonts.montserrat(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF656565),
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  GestureDetector(
                                    onTap: () {
                                      if (!isCodeCopied) {
                                        Clipboard.setData(
                                          const ClipboardData(
                                            text: "PUMA10OFF",
                                          ),
                                        );
                                        setState(() => isCodeCopied = true);
                                        widget.onCopied();
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 50.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryGreen,
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          isCodeCopied
                                              ? "Code Copied!"
                                              : "Copy Code",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "Expires on 00 March 2026",
                              style: GoogleFonts.montserrat(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF858585),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How to redeem",
          style: GoogleFonts.poppins(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF656565),
          ),
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 26.0),
          child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
        ),
        Text(
          "Terms and Conditions",
          style: GoogleFonts.poppins(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF656565),
          ),
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna",
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0, right: 8.0),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF858585),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF858585),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------
// --- MATHEMATICAL CLIPPERS & PAINTERS ---
// -------------------------------------------------------------------------

class TicketShapeClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double cutoutRadius;
  final double absoluteCutoutY;

  TicketShapeClipper({
    required this.cornerRadius,
    required this.cutoutRadius,
    required this.absoluteCutoutY,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(size.width, absoluteCutoutY - cutoutRadius);
    path.arcToPoint(
      Offset(size.width, absoluteCutoutY + cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    path.lineTo(0, absoluteCutoutY + cutoutRadius);
    path.arcToPoint(
      Offset(0, absoluteCutoutY - cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );
    path.lineTo(0, cornerRadius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class TicketOuterShadowPainter extends CustomPainter {
  final double cornerRadius;
  TicketOuterShadowPainter({required this.cornerRadius});
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
    final rectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius),
        ),
      );
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(rectPath, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SharedDottedLinePainter extends CustomPainter {
  final bool isVertical;
  final double strokeWidth;
  SharedDottedLinePainter({required this.isVertical, this.strokeWidth = 0.48});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF858585)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final maxDimension = isVertical ? size.height : size.width;
    const double dashWidth = 3.0;
    const double dashSpace = 3.0;
    double currentPosition = 0;
    while (currentPosition < maxDimension) {
      if (isVertical) {
        canvas.drawLine(
          Offset(0, currentPosition),
          Offset(0, currentPosition + dashWidth),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(currentPosition, 0),
          Offset(currentPosition + dashWidth, 0),
          paint,
        );
      }
      currentPosition += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
