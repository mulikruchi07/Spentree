import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';

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
  bool isCopied; // Mutable state

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

class _DealsScreenState extends State<DealsScreen> {
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
      isBlurred: true,
    ),
    DealModel(
      id: 'md_6',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Special Deal',
      offerSubtitle: 'Mystery box',
      isClaimable: false,
      isBlurred: true,
    ),
    DealModel(
      id: 'md_7',
      brandLogo: 'assets/images/deals/logo.png',
      productImage: 'assets/images/deals/items.png',
      offerTitle: 'Special Deal',
      offerSubtitle: 'Mystery box',
      isClaimable: false,
      isBlurred: true,
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
            const SizedBox(height: 45),

            _buildSectionHeader("Deal of the day", showStar: true),
            const SizedBox(height: 16),
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
      buttonColor = AppColors.primaryGreen;
    } else if (deal.isLockedWithSeeds) {
      buttonText = "3 more seeds";
      buttonColor = const Color(0xFFBDBDBD);
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
                onTap: () => _openDealExpanded(context, deal),
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
                        color: Colors.white,
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

    if (deal.isBlurred) {
      innerContent = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
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
              absoluteCutoutY: dividerY,
            ),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              color: const Color(0xFFFFFFFF),
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
                                    fontSize: 5.85,
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
                              onTap: () => _openDealExpanded(context, deal),
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
                                      color: Colors.white,
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
        imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
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
              color: const Color(0xFFFFFFFF),
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
              color: const Color(0xFFFFFFFF),
              child: Stack(
                children: [
                  // 1. PRODUCT IMAGE
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

                  // 2. BRAND LOGO
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

                  // 3. DOTTED DIVIDER
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

                  // 4. MATHEMATICALLY EQUAL BOTTOM LAYOUT (ANIMATION SAFE)
                  // SingleChildScrollView prevents RenderFlex errors during the flight
                  // It acts as a safe clipping boundary as the card expands.
                  Positioned(
                    top: dividerY,
                    bottom: 0,
                    left: 20,
                    right: 20,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: cardHeight - dividerY, // Exactly 280.0
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // TEXT BLOCK
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

                            // GREY CODE BOX
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
                                        setState(() {
                                          isCodeCopied = true;
                                        });
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

                            // EXPIRE TEXT
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
