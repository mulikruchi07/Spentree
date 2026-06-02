import 'package:flutter/material.dart';
import 'package:spentree/widgets/dynamic_calendar_card.dart';
import 'package:spentree/widgets/todays_expenses_card.dart';
import 'package:spentree/widgets/todays_tree_card.dart';

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int currentCard = 0;

  void nextCard() {
    setState(() {
      currentCard = (currentCard + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget card;

    switch (currentCard) {
      case 0:
        card = TodaysTreeCard(
          todayExpense: 2000,
          dailyLimit: 5000,
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
        card = DynamicCalendarCard(dailyLimit: 5000, onSwapTap: nextCard);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(child: card),
    );
  }
}
