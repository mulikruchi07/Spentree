// lib/core/monthly_insights_service.dart
import 'package:flutter/material.dart';
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import 'transaction_service.dart';
import '../screens/forest/forest_screen.dart'; // To access TreeStatus and ForestStatus

class WrapStatus {
  final bool isAvailable;
  final DateTime? targetMonth;
  final bool showDot;
  // True once the SERVER confirms this account is Pro. Free users get
  // showDot/hasViewed gating; Pro users can always reopen the wrap.
  final bool isPro;

  WrapStatus({
    required this.isAvailable,
    this.targetMonth,
    required this.showDot,
    this.isPro = false,
  });
}

class MonthlyInsightsService {
  static final MonthlyInsightsService _instance =
      MonthlyInsightsService._internal();
  factory MonthlyInsightsService() => _instance;
  MonthlyInsightsService._internal();

  final List<Color> greenPalette = [
    const Color(0xFF005A32),
    const Color(0xFF238B45),
    const Color(0xFF41AB5D),
    const Color(0xFF74C476),
    const Color(0xFFA1D99B),
    const Color(0xFFC7E9C0),
  ];

  final List<String> allCategories = [
    "Food & Beverages",
    "Shopping",
    "To People",
    "Fuel",
    "Recharge",
    "Other",
  ];

  // ==========================================
  // WRAP AVAILABILITY & PERSISTENCE
  // ==========================================

  Future<WrapStatus> checkWrapStatus({DateTime? forMonth}) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      return WrapStatus(isAvailable: false, showDot: false);
    }

    final now = DateTime.now();

    // Free-plan eligibility window, computed exactly as before — used both
    // as the free-plan target month AND as the fallback default month when
    // no specific month is requested (e.g. Pro on first load, before the
    // person has navigated Forest's calendar to a specific past month).
    //
    // Rule: Wrap becomes available on the 1st day of the month AFTER 00:59
    // AM and stays available until the 25th of that same month.
    DateTime? freeEligibleMonth;
    if (now.day == 1) {
      if (now.hour > 0 || (now.hour == 0 && now.minute >= 59)) {
        freeEligibleMonth = DateTime(now.year, now.month - 1, 1);
      }
    } else if (now.day > 1 && now.day <= 29) {
      freeEligibleMonth = DateTime(now.year, now.month - 1, 1);
    }

    final DateTime candidateMonth = forMonth != null
        ? DateTime(forMonth.year, forMonth.month, 1)
        : (freeEligibleMonth ?? DateTime(now.year, now.month - 1, 1));
    final candidateKey = "${candidateMonth.year}-${candidateMonth.month}";

    // AUTHORITATIVE SOURCE for both view-completion state AND Pro status:
    // the server (get_wrap_view_state RPC), never local state. If the RPC
    // can't be reached, this fails CLOSED: treat as already-viewed / not
    // Pro (no dot, feature not re-openable) rather than granting anything.
    try {
      final response = await supabase
          .rpc(
            'get_wrap_view_state',
            params: {'target_month_year': candidateKey},
          )
          .timeout(const Duration(seconds: 10));

      final rows = response as List?;
      if (rows == null || rows.isEmpty) {
        return WrapStatus(isAvailable: false, showDot: false, isPro: false);
      }

      final row = rows.first as Map<String, dynamic>;
      final isPro = row['is_pro'] as bool? ?? false; // fail closed
      final hasViewed = row['has_viewed'] as bool? ?? true; // fail closed

      if (isPro) {
        // PRO: no day-of-month release window at all — available every day
        // of every month, for ANY completed month within the same 12-month
        // range Forest allows Pro users to browse, and never gated on
        // "already viewed" (unlimited re-opens until next month's wrap
        // exists).
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final earliestAllowed = DateTime(now.year, now.month - 11, 1);
        final monthIsCompleted = candidateMonth.isBefore(currentMonthStart);
        final monthIsWithinRange = !candidateMonth.isBefore(earliestAllowed);

        if (!monthIsCompleted || !monthIsWithinRange) {
          return WrapStatus(isAvailable: false, showDot: false, isPro: true);
        }
        return WrapStatus(
          isAvailable: true,
          targetMonth: candidateMonth,
          showDot: true,
          isPro: true,
        );
      }

      // FREE: unchanged from before — single auto-computed eligible month,
      // narrow day-of-month release window, exactly one completed view.
      if (freeEligibleMonth == null) {
        return WrapStatus(isAvailable: false, showDot: false, isPro: false);
      }

      // The candidate we queried IS the free-eligible month in the normal
      // Forest flow (free users can't navigate elsewhere — blocked at the
      // month-navigation level). If some other caller ever passes a
      // different forMonth for a free account, re-check the ACTUAL
      // eligible month's view-state instead of trusting the query above,
      // so a free account can never be shown availability for an
      // arbitrary month it asked for.
      if (freeEligibleMonth.year != candidateMonth.year ||
          freeEligibleMonth.month != candidateMonth.month) {
        final eligibleKey =
            "${freeEligibleMonth.year}-${freeEligibleMonth.month}";
        final response2 = await supabase
            .rpc(
              'get_wrap_view_state',
              params: {'target_month_year': eligibleKey},
            )
            .timeout(const Duration(seconds: 10));
        final rows2 = response2 as List?;
        if (rows2 == null || rows2.isEmpty) {
          return WrapStatus(
            isAvailable: true,
            targetMonth: freeEligibleMonth,
            showDot: false,
            isPro: false,
          );
        }
        final row2 = rows2.first as Map<String, dynamic>;
        final hasViewed2 = row2['has_viewed'] as bool? ?? true;
        return WrapStatus(
          isAvailable: true,
          targetMonth: freeEligibleMonth,
          showDot: !hasViewed2,
          isPro: false,
        );
      }

      return WrapStatus(
        isAvailable: true,
        targetMonth: freeEligibleMonth,
        showDot: !hasViewed,
        isPro: false,
      );
    } catch (e) {
      debugPrint("Wrap status check failed, failing closed: $e");
      return WrapStatus(
        isAvailable: freeEligibleMonth != null,
        targetMonth: freeEligibleMonth,
        showDot: false,
        isPro: false,
      );
    }
  }

  /// Records completion of a wrap view. This is fire-and-forget from the
  /// UI's point of view for responsiveness, but the actual gating decision
  /// on next launch always re-reads server state via checkWrapStatus()
  /// above — a failed/offline write here just means the next
  /// checkWrapStatus() call will (correctly, fail-closed) still show it as
  /// not-yet-completed, so the user simply gets to finish watching it next
  /// time rather than being incorrectly locked out or incorrectly granted
  /// an extra view.
  Future<void> markWrapAsViewed(DateTime month) async {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) return;
    final monthKey = "${month.year}-${month.month}";
    try {
      await supabase
          .rpc('mark_wrap_viewed', params: {'target_month_year': monthKey})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("mark_wrap_viewed failed (will retry via next check): $e");
    }
  }

  // ==========================================
  // SHARED CALCULATIONS (Used by Forest & Wrap)
  // ==========================================

  int daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

  double getDailyPercentage(double expense, int limit) {
    if (limit <= 0) return 0.0;
    double pending = (limit - expense).clamp(0.0, limit.toDouble());
    return (pending / limit).clamp(0.0, 1.0);
  }

  Map<int, double> getDailyTotals(DateTime month) {
    final days = daysInMonth(month);
    final Map<int, double> totals = {};
    for (int day = 1; day <= days; day++) {
      final date = DateTime(month.year, month.month, day);
      final txs = TransactionService().getTransactionsForDay(date);
      totals[day] = txs.fold(0.0, (sum, tx) => sum + tx.amount);
    }
    return totals;
  }

  double getTotalMonthlyExpense(DateTime month) {
    return getDailyTotals(month).values.fold(0.0, (sum, val) => sum + val);
  }

  // Forest Stats (Trees)
  Map<String, dynamic> computeForestStats(DateTime month, int dailyLimit) {
    final totals = getDailyTotals(month);
    int dense = 0, grand = 0, forest = 0, string = 0, drying = 0, dry = 0;
    int totalTrees = 0;

    totals.forEach((day, expense) {
      final pct = getDailyPercentage(expense, dailyLimit);
      final status = getTreeStatusForPercentage(pct);
      totalTrees += status.treesGrown;

      switch (status.label) {
        case "Dense Forest":
          dense++;
          break;
        case "Grand Forest":
          grand++;
          break;
        case "Forest":
          forest++;
          break;
        case "String Tree":
          string++;
          break;
        case "Drying Tree":
          drying++;
          break;
        case "Dry Tree":
          dry++;
          break;
      }
    });

    // Dominant Tree Calculation for Layer 1
    final treeCounts = [
      {
        "name": "Dense Forest",
        "image": "dense_forest.png",
        "count": dense,
        "weight": 6,
      },
      {
        "name": "Grand Forest",
        "image": "grand_forest.png",
        "count": grand,
        "weight": 5,
      },
      {"name": "Forest", "image": "forest.png", "count": forest, "weight": 4},
      {
        "name": "String Tree",
        "image": "string_tree.png",
        "count": string,
        "weight": 3,
      },
      {
        "name": "Drying Tree",
        "image": "drying_tree.png",
        "count": drying,
        "weight": 2,
      },
      {"name": "Dry Tree", "image": "dry_tree.png", "count": dry, "weight": 1},
    ];

    treeCounts.sort((a, b) {
      int countCompare = (b['count'] as int).compareTo(a['count'] as int);
      if (countCompare != 0) return countCompare;
      return (b['weight'] as int).compareTo(a['weight'] as int); // Tie-breaker
    });

    return {
      "totalTreesGrown": totalTrees,
      "treeCounts": [
        {
          "name": "Dense Forest",
          "image": "dense_forest.png",
          "count": dense.toString().padLeft(2, '0'),
        },
        {
          "name": "Grand Forest",
          "image": "grand_forest.png",
          "count": grand.toString().padLeft(2, '0'),
        },
        {
          "name": "Forest",
          "image": "forest.png",
          "count": forest.toString().padLeft(2, '0'),
        },
        {
          "name": "String Tree",
          "image": "string_tree.png",
          "count": string.toString().padLeft(2, '0'),
        },
        {
          "name": "Drying Tree",
          "image": "drying_tree.png",
          "count": drying.toString().padLeft(2, '0'),
        },
        {
          "name": "Dry Tree",
          "image": "dry_tree.png",
          "count": dry.toString().padLeft(2, '0'),
        },
      ],
      "dominantTreeImage": treeCounts.first['image'],
    };
  }

  // Category Breakdown
  List<Map<String, dynamic>> computeCategorySpends(
    DateTime month, {
    bool forceAll = false,
  }) {
    final totals = getDailyTotals(month);
    final Map<String, double> catTotals = forceAll
        ? {for (var cat in allCategories) cat: 0.0}
        : {};

    for (int day = 1; day <= daysInMonth(month); day++) {
      final txs = TransactionService().getTransactionsForDay(
        DateTime(month.year, month.month, day),
      );
      for (var tx in txs) {
        catTotals[tx.category] = (catTotals[tx.category] ?? 0.0) + tx.amount;
      }
    }

    var entries = catTotals.entries.toList();
    if (!forceAll) {
      entries = entries.where((e) => e.value > 0).toList();
    }
    entries.sort((a, b) => b.value.compareTo(a.value));

    return entries.asMap().entries.map((entry) {
      return {
        "name": entry.value.key,
        "amount": entry.value.value,
        "color": greenPalette[entry.key % greenPalette.length],
      };
    }).toList();
  }

  // Strongest Day Calculation
  Map<String, dynamic>? getStrongestDay(DateTime month, int dailyLimit) {
    final totals = getDailyTotals(month);
    int bestDay = -1;
    double lowestSpend = double.infinity;
    bool hasData = false;

    totals.forEach((day, expense) {
      if (expense < lowestSpend) {
        lowestSpend = expense;
        bestDay = day;
        hasData = true;
      }
    });

    if (!hasData || bestDay == -1) return null;

    double pct = getDailyPercentage(lowestSpend, dailyLimit);
    return {
      "day": bestDay,
      "date": DateTime(month.year, month.month, bestDay),
      "expense": lowestSpend,
      "percentage": (pct * 100).toInt(),
      "treeStatus": getTreeStatusForPercentage(pct).label,
    };
  }

  // Visual Assets based on Category
  Map<String, dynamic> getCategoryAssets(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case "food & drinks":
      case "food & beverages":
        return {
          "img1": "food_1.png",
          "img2": "food_2.png",
          "icon1": PhosphorIconsRegular.bowlSteam,
          "icon2": PhosphorIconsRegular.wine,
        };
      case "shopping":
        return {
          "img1": "shopping_1.png",
          "img2": "shopping_2.png",
          "icon1": PhosphorIconsRegular.shoppingCart,
          "icon2": PhosphorIconsRegular.shoppingBag,
        };
      case "to people":
        return {
          "img1": "people_1.png",
          "img2": "people_2.png",
          "icon1": PhosphorIconsRegular.user,
          "icon2": PhosphorIconsRegular.users,
        };
      case "fuel":
        return {
          "img1": "fuel_1.png",
          "img2": "fuel_2.png",
          "icon1": PhosphorIconsRegular.gasPump,
          "icon2": PhosphorIconsRegular.gasCan,
        };
      case "recharge":
      case "bills":
        return {
          "img1": "bills_1.png",
          "img2": "bills_2.png",
          "icon1": PhosphorIconsRegular.invoice,
          "icon2": PhosphorIconsRegular.scroll,
        };
      default:
        return {
          "img1": "other_1.png",
          "img2": "other_2.png",
          "icon1": PhosphorIconsRegular.money,
          "icon2": PhosphorIconsRegular.newspaperClipping,
        };
    }
  }
}
