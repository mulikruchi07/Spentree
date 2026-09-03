import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/core/user_data.dart';
import '../../core/app_style.dart';
import '../../core/user_profile.dart';
import '../../core/transaction_service.dart';
// import 'deals_screen.dart';

// ==========================================
// LEVEL & PHASE SYSTEM DEFINITIONS
// ==========================================
class LevelInfo {
  final int level;
  final String title;
  final int requiredTrees;

  const LevelInfo(this.level, this.title, this.requiredTrees);
}

class MilestoneProgress {
  final int
  completedLevelIndex; // index into masterLevels of the highest fully-completed level
  final int
  activeLevelIndex; // index into masterLevels of the level currently being filled
  final int
  activeProgress; // trees earned toward the active level's OWN requirement, reset per level
  final bool allLevelsCompleted;

  const MilestoneProgress({
    required this.completedLevelIndex,
    required this.activeLevelIndex,
    required this.activeProgress,
    required this.allLevelsCompleted,
  });
}

// Pure, stateless, sequential-consumption calculation. Re-run this from
// scratch on every call — never cache or mutate the daily results — so
// editing or deleting a transaction anywhere in history correctly
// reshuffles which trees belong to which level.
//
// Level 1 (requiredTrees = 0) is satisfied instantly, so the active level
// starts at index 1 (Level 2) before any trees exist. Each day's earned
// trees are added ONLY to the currently active level; once that level's
// own requirement is met, it's marked complete, the counter resets to
// zero, and any leftover trees from that same day roll into the next
// level (handles a day's earnings spanning two level completions).
MilestoneProgress calculateMilestoneProgress(
  List<int> dailyTreeResultsChronological,
  List<LevelInfo> levels,
) {
  if (levels.isEmpty) {
    return const MilestoneProgress(
      completedLevelIndex: 0,
      activeLevelIndex: 0,
      activeProgress: 0,
      allLevelsCompleted: true,
    );
  }

  int completedIndex = 0;
  int activeIndex = levels.length > 1 ? 1 : 0;
  int activeProgress = 0;

  if (activeIndex >= levels.length) {
    return MilestoneProgress(
      completedLevelIndex: completedIndex,
      activeLevelIndex: completedIndex,
      activeProgress: 0,
      allLevelsCompleted: true,
    );
  }

  for (final earnedToday in dailyTreeResultsChronological) {
    int remaining = earnedToday;
    while (remaining > 0 && activeIndex < levels.length) {
      final requirement = levels[activeIndex].requiredTrees;
      final stillNeeded = requirement - activeProgress;
      final used = remaining < stillNeeded ? remaining : stillNeeded;

      activeProgress += used;
      remaining -= used;

      if (activeProgress >= requirement) {
        completedIndex = activeIndex;
        activeIndex += 1;
        activeProgress = 0;
      }
    }
    if (activeIndex >= levels.length) break;
  }

  if (activeIndex >= levels.length) {
    return MilestoneProgress(
      completedLevelIndex: completedIndex,
      activeLevelIndex: completedIndex,
      activeProgress: 0,
      allLevelsCompleted: true,
    );
  }

  return MilestoneProgress(
    completedLevelIndex: completedIndex,
    activeLevelIndex: activeIndex,
    activeProgress: activeProgress,
    allLevelsCompleted: false,
  );
}

final List<LevelInfo> masterLevels = [
  // Levels 1–10 (Onboarding Phase)
  const LevelInfo(1, "Seed Starter", 0),
  const LevelInfo(2, "Sprout Keeper", 5),
  const LevelInfo(3, "Bud Guardian", 10),
  const LevelInfo(4, "Tree Nurturer", 15),
  const LevelInfo(5, "Green Grower", 20),
  const LevelInfo(6, "Forest Friend", 25),
  const LevelInfo(7, "Leaf Leader", 30),
  const LevelInfo(8, "Root Builder", 40),
  const LevelInfo(9, "Eco Planner", 50),
  const LevelInfo(10, "Forest Builder", 60),

  // Levels 11–20 (Habit Phase)
  const LevelInfo(11, "Growth Keeper", 75),
  const LevelInfo(12, "Woodland Ranger", 90),
  const LevelInfo(13, "Tree Steward", 110),
  const LevelInfo(14, "Nature Shaper", 130),
  const LevelInfo(15, "Green Architect", 150),
  const LevelInfo(16, "Eco Guardian", 180),
  const LevelInfo(17, "Sustainability Star", 210),
  const LevelInfo(18, "Climate Champion", 250),
  const LevelInfo(19, "Planet Ally", 300),
  const LevelInfo(20, "Earth Defender", 350),

  // Levels 21–30 (Advanced Phase)
  const LevelInfo(21, "Forest Commander", 420),
  const LevelInfo(22, "Eco Strategist", 500),
  const LevelInfo(23, "Nature Architect", 600),
  const LevelInfo(24, "Green Master", 720),
  const LevelInfo(25, "Habitat Hero", 850),
  const LevelInfo(26, "Carbon Cutter", 1000),
  const LevelInfo(27, "Planet Guardian", 1200),
  const LevelInfo(28, "Evergreen Leader", 1450),
  const LevelInfo(29, "Eco Visionary", 1750),
  const LevelInfo(30, "Climate Warrior", 2100),

  // Levels 31–40 (Elite Phase)
  const LevelInfo(31, "Earth Champion", 2500),
  const LevelInfo(32, "Green Titan", 3000),
  const LevelInfo(33, "Nature Protector", 3600),
  const LevelInfo(34, "Sustainability Lord", 4300),
  const LevelInfo(35, "Global Gardener", 5100),
  const LevelInfo(36, "Climate King", 6000),
  const LevelInfo(37, "Planet Pioneer", 7000),
  const LevelInfo(38, "Eco Supreme", 8200),
  const LevelInfo(39, "Forest Legend", 9500),
  const LevelInfo(40, "Earth Emperor", 11000),

  // Levels 41–50 (Prestige Phase)
  const LevelInfo(41, "Green Overlord", 13000),
  const LevelInfo(42, "Nature Icon", 15000),
  const LevelInfo(43, "Carbon Slayer", 17500),
  const LevelInfo(44, "Planet Hero", 20000),
  const LevelInfo(45, "Eco Elite", 23000),
  const LevelInfo(46, "Forest Immortal", 26000),
  const LevelInfo(47, "Climate Supreme", 30000),
  const LevelInfo(48, "Earth Visionary", 35000),
  const LevelInfo(49, "Planet Legend", 40000),
  const LevelInfo(50, "🌍 World Restorer", 50000),
];

// Helper to get phase-wise image asset path based on level number
String getPhaseAssetForLevel(int level) {
  if (level <= 10) return "assets/images/achievements/keep_planting.png";
  if (level <= 20) return "assets/images/achievements/3_days.png";
  if (level <= 30) return "assets/images/achievements/one_week.png";
  if (level <= 40) return "assets/images/achievements/growing_forest.png";
  return "assets/images/achievements/masterful_control.png";
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _totalTrees = 0;
  bool _isLoadingData = true;
  bool _showSkeleton = false;
  int _dailyLimit = 500;

  // Sequential, no-carryover level state — always recomputed from
  // scratch, never cached/mutated in place.
  int _completedLevelIndex = 0;
  int _activeLevelIndex = 0;
  int _activeProgress = 0;
  bool _allLevelsCompleted = false;

  // Local cache of the last computed/synced state, purely so this screen
  // can render immediately (no full-screen loader) on a fresh install or
  // after a long time away, using whatever's already known while the
  // authoritative recomputation from actual local transactions runs and
  // corrects it if needed. This is NEVER the source of truth — it's a
  // display convenience, self-healing the instant _loadUserMetrics()
  // finishes its real computation below.
  static const _kCacheKey = 'milestone_cache_json_v1';
  static const _kPendingSyncKey = 'milestone_sync_pending_v1';

  @override
  void initState() {
    super.initState();
    TransactionService().addListener(_loadUserMetrics);

    // Give the local cache 150ms to load instantly before deciding to show the skeleton
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _isLoadingData) {
        setState(() {
          _showSkeleton = true;
        });
      }
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Instant paint from whatever's cached locally (from a previous
    // successful compute/sync on this device) — avoids the full-screen
    // spinner for a returning user. Never trusted beyond display; step 3
    // below always recomputes from real data and corrects this if wrong.
    await _renderFromLocalCacheIfAny();

    // 2. If nothing was cached locally at all (first time ever on this
    // device — fresh install, or first login on a new device), try the
    // server's cached snapshot so there's still something correct-ish to
    // show immediately instead of "Level 1 / 0 trees" while transactions
    // are still pulling down.
    if (_isLoadingData) {
      await _renderFromServerCacheIfAny();
    }

    // 3. The actual authoritative computation, from real local transaction
    // data — this always runs, always wins, and is what keeps the state
    // correct regardless of what either cache said.
    await _loadUserMetrics();
  }

  Future<void> _renderFromLocalCacheIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCacheKey);
    if (cached == null) return;
    try {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _totalTrees = map['totalTrees'] as int;
          _completedLevelIndex = map['completedLevelIndex'] as int;
          _activeLevelIndex = map['activeLevelIndex'] as int;
          _activeProgress = map['activeProgress'] as int;
          _allLevelsCompleted = map['allLevelsCompleted'] as bool;
          _isLoadingData = false; // we have SOMETHING to show now
        });
      }
    } catch (_) {
      // Corrupt/old-shape cache — ignore, step 3 will populate a fresh one.
    }
  }

  Future<void> _renderFromServerCacheIfAny() async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) return;

      final response = await supabase.functions
          .invoke('decrypt-milestones', body: {})
          .timeout(const Duration(seconds: 8));

      if (response.status != 200 || response.data == null) return;

      final map = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _totalTrees = map['totalTrees'] as int;
          _completedLevelIndex = map['completedLevelIndex'] as int;
          _activeLevelIndex = map['activeLevelIndex'] as int;
          _activeProgress = map['activeProgress'] as int;
          _allLevelsCompleted = map['allLevelsCompleted'] as bool;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Milestone server-cache fetch skipped: $e");
      // Fine — step 3 (_loadUserMetrics) still runs regardless and is the
      // real source of truth; this was only for a faster first paint.
    }
  }

  @override
  void dispose() {
    TransactionService().removeListener(_loadUserMetrics);
    super.dispose();
  }

  Future<void> _loadUserMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedLimit = prefs.getInt('daily_expense_limit');
    if (savedLimit != null) {
      _dailyLimit = savedLimit;
    } else {
      int? parsedLimit = int.tryParse(
        UserData.dailyLimit.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      _dailyLimit = parsedLimit ?? 500;
    }

    // Retrieve the account's real signup date. THIS IS THE VALUE THAT MUST
    // BE CONSISTENT ACROSS DEVICES: it anchors the entire day-by-day tree
    // walk below, so it must be the authoritative, server-side
    // users.created_at — never a per-device local guess. (The previous
    // version of this method stored a SharedPreferences 'user_signup_date'
    // that got silently initialized to DateTime.now() the first time this
    // screen ran on ANY device without that key present — which is every
    // fresh install, every new device, and every reinstall. That made the
    // whole history-based calculation start over from zero on exactly the
    // scenarios this feature needs to handle correctly.)
    final signupDate = await _resolveSignupDate(prefs);
    DateTime today = DateTime.now();

    // Compute accumulated trees from signup date to today based on dashboard metrics
    int accumulatedTrees = 0;
    // Walk signup date → today building the CHRONOLOGICAL per-day tree
    // stream (never a running total) — order matters, since this is
    // consumed sequentially below.
    List<int> dailyTreeResults = [];
    DateTime iterator = DateTime(
      signupDate.year,
      signupDate.month,
      signupDate.day,
    );
    DateTime endDay = DateTime(today.year, today.month, today.day);

    while (!iterator.isAfter(endDay)) {
      final dailyTx = TransactionService().getTransactionsForDay(iterator);
      double dayExpense = dailyTx.fold(0.0, (sum, item) => sum + item.amount);
      double pendingLimit = (_dailyLimit - dayExpense).clamp(
        0.0,
        _dailyLimit.toDouble(),
      );
      double percentage = _dailyLimit > 0
          ? (pendingLimit / _dailyLimit).clamp(0.0, 1.0)
          : 0.0;

      int treesToday = 0;
      if (percentage >= 0.83) {
        treesToday = 5;
      } else if (percentage >= 0.66) {
        treesToday = 3;
      } else if (percentage >= 0.50) {
        treesToday = 2;
      } else if (percentage >= 0.33) {
        treesToday = 1;
      }
      dailyTreeResults.add(treesToday);

      iterator = iterator.add(const Duration(days: 1));
    }

    final milestone = calculateMilestoneProgress(
      dailyTreeResults,
      masterLevels,
    );

    if (mounted) {
      setState(() {
        _totalTrees = dailyTreeResults.fold(0, (sum, t) => sum + t);
        _completedLevelIndex = milestone.completedLevelIndex;
        _activeLevelIndex = milestone.activeLevelIndex;
        _activeProgress = milestone.activeProgress;
        _allLevelsCompleted = milestone.allLevelsCompleted;
        _isLoadingData = false;
      });
    }

    // Only cache/sync once transactions have actually finished loading —
    // otherwise a fresh device could compute (and then persist) a
    // partial/wrong state from an incomplete transaction pull, which is
    // exactly the kind of stale-data problem this feature exists to avoid.
    if (!TransactionService().isLoading) {
      await _persistLocalCache(milestone, _totalTrees);
      await _pushMilestoneStateIfChanged(milestone, _totalTrees);
    }
  }

  Future<void> _persistLocalCache(
    MilestoneProgress milestone,
    int totalTrees,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCacheKey,
      jsonEncode({
        'totalTrees': totalTrees,
        'completedLevelIndex': milestone.completedLevelIndex,
        'activeLevelIndex': milestone.activeLevelIndex,
        'activeProgress': milestone.activeProgress,
        'allLevelsCompleted': milestone.allLevelsCompleted,
      }),
    );
  }

  /// Pushes the current state to the server cache (encrypt-milestones)
  /// ONLY if it actually differs from what was last successfully pushed —
  /// this is what makes the sync idempotent and avoids hammering the
  /// function on every minor rebuild. If the push fails (offline), a
  /// pending flag is left set so the NEXT successful computation (next
  /// app open, next transaction change, next reconnect) retries it — this
  /// is the "sync when back online" behavior, without needing a durable
  /// offline queue table for what is fundamentally a single cached value.
  Future<void> _pushMilestoneStateIfChanged(
    MilestoneProgress milestone,
    int totalTrees,
  ) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final newStateJson = jsonEncode({
      'totalTrees': totalTrees,
      'completedLevelIndex': milestone.completedLevelIndex,
      'activeLevelIndex': milestone.activeLevelIndex,
      'activeProgress': milestone.activeProgress,
      'allLevelsCompleted': milestone.allLevelsCompleted,
    });

    final lastPushedJson = prefs.getString('milestone_last_pushed_v1');
    final pendingRetry = prefs.getBool(_kPendingSyncKey) ?? false;

    if (newStateJson == lastPushedJson && !pendingRetry) {
      return; // nothing changed since the last successful push
    }

    try {
      final response = await supabase.functions
          .invoke(
            'encrypt-milestones',
            body: {
              'totalTrees': totalTrees,
              'completedLevelIndex': milestone.completedLevelIndex,
              'activeLevelIndex': milestone.activeLevelIndex,
              'activeProgress': milestone.activeProgress,
              'allLevelsCompleted': milestone.allLevelsCompleted,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.status == 200) {
        await prefs.setString('milestone_last_pushed_v1', newStateJson);
        await prefs.setBool(_kPendingSyncKey, false);
      } else {
        await prefs.setBool(_kPendingSyncKey, true);
      }
    } catch (e) {
      debugPrint("Milestone sync deferred (offline?): $e");
      await prefs.setBool(_kPendingSyncKey, true);
    }
  }

  /// Resolves the account's true signup date, in order of trust:
  ///   1. users.created_at from the server — authoritative, identical
  ///      across every device, set once at signup and never changed.
  ///   2. A locally cached copy of that same server value, ONLY used when
  ///      offline (so the app still works without a network call) — never
  ///      a substitute for actually checking the server when possible.
  ///   3. The earliest locally-known transaction date, if any exist —
  ///      handles the (should-be-rare) case of truly no network AND no
  ///      local cache yet, without ever inventing "today" for an account
  ///      that clearly already has history.
  ///   4. DateTime.now() — only reachable for a genuinely brand new
  ///      account with zero transactions and no network on its very first
  ///      run, where there is no history to lose either way.
  Future<DateTime> _resolveSignupDate(SharedPreferences prefs) async {
    const cacheKey = 'user_signup_date_server_v1';

    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid != null) {
        final row = await supabase
            .from('users')
            .select('created_at')
            .eq('id', uid)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
        final createdAt = row?['created_at'] as String?;
        if (createdAt != null) {
          await prefs.setString(cacheKey, createdAt);
          return DateTime.parse(createdAt);
        }
      }
    } catch (e) {
      debugPrint("Couldn't fetch signup date from server, falling back: $e");
    }

    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return DateTime.parse(cached);
    }

    final earliestLocalTx = TransactionService().allTransactions.isNotEmpty
        ? TransactionService().allTransactions
              .map((t) => t.dateTime)
              .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    if (earliestLocalTx != null) return earliestLocalTx;

    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoadingData) {
      // If we are still in the 150ms grace period, show a blank background.
      // This completely eliminates the 1-frame skeleton flash for cached data.
      if (!_showSkeleton) {
        return Scaffold(backgroundColor: AppColors.bgWhite);
      }

      // If data actually needs time to compute/fetch, show the skeleton.
      return Scaffold(
        backgroundColor: AppColors.bgWhite,
        body: _buildSkeletonLoad(),
      );
    }

    // currentLevelInfo = highest fully-completed level (the badge).
    // nextLevelInfo = the level currently being actively filled — its
    // progress resets to 0 the instant the previous level completes.
    final currentLevelInfo = masterLevels[_completedLevelIndex];
    final nextLevelInfo = masterLevels[_activeLevelIndex];

    int treesNeededForOngoing = nextLevelInfo.requiredTrees;
    int treesCollectedForOngoing = _allLevelsCompleted
        ? treesNeededForOngoing
        : _activeProgress;

    double progress = treesNeededForOngoing > 0
        ? (treesCollectedForOngoing / treesNeededForOngoing).clamp(0.0, 1.0)
        : 1.0;

    // Build next 7 upcoming level cards starting strictly AFTER the ongoing filling level
    List<LevelInfo> upcomingLevelsList = [];
    for (int i = 1; i <= 7; i++) {
      int targetLvl = nextLevelInfo.level + i;
      if (targetLvl <= 50) {
        upcomingLevelsList.add(
          masterLevels.firstWhere((lvl) => lvl.level == targetLvl),
        );
      }
    }

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
                  _buildProfileSection(
                    screenWidth,
                    currentLevelInfo,
                    nextLevelInfo,
                    progress,
                    treesCollectedForOngoing,
                    treesNeededForOngoing,
                  ),

                  const SizedBox(height: 22),

                  // 3. Upcoming Levels Header
                  Text(
                    "Upcoming Levels",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Upcoming Level Cards (Next 7)
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingLevelsList.length,
                    itemBuilder: (context, index) {
                      return _buildUpcomingLevelCard(
                        upcomingLevelsList[index],
                        screenWidth,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Non-clickable 'more to go' note
                  Center(
                    child: Text(
                      "More to go",
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 5. Footer Tip & Info
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
                  const SizedBox(height: 120),
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
      ],
    );
  }

  Widget _buildProfileSection(
    double screenWidth,
    LevelInfo currentLevelInfo,
    LevelInfo nextLevelInfo,
    double progress,
    int treesCollected,
    int treesNeeded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
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
                  // Completed level badge displayed around the PFP
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
                          "${currentLevelInfo.level}",
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
                        "Level ${currentLevelInfo.level} - ${currentLevelInfo.title}",
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Level ${nextLevelInfo.level} - ${nextLevelInfo.title}",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.datenum,
              ),
            ),
            Text(
              "$treesCollected / $treesNeeded",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.datenum,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
              widthFactor: progress,
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

  Widget _buildUpcomingLevelCard(LevelInfo levelInfo, double screenWidth) {
    String phaseImage = getPhaseAssetForLevel(levelInfo.level);

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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    phaseImage,
                    width: 42,
                    height: 42,
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
                  levelInfo.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${levelInfo.requiredTrees} Trees Required",
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
            "Level ${levelInfo.level}",
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

  Widget _buildSkeletonLoad() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 70),

            // Header Skeleton
            const SkeletonBox(width: 40, height: 20),
            const SizedBox(height: 8),
            const SkeletonBox(width: 180, height: 36),
            const SizedBox(height: 32),

            // Profile Section Skeleton
            Row(
              children: [
                const SkeletonBox(
                  width: 90,
                  height: 90,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 150, height: 24),
                      SizedBox(height: 12),
                      SkeletonBox(width: 100, height: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 100, height: 14),
                SkeletonBox(width: 40, height: 14),
              ],
            ),
            const SizedBox(height: 8),
            SkeletonBox(
              width: double.infinity,
              height: 17.32,
              borderRadius: BorderRadius.circular(7.79),
            ),
            const SizedBox(height: 32),

            // Upcoming Levels Header Skeleton
            const SkeletonBox(width: 130, height: 20),
            const SizedBox(height: 18),

            // Upcoming Level Cards Skeleton
            for (int i = 0; i < 5; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                width: double.infinity,
                height: 78.0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.inputFill, // Keep existing background
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Row(
                  children: [
                    SkeletonBox(
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(9.63),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SkeletonBox(width: 120, height: 16),
                          SizedBox(height: 8),
                          SkeletonBox(width: 80, height: 12),
                        ],
                      ),
                    ),
                    const SkeletonBox(width: 60, height: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Turns each level's `requiredTrees` into a genuine independent quota:
  // the running SUM of every level's own requirement, not the raw table
  // value (which was being read as an already-cumulative threshold —
  // that's what let a level clear after only its delta, not its full count).
  int _cumulativeFloorForLevel(int level) {
    int sum = 0;
    for (final info in masterLevels) {
      if (info.level >= level) break;
      sum += info.requiredTrees;
    }
    return sum;
  }
}

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0), // Soft gray for skeleton
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.rectangle
              ? (widget.borderRadius ?? BorderRadius.circular(8.0))
              : null,
        ),
      ),
    );
  }
}
