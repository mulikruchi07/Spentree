import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Required for SVG rendering
import '../../core/app_style.dart';
import '../../core/user_data.dart'; // Assumes you have this for UserData.userName / UserData.profileImageUrl
import 'deals_screen.dart';
import '../../core/user_profile.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  // --- MOCK MILESTONE DATA ---
  // In development, this will be fetched from your backend/local storage
  final List<Map<String, dynamic>> _milestones = [
    {
      "title": "Keep Planting!",
      "subtitle": "First Tree Earned",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/keep_planting.png",
    },
    {
      "title": "3 Days of Control!",
      "subtitle": "3-Day Streak",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/3_days.png",
    },
    {
      "title": "One Week Strong!",
      "subtitle": "7-Day Streak",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/one_week.png",
    },
    {
      "title": "Growing Forest!",
      "subtitle": "30 Trees Grown",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/growing_forest.png",
    },
    {
      "title": "Masterful Control",
      "subtitle": "Spent well below limit",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/masterful_control.png",
    },
    {
      "title": "Back on Track!",
      "subtitle": "Comeback Day",
      "seeds": "+10 Seeds",
      "date": "Fri, 11 April 2025",
      "image": "assets/images/achievements/back_on_track.png",
    },
  ];

  // Dummy URL launcher for the footer
  void _launchURL(String url) {
    debugPrint("Launching $url");
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
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

                  // 1. Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // 2. Profile & Level Section
                  _buildProfileSection(screenWidth),

                  // Explicit gap of 18 from progress bar to Upcoming level text
                  const SizedBox(height: 22),

                  // 3. Upcoming Level Card
                  Text(
                    "Upcoming Level",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildUpcomingLevelCard(screenWidth),

                  // Explicit gap of 26 from upcoming card to milestone text
                  const SizedBox(height: 30),

                  // 4. Milestone Collection Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Milestone Collection",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                      Text(
                        "06/30",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),

                  // Explicit gap of 16 from milestone header to first card
                  const SizedBox(height: 18),

                  // 5. Milestone List
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _milestones.length,
                    itemBuilder: (context, index) {
                      return _buildMilestoneCard(
                        _milestones[index],
                        screenWidth,
                      );
                    },
                  ),

                  // Explicit gap of 26 from last card to footer
                  const SizedBox(height: 16),

                  // 6. Footer
                  _buildFooter(context),
                  const SizedBox(height: 120), // Bottom padding for navbar
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- SUB WIDGETS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              "Milestones",
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: AppColors.colblack,
                height: 1.0,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DealsScreen()),
            );
          },
          child: Stack(
            clipBehavior: Clip
                .none, // Allows the dot to sit slightly outside the icon bounds
            children: [
              Icon(PhosphorIcons.gift, size: 36, color: AppColors.colblack),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    // Adds a tiny white border around the red dot so it pops against the icon lines
                    border: Border.all(color: AppColors.bgWhite, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(double screenWidth) {
    // Math for progress bar
    int currentScore = 126;
    int maxScore = 150;
    double progress = currentScore / maxScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar with Badge
            SizedBox(
              width: 90, // Extra space to let the badge float outside
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Profile Image
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen, // Outer green ring
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(
                          1.5,
                        ), // White gap thickness
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.colwhite, // White middle ring
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(6.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.inputFill,
                                image:
                                    userProfileNotifier.value.imageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(
                                          userProfileNotifier.value.imageBytes!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child:
                                  userProfileNotifier.value.imageBytes == null
                                  ? Icon(
                                      PhosphorIcons.user,
                                      size: 40,
                                      color: AppColors.grey600,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Level Badge (The '2')
                  // Positioned outside the circle to create the "close but not stick" effect
                  Positioned(
                    top: 5,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen,
                          width: 2.0, // Weight is 2 thin
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "2",
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colwhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Name & Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<UserProfile>(
                    valueListenable: userProfileNotifier,
                    builder: (context, profile, _) => Text(
                      profile.firstName,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4), // Exact distance of 3
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.plant,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "The Sprout Keeper",
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // Medium
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress Bar Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Level 3 - Tree Nurturer",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500, // Medium
                color: AppColors.datenum, // Using datenum color
              ),
            ),
            Text(
              "$currentScore / $maxScore",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500, // Medium
                color: AppColors.datenum, // Using datenum color
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Custom Pill Progress Bar (Exact dimensions)
        Container(
          height: 17.32,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9), // Light grey track
            borderRadius: BorderRadius.circular(7.79),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress, // Dynamic fill based on score
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(7.79),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingLevelCard(double screenWidth) {
    return Container(
      width: double.infinity,
      height: 78.0, // Matches boxHeight reference
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill, // #F5F5F5 grey from app_style
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        children: [
          // Icon Box with Light Blurred Image & Lock
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.iconbox,
              borderRadius: BorderRadius.circular(9.63),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colblack.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft blur/opacity image effect in the background
                Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/images/forest/forest_great.png', // Fallback light image
                    fit: BoxFit.cover,
                  ),
                ),
                // Lock Icon on top
                Icon(
                  PhosphorIcons.lockKey,
                  size: 30,
                  color: AppColors.colblack,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Forest Builder",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Strong consistency",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500, // Medium
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),

          Text(
            "Level 4",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600, // SemiBold
              color: AppColors.colblack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> data, double screenWidth) {
    // Gap of 16 set via margin bottom
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      height: 78.0, // Matches boxHeight reference
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15.0), // Matches cardRadius
      ),
      child: Row(
        children: [
          // SVG Image Box matching reference exactly
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.iconbox,
              borderRadius: BorderRadius.circular(9.63),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colblack.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // SvgPicture handles the vector assets
            child: Center(
              child: Image.asset(data['image'], width: 42, height: 42),
            ),
          ),
          const SizedBox(width: 16),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['title'],
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: AppColors.colblack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data['subtitle'],
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500, // Medium
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),

          // Stats (Seeds & Date)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['seeds'],
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data['date'],
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500, // Medium
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
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
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com/in/designer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
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
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("www.linkedin.com/in/ruchi-mulik-816a2b295"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
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
        ),
      ],
    );
  }
}
