import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ADDED for fetching limit
import 'dart:math' as math;
import 'dart:convert'; // Required for jsonEncode
import 'package:flutter/material.dart'; // Required for DateUtils
import 'package:spentree/core/user_data.dart';

class Transaction {
  String id;
  String title;
  String category;
  double amount;
  DateTime date;
  TimeOfDay time;
  IconData icon;
  bool isManual; // Determines Cash vs Bank Account

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    required this.icon,
    this.isManual = false,
  });
}

class TransactionService extends ChangeNotifier {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  static const MethodChannel _channel = MethodChannel('sms_channel');

  List<Transaction> _allTransactions = [];
  bool isLoading = true;

  List<Transaction> get allTransactions => _allTransactions;

  Future<void> initService() async {
    if (kIsWeb) {
      isLoading = false;
      notifyListeners();
      return;
    }
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
    await _fetchAndParseSms();
  }

  Future<void> _fetchAndParseSms() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSms');
      List<Transaction> parsedList = [];

      for (var sms in result) {
        String body = (sms['body'] ?? '').toLowerCase();
        String originalBody = sms['body'] ?? '';
        String address = sms['address'] ?? 'Unknown';
        int timestamp = sms['date'] ?? 0;

        bool isDebit = body.contains('debited') || body.contains('sent to');
        bool hasAmount =
            body.contains('rs') || body.contains('inr') || body.contains('₹');

        if (!isDebit || !hasAmount) continue;

        RegExp amountRegex = RegExp(
          r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        );
        var amountMatch = amountRegex.firstMatch(originalBody);
        double amount = 0.0;
        if (amountMatch != null && amountMatch.group(1) != null) {
          amount =
              double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
        }

        String merchant = address;
        RegExp toRegex = RegExp(
          r'(?:to|info|vpa)\s+([a-zA-Z0-9\.\s@]+?)(?:\s+(?:ref|on|from|via|upi|okk))',
          caseSensitive: false,
        );
        var toMatch = toRegex.firstMatch(originalBody);
        if (toMatch != null && toMatch.group(1) != null) {
          merchant = toMatch.group(1)!.trim();
        }

        if (merchant.length > 20) merchant = merchant.substring(0, 20) + "...";

        String category = _determineCategory(body, merchant);
        IconData icon = _getIconForCategory(category);
        DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

        parsedList.add(
          Transaction(
            id: timestamp.toString() + math.Random().nextInt(1000).toString(),
            title: merchant,
            category: category,
            amount: amount,
            date: date,
            time: TimeOfDay.fromDateTime(date),
            icon: icon,
            isManual: false, // Auto-fetched from Bank
          ),
        );
      }

      _allTransactions = parsedList;
      _sortTransactions();
      isLoading = false;
      notifyListeners();

      // ==========================================
      // NEW: Sync the Android Widget after parsing SMS
      // ==========================================
      syncWidget();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error processing SMS: $e");
    }
  }

  void _sortTransactions() {
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  String _determineCategory(String body, String merchant) {
    String lowerBody = body.toLowerCase();
    String lowerMerchant = merchant.toLowerCase();

    if (lowerBody.contains('zomato') ||
        lowerBody.contains('swiggy') ||
        lowerBody.contains('mcdonald') ||
        lowerBody.contains('domino') ||
        lowerMerchant.contains('restaurant'))
      return "Food & Beverages";
    if (lowerBody.contains('amazon') ||
        lowerBody.contains('flipkart') ||
        lowerBody.contains('myntra') ||
        lowerMerchant.contains('mart'))
      return "Shopping";
    if (lowerBody.contains('petrol') ||
        lowerBody.contains('fuel') ||
        lowerBody.contains('indian oil'))
      return "Fuel";
    if (lowerBody.contains('jio') ||
        lowerBody.contains('airtel') ||
        lowerBody.contains('recharge') ||
        lowerBody.contains('bill'))
      return "Bills & Subscriptions";
    if (lowerBody.contains('upi') ||
        lowerBody.contains('vpa') ||
        lowerBody.contains('sent to'))
      return "To People";
    return "Other";
  }

  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case "Food & Beverages":
        return PhosphorIcons.bowlSteam;
      case "Shopping":
        return PhosphorIcons.tShirt;
      case "Fuel":
        return PhosphorIcons.gasCan;
      case "Bills & Subscriptions":
        return PhosphorIcons.simCard;
      case "To People":
        return PhosphorIcons.user;
      default:
        return PhosphorIcons.currencyInr;
    }
  }

  // --- MANUAL ADD & EDIT ---
  void addExpense(
    String title,
    double amount,
    String category,
    DateTime date,
    TimeOfDay time,
  ) {
    _allTransactions.insert(
      0,
      Transaction(
        id: DateTime.now().toString(),
        title: title,
        category: category,
        amount: amount,
        date: DateTime(date.year, date.month, date.day, time.hour, time.minute),
        time: time,
        icon: _getIconForCategory(category),
        isManual: true, // Labelled as Cash
      ),
    );
    _sortTransactions();
    notifyListeners();

    // ==========================================
    // NEW: Sync the Android Widget after adding an expense
    // ==========================================
    syncWidget();
  }

  void updateExpense(
    String id,
    String title,
    double amount,
    String category,
    TimeOfDay time,
  ) {
    int index = _allTransactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      _allTransactions[index].title = title;

      if (_allTransactions[index].isManual) {
        _allTransactions[index].amount = amount;
        _allTransactions[index].category = category;
        _allTransactions[index].time = time;
        _allTransactions[index].icon = _getIconForCategory(category);

        DateTime oldDate = _allTransactions[index].date;
        _allTransactions[index].date = DateTime(
          oldDate.year,
          oldDate.month,
          oldDate.day,
          time.hour,
          time.minute,
        );
      }

      _sortTransactions();
      notifyListeners();

      syncWidget();
    }
  }

  List<Transaction> getTransactionsForDay(DateTime date) {
    return _allTransactions
        .where(
          (tx) =>
              tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day,
        )
        .toList();
  }

  Future<void> syncWidget() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      int limit = prefs.getInt('daily_expense_limit') ?? 5000;
      await HomeWidget.saveWidgetData<int>('daily_expense_limit', limit);

      final now = DateTime.now();

      // --- NEW: today's total expense + limit as strings for Tree/MiniTree/Greeting widgets ---
      final todaysTx = getTransactionsForDay(now);
      double todayTotal = todaysTx.fold(0, (sum, item) => sum + item.amount);

      await HomeWidget.saveWidgetData<String>(
        'widget_expense_str',
        todayTotal.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_limit_str',
        limit.toString(),
      );

      // --- NEW: recent 4 transactions for the Expenses widget ---
      final recentList = todaysTx.take(4).map((tx) {
        final hour = tx.time.hourOfPeriod == 0 ? 12 : tx.time.hourOfPeriod;
        final minute = tx.time.minute.toString().padLeft(2, '0');
        final period = tx.time.period == DayPeriod.am ? "AM" : "PM";
        return {
          "title": tx.title,
          "category": tx.category,
          "amount": tx.amount,
          "time": "$hour:$minute $period",
          "isManual": tx.isManual,
        };
      }).toList();

      await HomeWidget.saveWidgetData<String>(
        'today_transactions_json',
        jsonEncode(recentList),
      );

      // --- Month map for calendar widget ---
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      Map<String, Map<String, dynamic>> monthMap = {};

      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        if (date.isBefore(now) ||
            (date.year == now.year &&
                date.month == now.month &&
                date.day == now.day)) {
          final dailyTx = getTransactionsForDay(date);
          double total = dailyTx.fold(0, (sum, item) => sum + item.amount);
          monthMap[i.toString()] = {"amount": total};
        }
      }

      String jsonString = jsonEncode(monthMap);
      await HomeWidget.saveWidgetData<String>('transactions_json', jsonString);

      // --- Trigger updates for ALL widgets ---
      await HomeWidget.updateWidget(
        name: 'CalendarWidgetProvider',
        androidName: 'CalendarWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: 'MiniTreeWidgetProvider',
        androidName: 'MiniTreeWidgetProvider',
      );
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
    } catch (e) {
      debugPrint("Failed to sync widget: $e");
    }
  }
}
