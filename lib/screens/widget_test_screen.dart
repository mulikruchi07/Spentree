import 'dart:typed_data'; // ADDED for Uint8List
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/widgets/calendar_card.dart';
import 'package:spentree/widgets/todays_expenses_card.dart';
import 'package:spentree/widgets/todays_tree_card.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int currentCard = 0;
  Uint8List? _treeBytes;

  @override
  void initState() {
    super.initState();
    _loadTreeBytes();
  }

  // ADDED: Loads a sample tree image into memory for the UI test
  Future<void> _loadTreeBytes() async {
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/dashboard/tree_1.png',
      );
      setState(() {
        _treeBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint("Failed to load test tree image: $e");
    }
  }

  void nextCard() {
    setState(() {
      currentCard = (currentCard + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        if (_treeBytes == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        Widget card;

        switch (currentCard) {
          case 0:
            card = TodaysTreeCard(
              todayExpense: 2000,
              dailyLimit: 5000,
              treeBytes: _treeBytes!, // Pass the loaded tree image bytes
              onGoToDashboard: () {},
              onSwapTap: nextCard,
            );
            break;

          case 1:
            card = TodaysExpensesCard(
              transactions: [],
              onGoToAnalytics: () {},
              onSwapTap: nextCard,
            );
            break;

          default:
            card = DynamicCalendarCard(
              dailyLimit: 5000,
              treeBytes: _treeBytes!,
              onSwapTap: nextCard,
            );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: SafeArea(child: card),
        );
      },
    );
  }
}
