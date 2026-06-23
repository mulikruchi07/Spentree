// lib/core/monthly_insights_service.dart
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:spentree/screens/forest/forest_screen.dart';
import 'transaction_service.dart';
import '../screens/forest/forest_screen.dart'; // To access TreeStatus and ForestStatus

class WrapStatus {
  final bool isAvailable;
  final DateTime? targetMonth;
  final bool showDot;

  WrapStatus({required this.isAvailable, this.targetMonth, required this.showDot});
}

class MonthlyInsightsService {
  static final MonthlyInsightsService _instance = MonthlyInsightsService._internal();
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
    "Food & Beverages", "Shopping", "To People", "Fuel", "Recharge", "Other"
  ];

  // ==========================================
  // WRAP AVAILABILITY & PERSISTENCE
  // ==========================================

  Future<WrapStatus> checkWrapStatus() async {
    final now = DateTime.now();

    DateTime? eligibleMonth;

    // Rule: Wrap becomes available on the 1st day of the month AFTER 00:59 AM
    // and stays available until the 25th of that same month.
    if (now.day == 1) {
      if (now.hour > 0 || (now.hour == 0 && now.minute >= 59)) {
        // It is 00:59 AM or later on the 1st of the month.
        // The wrap is for the PREVIOUS completed month.
        eligibleMonth = DateTime(now.year, now.month - 1, 1);
      }
    } else if (now.day > 1 && now.day <= 23) {
      // It is between the 2nd and 25th of the month.
      // The wrap is for the PREVIOUS completed month.
      eligibleMonth = DateTime(now.year, now.month - 1, 1);
    }

    // If we aren't in the valid window, the wrap is not available.
    if (eligibleMonth == null) {
      return WrapStatus(isAvailable: false, showDot: false);
    }

    final prefs = await SharedPreferences.getInstance();
    // Check if user has already watched it all the way through
    final key = "wrap_viewed_${eligibleMonth.year}_${eligibleMonth.month}";
    final hasViewed = prefs.getBool(key) ?? false;

    return WrapStatus(
      isAvailable: true,
      targetMonth: eligibleMonth,
      showDot: !hasViewed, // Only show red dot if they haven't completed it
    );
  }

  Future<void> markWrapAsViewed(DateTime month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("wrap_viewed_${month.year}_${month.month}", true);
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
        case "Dense Forest": dense++; break;
        case "Grand Forest": grand++; break;
        case "Forest": forest++; break;
        case "String Tree": string++; break;
        case "Drying Tree": drying++; break;
        case "Dry Tree": dry++; break;
      }
    });

    // Dominant Tree Calculation for Layer 1
    final treeCounts = [
      {"name": "Dense Forest", "image": "dense_forest.png", "count": dense, "weight": 6},
      {"name": "Grand Forest", "image": "grand_forest.png", "count": grand, "weight": 5},
      {"name": "Forest", "image": "forest.png", "count": forest, "weight": 4},
      {"name": "String Tree", "image": "string_tree.png", "count": string, "weight": 3},
      {"name": "Drying Tree", "image": "drying_tree.png", "count": drying, "weight": 2},
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
        {"name": "Dense Forest", "image": "dense_forest.png", "count": dense.toString().padLeft(2, '0')},
        {"name": "Grand Forest", "image": "grand_forest.png", "count": grand.toString().padLeft(2, '0')},
        {"name": "Forest", "image": "forest.png", "count": forest.toString().padLeft(2, '0')},
        {"name": "String Tree", "image": "string_tree.png", "count": string.toString().padLeft(2, '0')},
        {"name": "Drying Tree", "image": "drying_tree.png", "count": drying.toString().padLeft(2, '0')},
        {"name": "Dry Tree", "image": "dry_tree.png", "count": dry.toString().padLeft(2, '0')},
      ],
      "dominantTreeImage": treeCounts.first['image'],
    };
  }

  // Category Breakdown
  List<Map<String, dynamic>> computeCategorySpends(DateTime month, {bool forceAll = false}) {
    final totals = getDailyTotals(month);
    final Map<String, double> catTotals = forceAll 
        ? {for (var cat in allCategories) cat: 0.0} 
        : {};

    for (int day = 1; day <= daysInMonth(month); day++) {
      final txs = TransactionService().getTransactionsForDay(DateTime(month.year, month.month, day));
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
          "img1": "food_1.png", "img2": "food_2.png",
          "icon1": PhosphorIcons.bowlSteam, "icon2": PhosphorIconsRegular.wine
        };
      case "shopping":
        return {
          "img1": "shopping_1.png", "img2": "shopping_2.png",
          "icon1": PhosphorIcons.shoppingCart, "icon2": PhosphorIcons.shoppingBag
        };
      case "to people":
        return {
          "img1": "people_1.png", "img2": "people_2.png",
          "icon1": PhosphorIcons.user, "icon2": PhosphorIcons.users
        };
      case "fuel":
        return {
          "img1": "fuel_1.png", "img2": "fuel_2.png",
          "icon1": PhosphorIcons.gasPump, "icon2": PhosphorIcons.gasCan
        };
      case "recharge":
      case "bills":
        return {
          "img1": "bills_1.png", "img2": "bills_2.png",
          "icon1": PhosphorIcons.invoice, "icon2": PhosphorIcons.scroll
        };
      default:
        return {
          "img1": "other_1.png", "img2": "other_2.png",
          "icon1": PhosphorIcons.money, "icon2": PhosphorIcons.newspaperClipping
        };
    }
  }
}