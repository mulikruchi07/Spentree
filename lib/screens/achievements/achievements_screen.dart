import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/app_style.dart';
import '../../core/user_data.dart';
import 'deals_screen.dart';
import '../../core/user_profile.dart';
// import 'achievements_model.dart'; 

class Achievement {
  final String id;
  final String title;
  final String subtitle;
  final int seeds;
  final String category;
  final String imagePath; // Fallback to generic if specific doesn't exist

  const Achievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.seeds,
    required this.category,
    required this.imagePath,
  });
}

// Memory-light Master List of all 38 Achievements
const List<Achievement> masterAchievements = [
  // --- Onboarding ---
  Achievement(id: 'first_tree', title: "First Tree", subtitle: "Grow your first tree", seeds: 10, category: "Onboarding", imagePath: "keep_planting.png"),
  Achievement(id: 'first_control', title: "First Control Day", subtitle: "Stay under budget once", seeds: 5, category: "Onboarding", imagePath: "keep_planting.png"),
  
  // --- Streaks ---
  Achievement(id: 'streak_3', title: "3-Day Control", subtitle: "3-day streak", seeds: 10, category: "Streak", imagePath: "3_days.png"),
  Achievement(id: 'streak_5', title: "5-Day Momentum", subtitle: "5-day streak", seeds: 15, category: "Streak", imagePath: "3_days.png"),
  Achievement(id: 'streak_7', title: "7-Day Streak", subtitle: "7-day streak", seeds: 20, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_10', title: "10-Day Discipline", subtitle: "10-day streak", seeds: 25, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_15', title: "15-Day Streak", subtitle: "15-day streak", seeds: 30, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_21', title: "21-Day Habit", subtitle: "21-day streak", seeds: 40, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_30', title: "30-Day Master", subtitle: "30-day streak", seeds: 50, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_45', title: "45-Day Warrior", subtitle: "45-day streak", seeds: 60, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_60', title: "60-Day Champion", subtitle: "60-day streak", seeds: 75, category: "Streak", imagePath: "one_week.png"),
  Achievement(id: 'streak_90', title: "90-Day Legend", subtitle: "90-day streak", seeds: 100, category: "Streak", imagePath: "one_week.png"),

  // --- Tree Growth ---
  Achievement(id: 'trees_5', title: "5 Trees Grown", subtitle: "Grow 5 trees", seeds: 5, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_10', title: "10 Trees Grown", subtitle: "Grow 10 trees", seeds: 10, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_20', title: "20 Trees Grown", subtitle: "Grow 20 trees", seeds: 15, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_30', title: "30 Trees Grown", subtitle: "Grow 30 trees", seeds: 25, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_50', title: "50 Trees Grown", subtitle: "Grow 50 trees", seeds: 40, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_75', title: "75 Trees Grown", subtitle: "Grow 75 trees", seeds: 50, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_100', title: "100 Trees Grown", subtitle: "Grow 100 trees", seeds: 75, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_150', title: "150 Trees Grown", subtitle: "Grow 150 trees", seeds: 100, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_200', title: "200 Trees Grown", subtitle: "Grow 200 trees", seeds: 150, category: "Growth", imagePath: "growing_forest.png"),
  Achievement(id: 'trees_500', title: "500 Trees Grown", subtitle: "Grow 500 trees", seeds: 300, category: "Growth", imagePath: "growing_forest.png"),

  // --- Budget Mastery ---
  Achievement(id: 'budget_masterful', title: "Masterful Control", subtitle: "Perfect budget month", seeds: 50, category: "Mastery", imagePath: "masterful_control.png"),
  Achievement(id: 'budget_clean', title: "Clean Month", subtitle: "30 days under total budget", seeds: 60, category: "Mastery", imagePath: "masterful_control.png"),
  Achievement(id: 'budget_precision', title: "Precision Planner", subtitle: "Stay within 95% of budget", seeds: 30, category: "Mastery", imagePath: "masterful_control.png"),
  Achievement(id: 'budget_weekend', title: "Weekend Warrior", subtitle: "No overspending for 4 weekends", seeds: 25, category: "Mastery", imagePath: "masterful_control.png"),
  Achievement(id: 'budget_focused', title: "Financial Focused", subtitle: "No impulse category overspend", seeds: 35, category: "Mastery", imagePath: "masterful_control.png"),

  // --- Recovery & Resilience ---
  Achievement(id: 'recovery_comeback', title: "Comeback Day", subtitle: "Control after streak break", seeds: 5, category: "Recovery", imagePath: "back_on_track.png"),
  Achievement(id: 'recovery_rookie', title: "Restart Rookie", subtitle: "Start new streak after failure", seeds: 10, category: "Recovery", imagePath: "back_on_track.png"),
  Achievement(id: 'recovery_redemption', title: "Redemption Run", subtitle: "5-day streak after overspending", seeds: 20, category: "Recovery", imagePath: "back_on_track.png"),

  // --- Long-Term & Legendary ---
  Achievement(id: 'long_100', title: "100 Control Days", subtitle: "100 total days under limit", seeds: 75, category: "Legendary", imagePath: "growing_forest.png"),
  Achievement(id: 'long_200', title: "200 Control Days", subtitle: "200 total days under limit", seeds: 150, category: "Legendary", imagePath: "growing_forest.png"),
  Achievement(id: 'long_365', title: "365 Control Days", subtitle: "1 year of control", seeds: 300, category: "Legendary", imagePath: "growing_forest.png"),
  Achievement(id: 'long_month', title: "Monthly Dominator", subtitle: "Complete 3 clean months", seeds: 75, category: "Legendary", imagePath: "masterful_control.png"),
  Achievement(id: 'long_quarter', title: "Quarterly Champion", subtitle: "3 clean months", seeds: 150, category: "Legendary", imagePath: "masterful_control.png"),
  Achievement(id: 'long_half', title: "Half-Year Hero", subtitle: "6 months active", seeds: 200, category: "Legendary", imagePath: "masterful_control.png"),
  Achievement(id: 'long_annual', title: "Annual Achiever", subtitle: "12 months active", seeds: 400, category: "Legendary", imagePath: "masterful_control.png"),
  Achievement(id: 'long_legacy', title: "Forest Legacy", subtitle: "Reach 1000 trees grown", seeds: 500, category: "Legendary", imagePath: "growing_forest.png"),
];

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  // --- DYNAMIC STATE ---
  // In a real app, load this List of IDs from SharedPreferences or Isar
  final Set<String> _unlockedIds = {
    'first_tree',
    'first_control',
    'streak_3',
    'trees_5',
    'recovery_comeback',
  };

  int _totalSeeds = 0;
  int _currentLevel = 1;
  int _currentLevelThreshold = 50;
  int _nextLevelThreshold = 150;
  String _levelTitle = "The Sprout Keeper";

  @override
  void initState() {
    super.initState();
    _calculateUserProgress();
  }

  // Zero-Latency Calculation Engine
  void _calculateUserProgress() {
    int seeds = 0;

    // 1. Calculate Total Seeds from Unlocked Achievements
    for (var achievement in masterAchievements) {
      if (_unlockedIds.contains(achievement.id)) {
        seeds += achievement.seeds;
      }
    }

    // 2. Determine Level (Fast logic tree)
    int level = 1;
    String title = "The Sprout Keeper";
    int currentFloor = 0;
    int nextCeil = 50;

    if (seeds >= 500) {
      level = 5;
      title = "Forest Legend";
      currentFloor = 500;
      nextCeil = 1000;
    } else if (seeds >= 300) {
      level = 4;
      title = "Master Botanist";
      currentFloor = 300;
      nextCeil = 500;
    } else if (seeds >= 150) {
      level = 3;
      title = "Tree Nurturer";
      currentFloor = 150;
      nextCeil = 300;
    } else if (seeds >= 50) {
      level = 2;
      title = "Sapling Guardian";
      currentFloor = 50;
      nextCeil = 150;
    }

    setState(() {
      _totalSeeds = seeds;
      _currentLevel = level;
      _levelTitle = title;
      _currentLevelThreshold = currentFloor;
      _nextLevelThreshold = nextCeil;
    });
  }

  List<Achievement> get _unlockedAchievements {
    return masterAchievements
        .where((a) => _unlockedIds.contains(a.id))
        .toList();
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

                  // Explicit gap
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

                  // Explicit gap
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
                        "${_unlockedAchievements.length.toString().padLeft(2, '0')}/${masterAchievements.length}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                    ],
                  ),

                  // Explicit gap
                  const SizedBox(height: 18),

                  // 5. Milestone List (Dynamically Built)
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _unlockedAchievements.length,
                    itemBuilder: (context, index) {
                      return _buildMilestoneCard(
                        _unlockedAchievements[index],
                        screenWidth,
                      );
                    },
                  ),

                  // Explicit gap
                  const SizedBox(height: 16),

                  // 6. Footer
                  _buildTipSection(),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.divider, thickness: 1),
                  const SizedBox(height: 20),
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
            clipBehavior: Clip.none,
            children: [
              Icon(
                PhosphorIconsRegular.gift,
                size: 36,
                color: AppColors.colblack,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
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
    // Prevent division by zero and calculate progress bounded within the tier
    double levelProgress =
        (_totalSeeds - _currentLevelThreshold) /
        (_nextLevelThreshold - _currentLevelThreshold);
    levelProgress = levelProgress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar with Badge
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.colwhite,
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
                                      PhosphorIconsRegular.user,
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
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _currentLevel.toString(),
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
                      profile.firstName.isNotEmpty
                          ? profile.firstName
                          : "Ruchi Mulik",
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.plant,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _levelTitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
              "Level $_currentLevel - $_levelTitle",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.datenum,
              ),
            ),
            Text(
              "$_totalSeeds / $_nextLevelThreshold",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.datenum,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Custom Pill Progress Bar
        Container(
          height: 17.32,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(7.79),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: levelProgress,
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
      height: 78.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
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
                Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    'assets/images/forest/forest_great.png', // Fallback light image
                    fit: BoxFit.cover,
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.lockKey,
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
                  "Level ${_currentLevel + 1} Target",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$_nextLevelThreshold Seeds Required",
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),

          Text(
            "Level ${_currentLevel + 1}",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.colblack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Achievement achievement, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      height: 78.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Row(
        children: [
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
            child: Center(
              child: Image.asset(
                "assets/images/achievements/${achievement.imagePath}",
                width: 42,
                height: 42,
              ),
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
                  achievement.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "+${achievement.seeds} Seeds",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Earned", // You can replace this with a dynamic Date format later
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tip of the day",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Cooking one meal at home can save enough to grow 3 new leaves.",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: AppColors.white500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
