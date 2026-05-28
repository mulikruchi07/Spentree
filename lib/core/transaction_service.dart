import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:math' as math;

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
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error processing SMS: $e");
    }
  }

  void _sortTransactions() {
    // Sorts by exact Date and Time descending (Recent on top)
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
        return PhosphorIcons.bowlSteam();
      case "Shopping":
        return PhosphorIcons.tShirt();
      case "Fuel":
        return PhosphorIcons.gasCan();
      case "Bills & Subscriptions":
        return PhosphorIcons.simCard();
      case "To People":
        return PhosphorIcons.user();
      default:
        return PhosphorIcons.currencyInr();
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

      // If it's a bank SMS, we ONLY update the title. The rest stays locked.
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
}
