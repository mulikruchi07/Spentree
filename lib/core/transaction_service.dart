import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart' show DateUtils;
import 'package:spentree/core/user_data.dart';

class Transaction {
  String id;
  String title;
  String category;
  double amount;
  DateTime date;
  TimeOfDay time;
  IconData icon;
  bool isManual;
  bool isHidden;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    required this.icon,
    this.isManual = false,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'hour': time.hour,
    'minute': time.minute,
    'isManual': isManual,
    'isHidden': isHidden,
  };

  factory Transaction.fromJson(
    Map<String, dynamic> json,
    IconData Function(String) getIcon,
  ) {
    final parsedDate = DateTime.parse(json['date']);
    return Transaction(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: parsedDate,
      time: TimeOfDay(hour: json['hour'], minute: json['minute']),
      icon: getIcon(json['category']),
      isManual: json['isManual'] ?? false,
      isHidden: json['isHidden'] ?? false,
    );
  }
}

class TransactionService extends ChangeNotifier {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  static const MethodChannel _channel = MethodChannel('sms_channel');

  static const String _overrideKey = 'tx_overrides';
  static const String _manualKey = 'tx_manual';
  static const String _deletedKey = 'tx_deleted_ids';

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

  Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> deletedIds = prefs.getStringList(_deletedKey) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(_deletedKey, deletedIds);
    }

    _allTransactions.removeWhere((tx) => tx.id == id);

    final raw = prefs.getString(_manualKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        final filtered = decoded.where((item) => item['id'] != id).toList();
        await prefs.setString(_manualKey, jsonEncode(filtered));
      } catch (_) {
        await prefs.remove(_manualKey);
      }
    }

    final overrides = await _loadOverrides();
    if (overrides.containsKey(id)) {
      overrides.remove(id);
      await prefs.setString(_overrideKey, jsonEncode(overrides));
    }

    notifyListeners();
    syncWidget();
  }

  Future<void> _fetchAndParseSms() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSms');
      List<Transaction> parsedList = [];

      for (var sms in result) {
        String originalBody = sms['body'] ?? '';
        String body = originalBody.toLowerCase();
        String address = sms['address'] ?? 'Unknown';
        int timestamp = sms['date'] ?? 0;

        const blocklist = ['mandate', 'autopay', 'standing instruction', 'si registered', 'e-mandate', 'si debit'];
  if (blocklist.any((kw) => body.contains(kw))) {
    continue; 
  }

        // 1. Credit & Inflow Exclusion Check [2]
        const creditKeywords = [
          'credited',
          'received',
          'refund',
          'reversal',
          'deposited',
          'cr',
        ];
        bool isCredit = creditKeywords.any((kw) {
          if (kw == 'cr' && body.contains('credit card')) return false;
          return body.contains(kw);
        });
        if (isCredit) continue;

        // 2. Failure & Unsuccessful Exclusion Check [3, 4, 5, 6]
        const failureKeywords = [
          'failed',
          'declined',
          'bounced',
          'insufficient',
          'unsuccessful',
          'rejected',
          'could not',
          'returned',
          'locked',
          'block',
          'limit is less',
          'non compliant',
          'bounces',
          'unauthorized',
          'declines',
          'rejection',
        ];
        bool isFailure = failureKeywords.any((kw) => body.contains(kw));
        if (isFailure) continue;

        // 3. OTP and Authentication Exclusion Check [7, 4]
        const otpKeywords = [
          'otp',
          'verification code',
          'is your secret',
          'do not share',
          'valid for',
          'auth code',
          'one time password',
        ];
        bool isOtp = otpKeywords.any((kw) => body.contains(kw));
        if (isOtp) continue;

        // 4. Predictive Recurring Mandate Intimation Alert Exclusion Check [9]
        const predictiveKeywords = [
          'is due on',
          'will be processed',
          'scheduled for',
          'upcoming',
          'due by',
        ];
        bool isPredictive = predictiveKeywords.any((kw) => body.contains(kw));
        if (isPredictive) continue;

        // 5. Outflow Identification (Famous & Local/Cooperative Bank Legacy "WDL" keywords)
        const debitKeywords = [
          'debited',
          'debit',
          'withdrawn',
          'withdrawal',
          'spent',
          'purchase',
          'paid',
          'sent',
          'transfer',
          'transferred',
          'imps',
          'neft',
          'rtgs',
          'pos',
          'merchant',
          'atm',
          'deducted',
          'wdl',
        ];
        bool isDebit = debitKeywords.any((kw) => body.contains(kw));
        if (!isDebit) continue;

        // 6. Extract Amount
        double amount = 0.0;

        // Primary Regex Pattern for Scheduled Commercial Banks [1]
        RegExp primaryAmountRegex = RegExp(
          r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        );
        var amountMatch = primaryAmountRegex.firstMatch(originalBody);

        if (amountMatch != null && amountMatch.group(1) != null) {
          amount =
              double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
        } else {
          // Legacy Fallback Regex matching Cooperative Banks ("ATM WDL 700.00" style) [11, 12, 2]
          RegExp fallbackAmountRegex = RegExp(
            r'(?:wdl|cash|prch|txn|dr)\s+(?:[a-z0-9\-]+\s+)?([\d,]+\.\d{2})',
            caseSensitive: false,
          );
          var fallbackMatch = fallbackAmountRegex.firstMatch(originalBody);
          if (fallbackMatch != null && fallbackMatch.group(1) != null) {
            amount =
                double.tryParse(fallbackMatch.group(1)!.replaceAll(',', '')) ??
                0.0;
          }
        }

        if (amount <= 0.0) continue; // Ignore empty or zero balance records

        // 8. Payee / Receiver Name Extraction [2]
        String merchant = address;

        RegExp merchantRegex = RegExp(
          r'(?:to|towards|at|info|vpa|merchnt:|merchant:|spent on card xx\d+ at)\s+([a-zA-Z0-9\.\s@\-]+?)(?:\s+(?:ref|on|from|via|upi|okk|bal|avl|limit|seq|card|a/c|ending|statement|dr|cr|\.))',
          caseSensitive: false,
        );

        var merchantMatch = merchantRegex.firstMatch(originalBody);
        if (merchantMatch != null && merchantMatch.group(1) != null) {
          merchant = merchantMatch.group(1)!.trim();
        } else {
          // Cooperative legacy location-based/branch naming fallback [10]
          RegExp coopBranchRegex = RegExp(
            r'([a-zA-Z\s\-]+(?:\sbranch|\satm|\spos))',
            caseSensitive: false,
          );
          var coopMatch = coopBranchRegex.firstMatch(originalBody);
          if (coopMatch != null && coopMatch.group(1) != null) {
            merchant = coopMatch.group(1)!.trim();
          }
        }

        merchant = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (merchant.length > 20) {
          merchant = merchant.substring(0, 20) + "...";
        }

        String category = _determineCategory(body, merchant);
        IconData icon = _getIconForCategory(category);
        DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        String id = timestamp.toString();

        parsedList.add(
          Transaction(
            id: id,
            title: merchant,
            category: category,
            amount: amount,
            date: date,
            time: TimeOfDay.fromDateTime(date),
            icon: icon,
            isManual: false,
          ),
        );
      }

      final prefs2 = await SharedPreferences.getInstance();
      final deletedIds = Set<String>.from(
        prefs2.getStringList(_deletedKey) ?? [],
      );
      parsedList.removeWhere((tx) => deletedIds.contains(tx.id));

      List<Transaction> manualTx = await _loadManualTransactions();
      manualTx.removeWhere((tx) => deletedIds.contains(tx.id));
      parsedList.addAll(manualTx);

      _allTransactions = parsedList;

      await _applyOverrides();

      _sortTransactions();
      isLoading = false;
      notifyListeners();
      syncWidget();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint("Error processing SMS: $e");
    }
  }

  Future<List<Transaction>> _loadManualTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_manualKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((item) => Transaction.fromJson(item, _getIconForCategory))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveManualTransaction(Transaction tx) async {
    final manualList = await _loadManualTransactions();
    manualList.add(tx);
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(manualList.map((e) => e.toJson()).toList());
    await prefs.setString(_manualKey, encoded);
  }

  Future<Map<String, dynamic>> _loadOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_overrideKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _applyOverrides() async {
    final overrides = await _loadOverrides();
    for (final tx in _allTransactions) {
      final entry = overrides[tx.id];
      if (entry != null) {
        final title = entry['title'] as String?;
        final category = entry['category'] as String?;
        final isHidden = entry['isHidden'] as bool?;
        if (title != null && title.isNotEmpty) tx.title = title;
        if (category != null && category.isNotEmpty) {
          tx.category = category;
          tx.icon = _getIconForCategory(category);
        }
        if (isHidden != null) {
          tx.isHidden = isHidden;
        }
      }
    }
  }

  Future<void> _saveOverride(String id, String title, String category) async {
    final overrides = await _loadOverrides();
    final existing = overrides[id] ?? {};

    existing['title'] = title;
    existing['category'] = category;
    overrides[id] = existing;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overrideKey, jsonEncode(overrides));
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
        lowerMerchant.contains('restaurant') ||
        lowerBody.contains('starbucks')) {
      return "Food & Beverages";
    }
    if (lowerBody.contains('amazon') ||
        lowerBody.contains('flipkart') ||
        lowerBody.contains('myntra') ||
        lowerMerchant.contains('mart') ||
        lowerBody.contains('shopping')) {
      return "Shopping";
    }
    if (lowerBody.contains('petrol') ||
        lowerBody.contains('fuel') ||
        lowerBody.contains('indian oil') ||
        lowerBody.contains('bpcl')) {
      return "Fuel";
    }
    if (lowerBody.contains('jio') ||
        lowerBody.contains('airtel') ||
        lowerBody.contains('recharge') ||
        lowerBody.contains('bill') ||
        lowerBody.contains('netflix') ||
        lowerBody.contains('spotify')) {
      return "Bills & Subscriptions";
    }
    if (lowerBody.contains('upi') ||
        lowerBody.contains('vpa') ||
        lowerBody.contains('sent to') ||
        lowerBody.contains('transfer to')) {
      return "To People";
    }
    return "Other";
  }

  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case "Food & Beverages":
        return PhosphorIconsRegular.bowlSteam;
      case "Shopping":
        return PhosphorIconsRegular.tShirt;
      case "Fuel":
        return PhosphorIconsRegular.gasCan;
      case "Bills & Subscriptions":
        return PhosphorIconsRegular.simCard;
      case "To People":
        return PhosphorIconsRegular.user;
      default:
        return PhosphorIconsRegular.currencyInr;
    }
  }

  void addExpense(
    String title,
    double amount,
    String category,
    DateTime date,
    TimeOfDay time,
  ) async {
    final id =
        DateTime.now().millisecondsSinceEpoch.toString() +
        math.Random().nextInt(1000).toString();

    final newTx = Transaction(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: DateTime(date.year, date.month, date.day, time.hour, time.minute),
      time: time,
      icon: _getIconForCategory(category),
      isManual: true,
    );

    _allTransactions.insert(0, newTx);
    await _saveManualTransaction(newTx);

    _sortTransactions();
    notifyListeners();
    syncWidget();
  }

  void toggleTransactionVisibility(String id, bool hide) async {
    int index = _allTransactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;

    _allTransactions[index].isHidden = hide;

    if (_allTransactions[index].isManual) {
      final prefs = await SharedPreferences.getInstance();
      final manualItems = _allTransactions.where((e) => e.isManual).toList();
      await prefs.setString(
        _manualKey,
        jsonEncode(manualItems.map((e) => e.toJson()).toList()),
      );
    } else {
      final overrides = await _loadOverrides();
      final existing = overrides[id] ?? {};
      existing['isHidden'] = hide;
      existing['title'] = existing['title'] ?? _allTransactions[index].title;
      existing['category'] =
          existing['category'] ?? _allTransactions[index].category;

      overrides[id] = existing;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_overrideKey, jsonEncode(overrides));
    }
    notifyListeners();
    syncWidget();
  }

  void updateExpense(
    String id,
    String title,
    double amount,
    String category,
    TimeOfDay time,
  ) async {
    int index = _allTransactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;

    _allTransactions[index].title = title;
    _allTransactions[index].category = category;
    _allTransactions[index].icon = _getIconForCategory(category);

    if (_allTransactions[index].isManual) {
      _allTransactions[index].amount = amount;
      _allTransactions[index].time = time;

      DateTime oldDate = _allTransactions[index].date;
      _allTransactions[index].date = DateTime(
        oldDate.year,
        oldDate.month,
        oldDate.day,
        time.hour,
        time.minute,
      );

      final prefs = await SharedPreferences.getInstance();
      final manualItems = _allTransactions
          .where((element) => element.isManual)
          .toList();
      await prefs.setString(
        _manualKey,
        jsonEncode(manualItems.map((e) => e.toJson()).toList()),
      );
    }

    await _saveOverride(id, title, category);

    _sortTransactions();
    notifyListeners();
    syncWidget();
  }

  List<Transaction> getTransactionsForDay(DateTime date) {
    return _allTransactions
        .where(
          (tx) =>
              !tx.isHidden &&
              tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day,
        )
        .toList();
  }

  List<Transaction> getAllTransactionsForDay(DateTime date) {
    return _allTransactions
        .where(
          (tx) =>
              tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day,
        )
        .toList();
  }

  List<Transaction> get visibleTransactions =>
      _allTransactions.where((tx) => !tx.isHidden).toList();

  Future<void> syncWidget() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      int limit = prefs.getInt('daily_expense_limit') ?? 5000;
      await HomeWidget.saveWidgetData<int>('daily_expense_limit', limit);

      final now = DateTime.now();

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
      await HomeWidget.saveWidgetData<String>(
        'widget_user_name',
        UserData.userName,
      );

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

      await HomeWidget.saveWidgetData<String>(
        'transactions_json',
        jsonEncode(monthMap),
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
