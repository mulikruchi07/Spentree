import 'dart:typed_data'; // ADDED
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/user_data.dart';

import '../widgets/greeting_card.dart';
import '../widgets/todays_tree_card.dart';
import '../widgets/todays_expenses_card.dart';
import '../widgets/calendar_card.dart';
import '../widgets/mini_tree_card.dart';
import '../widgets/add_expense_card.dart';
import '../widgets/auth_overlay_card.dart';

class WidgetUpdater {
  static Future<void> syncAllWidgets({
    required double todayExpense,
    required int dailyLimit,
    required List<Transaction> todayTransactions,
    required String? profileImagePath,
  }) async {
    // ==========================================
    // THE ULTIMATE SAFE HEADLESS WRAPPER
    // ==========================================
    Widget buildHeadless(Widget child, Size size) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 2.0,
          textScaler: const TextScaler.linear(1.0),
        ),
        // Adding MaterialApp back fixes the Localizations crash
        // useInheritedMediaQuery prevents the 0x0 size crash
        child: MaterialApp(
          useInheritedMediaQuery: true,
          debugShowCheckedModeBanner: false,
          home: Material(
            color: Colors.transparent,
            child: Center(child: child),
          ),
        ),
      );
    }

    Future<void> renderSafely(Widget child, Size size, String key) async {
      try {
        await HomeWidget.renderFlutterWidget(
          buildHeadless(child, size),
          logicalSize: size,
          pixelRatio: 2.0,
          key: key,
        );
        await Future.delayed(const Duration(milliseconds: 400));
      } catch (e) {
        debugPrint("❌ Failed to render $key: $e");
      }
    }

    final double pendingLimit = (dailyLimit - todayExpense).clamp(
      0.0,
      dailyLimit.toDouble(),
    );
    final double percentage = dailyLimit > 0
        ? (pendingLimit / dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    String treePath;
    if (percentage >= 0.83)
      treePath = "assets/images/dashboard/tree_1.png";
    else if (percentage >= 0.66)
      treePath = "assets/images/dashboard/tree_2.png";
    else if (percentage >= 0.50)
      treePath = "assets/images/dashboard/tree_3.png";
    else if (percentage >= 0.33)
      treePath = "assets/images/dashboard/tree_4.png";
    else if (percentage >= 0.16)
      treePath = "assets/images/dashboard/tree_5.png";
    else
      treePath = "assets/images/dashboard/tree_6.png";

    // Read the file directly into RAM to prevent blank screenshot bugs!
    final ByteData treeData = await rootBundle.load(treePath);
    final Uint8List treeBytes = treeData.buffer.asUint8List();

    // ==========================================
    // HEIGHTS INCREASED TO PREVENT OVERFLOW CRASHES
    // ==========================================
    await renderSafely(
      GreetingCard(
        userName: UserData.userName, // Fetches real name
        todayExpense: todayExpense,
        dailyLimit: dailyLimit,
        profileImageUrl: UserData.profileImagePath, // Passes local image path
        onArrowTap: () {},
      ),
      const Size(400, 250), // Height increased from 200
      'img_greeting',
    );

    await renderSafely(
      TodaysTreeCard(
        todayExpense: todayExpense,
        dailyLimit: dailyLimit,
        treeBytes: treeBytes,
        onGoToDashboard: () {},
        onSwapTap: () {},
      ),
      const Size(400, 500), // Height increased from 400
      'img_tree',
    );

    await renderSafely(
      TodaysExpensesCard(
        transactions: todayTransactions,
        onGoToAnalytics: () {},
        onSwapTap: () {},
      ),
      const Size(400, 500), // Height increased from 400
      'img_expenses',
    );

    await renderSafely(
      DynamicCalendarCard(
        dailyLimit: dailyLimit,
        treeBytes: treeBytes,
        onSwapTap: () {},
      ),
      const Size(400, 500), // Height increased from 400
      'img_calendar',
    );

    await renderSafely(
      MiniTreeCard(
        todayExpense: todayExpense,
        dailyLimit: dailyLimit,
        treeBytes: treeBytes, 
        onTap: () {},
      ),
      const Size(200, 250), // Height increased from 200
      'img_mini_tree',
    );

    await renderSafely(
      AddExpenseCard(onTap: () {}),
      const Size(200, 250), // Changed from (200, 250) to a perfect square
      'img_add_expense',
    );

    await renderSafely(
      AuthOverlayCard(onActionTap: () {}, isSignUpMode: false),
      const Size(400, 500), // Changed from (400, 450) to a perfect square
      'img_auth_overlay',
    );

    // ==========================================
    // UPDATE ANDROID
    // ==========================================
    try {
      await HomeWidget.updateWidget(
        name: 'GreetingWidgetProvider',
        androidName: 'GreetingWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'TreeWidgetProvider',
        androidName: 'TreeWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'ExpensesWidgetProvider',
        androidName: 'ExpensesWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'CalendarWidgetProvider',
        androidName: 'CalendarWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'MiniTreeWidgetProvider',
        androidName: 'MiniTreeWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'AddExpenseWidgetProvider',
        androidName: 'AddExpenseWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'AuthOverlayWidgetProvider',
        androidName: 'AuthOverlayWidgetProvider',
      );
      debugPrint("✅ All Android Home Screen Widgets Synced Safely!");
    } catch (e) {
      debugPrint("❌ Failed to push updates to Android: $e");
    }
  }
}
