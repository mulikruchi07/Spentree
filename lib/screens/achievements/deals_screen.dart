import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/app_style.dart';

// --- DATA MODEL ---
// Use this model to easily plug in your backend API data later
class DealModel {
  final String brandLogo;
  final String productImage;
  final String offerTitle;
  final String offerSubtitle;
  final bool
  isClaimable; // true = Green 'Claim' button | false = Grey 'Unlock' button
  final String? description; // Specific to the large "Deal of the day" card

  DealModel({
    required this.brandLogo,
    required this.productImage,
    required this.offerTitle,
    required this.offerSubtitle,
    required this.isClaimable,
    this.description,
  });
}

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  // --- MOCK DATA ---
  final List<DealModel> _crowdFavourites = [
    DealModel(
      brandLogo: 'assets/images/deals/puma_logo.png',
      productImage: 'assets/images/deals/puma_shoes.png',
      offerTitle: 'Flat 10% off',
      offerSubtitle: 'on motorsport\nsneakers',
      isClaimable: true,
    ),
    DealModel(
      brandLogo: 'assets/images/deals/giva_logo.png',
      productImage: 'assets/images/deals/giva_jewelry.png',
      offerTitle: 'Flat 15% off',
      offerSubtitle: 'on collection of\nsilver jewellery',
      isClaimable: true,
    ),
    DealModel(
      brandLogo: 'assets/images/deals/mamaearth_logo.png',
      productImage: 'assets/images/deals/mamaearth_product.png',
      offerTitle: 'Upto 10% off',
      offerSubtitle: 'on face products',
      isClaimable: true,
    ),
    DealModel(
      brandLogo: 'assets/images/deals/boat_logo.png',
      productImage: 'assets/images/deals/boat_earbuds.png',
      offerTitle: 'Flat Rs.500 off',
      offerSubtitle: 'on Nirvana range\nTWS',
      isClaimable: true,
    ),
  ];

  final List<DealModel> _memberDrops = [
    DealModel(
      brandLogo: 'assets/images/deals/mamaearth_logo.png',
      productImage: 'assets/images/deals/mamaearth_bundle.png',
      offerTitle: 'Free Product',
      offerSubtitle: 'on purchase of 2499\nor above',
      isClaimable: false,
    ),
    DealModel(
      brandLogo: 'assets/images/deals/tripadvisor_logo.png',
      productImage: 'assets/images/deals/japan_cherry.png',
      offerTitle: 'Upto 30% off',
      offerSubtitle: 'on Japan Cherry\nBlossoms',
      isClaimable: false,
    ),
  ];

  final DealModel _dealOfTheDay = DealModel(
    brandLogo: 'assets/images/deals/goboult_logo.png',
    productImage: 'assets/images/deals/goboult_headphones.png',
    offerTitle: 'Flat 50% off',
    offerSubtitle: 'on Headphones',
    description:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna.',
    isClaimable: false,
  );

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

            // --- 1. HEADER ---
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
            const SizedBox(height: 32),

            // --- 2. CROWD FAVOURITES ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Crowd Favourites",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250, // Card height + shadow padding
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _crowdFavourites.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildSmallTicketCard(_crowdFavourites[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. MEMBER ONLY DROPS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    "Member only drops",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _memberDrops.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildSmallTicketCard(_memberDrops[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // --- 4. DEAL OF THE DAY ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    "Deal of the day",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildBigTicketCard(_dealOfTheDay),
            ),
            const SizedBox(height: 40),

            // --- 5. FOOTER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildFooter(),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildSmallTicketCard(DealModel deal) {
    const double cardWidth = 150.0;
    const double cardHeight = 230.0;
    const double cutoutY = 125.0; // The exact Y position of the dotted line

    return CustomPaint(
      painter: TicketShadowPainter(
        clipper: TicketClipper(cutoutPosition: cutoutY),
      ),
      child: ClipPath(
        clipper: TicketClipper(cutoutPosition: cutoutY),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          color: Colors.white,
          child: Stack(
            children: [
              Column(
                children: [
                  // 1. Product Image (Top half)
                  Container(
                    height: 85,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5), // Fallback color
                    ),
                    child: Image.asset(
                      deal.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),

                  // 2. Brand Logo
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 22,
                    child: Image.asset(
                      deal.brandLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Text(
                        "LOGO",
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 3. Spacing for the dotted line cutouts
                  const SizedBox(height: 16),

                  // 4. Offer Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Text(
                          deal.offerTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.colblack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deal.offerSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // 5. Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        color: deal.isClaimable
                            ? AppColors.primaryGreen
                            : const Color(0xFFBDBDBD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          deal.isClaimable ? "Claim" : "Unlock",
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Custom Horizontal Dotted Line exactly aligned with cutouts
              Positioned(
                top: cutoutY,
                left: 10, // Avoid overlapping the cutout arcs
                right: 10,
                child: CustomPaint(
                  painter: DottedLinePainter(),
                  size: const Size(double.infinity, 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigTicketCard(DealModel deal) {
    const double cardHeight = 180.0;
    const double cutoutY = cardHeight / 2; // Dead center for the big card

    return CustomPaint(
      painter: TicketShadowPainter(
        clipper: TicketClipper(cutoutPosition: cutoutY),
      ),
      child: ClipPath(
        clipper: TicketClipper(cutoutPosition: cutoutY),
        child: Container(
          width: double.infinity,
          height: cardHeight,
          color: Colors.white,
          child: Stack(
            children: [
              Row(
                children: [
                  // 1. Left Product Image
                  Container(
                    width: 140,
                    height: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: const Color(0xFFF5F5F5), // Fallback background
                        child: Image.asset(
                          deal.productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  // 2. Right Content Area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand Logo
                          SizedBox(
                            height: 20,
                            child: Image.asset(
                              deal.brandLogo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    "LOGO",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Offer Details
                          Text(
                            deal.offerTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.colblack,
                            ),
                          ),
                          Text(
                            deal.offerSubtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white500,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Description text
                          Text(
                            deal.description ?? "",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 8,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white500,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),

                          // Button
                          Container(
                            width: 100,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBDBDBD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "Unlock",
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
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
                ],
              ),

              // Custom Vertical Dotted Line
              Positioned(
                top: 10,
                bottom: 10,
                left: 140, // Positioned exactly at the boundary of the image
                child: CustomPaint(
                  painter: DottedLinePainter(isVertical: true),
                  size: const Size(1, double.infinity),
                ),
              ),
            ],
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

// ==========================================
// CORE TICKET CLIPPER & PAINTER SYSTEM
// ==========================================

/// Carves out the geometric "Ticket" shape with mathematically perfect semi-circles.
class TicketClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double cutoutRadius;
  final double
  cutoutPosition; // The precise Y-axis position for the center of the cutouts

  TicketClipper({
    this.cornerRadius = 14.0,
    this.cutoutRadius = 8.0,
    required this.cutoutPosition,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Top Left Corner
    path.moveTo(0, cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
    );

    // Top Right Corner
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right Edge -> Down to Cutout
    path.lineTo(size.width, cutoutPosition - cutoutRadius);

    // Right Cutout (Inward curve)
    path.arcToPoint(
      Offset(size.width, cutoutPosition + cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );

    // Right Edge -> Down to Bottom Corner
    path.lineTo(size.width, size.height - cornerRadius);
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom Left Corner
    path.lineTo(cornerRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left Edge -> Up to Cutout
    path.lineTo(0, cutoutPosition + cutoutRadius);

    // Left Cutout (Inward curve)
    path.arcToPoint(
      Offset(0, cutoutPosition - cutoutRadius),
      radius: Radius.circular(cutoutRadius),
      clockwise: false,
    );

    // Left Edge -> Up to Top
    path.lineTo(0, cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Casts a beautiful drop shadow explicitly matching the shape generated by the TicketClipper.
class TicketShadowPainter extends CustomPainter {
  final CustomClipper<Path> clipper;

  TicketShadowPainter({required this.clipper});

  @override
  void paint(Canvas canvas, Size size) {
    var path = clipper.getClip(size);
    // Draw the shadow exactly along the carved ticket path
    canvas.drawShadow(path, Colors.black.withOpacity(0.08), 8.0, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Draws the minimal dashed divider lines matching the Figma file
class DottedLinePainter extends CustomPainter {
  final Color color;
  final bool isVertical;

  DottedLinePainter({
    this.color = const Color(0xFFD4D4D4),
    this.isVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    var max = isVertical ? size.height : size.width;
    var dashWidth = 4.0;
    var dashSpace = 4.0;
    double currentPos = 0;

    while (currentPos < max) {
      if (isVertical) {
        canvas.drawLine(
          Offset(0, currentPos),
          Offset(0, currentPos + dashWidth),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(currentPos, 0),
          Offset(currentPos + dashWidth, 0),
          paint,
        );
      }
      currentPos += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


well there are few changes needed 