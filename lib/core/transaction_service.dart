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
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
// Using built-in Material icons instead of PhosphorIconsRegular

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

  // ── Override store key ────────────────────────────────────────────────────
  // JSON string: Map<txId, {title, category}>
  // Persists user edits (title/category) through app restarts.
  static const String _overrideKey = 'tx_overrides';
  static const String _manualKey = 'tx_manual';
  static const String _deletedKey = 'tx_deleted_ids';

  List<Transaction> _allTransactions = [];
  bool isLoading = true;

  List<Transaction> get allTransactions => _allTransactions;

  // ── Init ─────────────────────────────────────────────────────────────────

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

  // Permanently block a transaction ID — works for both SMS and manual transactions.
  Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Add to the persistent deleted-IDs blocklist.
    List<String> deletedIds = prefs.getStringList(_deletedKey) ?? [];
    if (!deletedIds.contains(id)) {
      deletedIds.add(id);
      await prefs.setStringList(_deletedKey, deletedIds);
    }

    // 2. Remove from in-memory list immediately.
    _allTransactions.removeWhere((tx) => tx.id == id);

    // 3. Purge from manual storage so it never reloads on restart.
    final raw = prefs.getString(_manualKey);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        final filtered = decoded.where((item) => item['id'] != id).toList();
        await prefs.setString(_manualKey, jsonEncode(filtered));
      } catch (_) {
        // If manual storage is corrupt, clear it entirely to stay safe.
        await prefs.remove(_manualKey);
      }
    }

    // 4. Remove from overrides store to free up space.
    final overrides = await _loadOverrides();
    if (overrides.containsKey(id)) {
      overrides.remove(id);
      await prefs.setString(_overrideKey, jsonEncode(overrides));
    }

    notifyListeners();
    syncWidget();
  }

  // ── SMS parse ─────────────────────────────────────────────────────────────

  Future<void> _fetchAndParseSms() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSms');
      List<Transaction> parsedList = [];

      for (var sms in result) {
        String body = (sms['body'] ?? '').toLowerCase();
        String originalBody = sms['body'] ?? '';
        String address = sms['address'] ?? 'Unknown';
        int timestamp = sms['date'] ?? 0;

        const debitKeywords = [
          'debited', 'debit', 'dr', 'withdrawn', 'withdrawal', 'spent',
          'purchase', 'paid', 'payment', 'sent', 'transfer', 'transferred',
          'upi', 'imps', 'neft', 'rtgs', 'pos', 'ecom', 'merchant', 'atm',
          'autopay', 'ecs', 'nach', 'mandate', 'emi', 'fee', 'charge', 'deducted'
        ];
        bool isDebit = debitKeywords.any((kw) => body.contains(kw));
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
        // Use timestamp as a stable, deterministic id so overrides survive
        // list rebuilds (the old id used Random which changed on every reload).
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

      // Restore and merge manually created items
      // Load permanently deleted IDs and strip them from parsed SMS list
      final prefs2 = await SharedPreferences.getInstance();
      final deletedIds = Set<String>.from(
        prefs2.getStringList(_deletedKey) ?? [],
      );
      parsedList.removeWhere((tx) => deletedIds.contains(tx.id));

      // Restore and merge manually created items (also filter deleted)
      List<Transaction> manualTx = await _loadManualTransactions();
      manualTx.removeWhere((tx) => deletedIds.contains(tx.id));
      parsedList.addAll(manualTx);

      _allTransactions = parsedList;

      // ── Re-apply persisted overrides ─────────────────────────────────────
      // After every SMS rebuild, restore title/category edits the user made.
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

  // ── Manual Transaction Persistence Fix ───────────────────────────────────

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

  // ── Override persistence ──────────────────────────────────────────────────

  /// Load the override map from SharedPreferences.
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

  /// Apply stored overrides to the current in-memory list.
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

  /// Persist a title/category override for a transaction id.
  Future<void> _saveOverride(String id, String title, String category) async {
    final overrides = await _loadOverrides();
    // Merge with existing data so we don't overwrite the isHidden flag
    final existing = overrides[id] ?? {};

    existing['title'] = title;
    existing['category'] = category;
    overrides[id] = existing;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overrideKey, jsonEncode(overrides));
  }

  // ── Sort ──────────────────────────────────────────────────────────────────

  void _sortTransactions() {
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // ── Category / icon helpers ───────────────────────────────────────────────

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

  // ── Add ───────────────────────────────────────────────────────────────────

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

  // ── Hide / Unhide ─────────────────────────────────────────────────────────

  void toggleTransactionVisibility(String id, bool hide) async {
    int index = _allTransactions.indexWhere((tx) => tx.id == id);
    if (index == -1) return;

    // Update state
    _allTransactions[index].isHidden = hide;

    // Persist this state change without deleting the object
    if (_allTransactions[index].isManual) {
      final prefs = await SharedPreferences.getInstance();
      final manualItems = _allTransactions.where((e) => e.isManual).toList();
      await prefs.setString(_manualKey, jsonEncode(manualItems.map((e) => e.toJson()).toList()));
    } else {
      final overrides = await _loadOverrides();
      final existing = overrides[id] ?? {};
      existing['isHidden'] = hide;
      // Ensure we keep existing data
      existing['title'] = existing['title'] ?? _allTransactions[index].title;
      existing['category'] = existing['category'] ?? _allTransactions[index].category;
      
      overrides[id] = existing;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_overrideKey, jsonEncode(overrides));
    }
    notifyListeners();
    syncWidget();
  }

  // ── Update ────────────────────────────────────────────────────────────────
  //
  // CHANGED:
  // • title, category, icon are now ALWAYS updated regardless of isManual.
  //   The UI (canEditAmount / canEditTime) already ensures amount/time
  //   passed in for auto-fetched transactions are unchanged values.
  // • For auto-fetched transactions the override is persisted so the edit
  //   survives the next SMS re-parse / app restart.

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

      // Re-save entire manual transaction list to preserve edits to manual items
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

  // ── Query ─────────────────────────────────────────────────────────────────

  List<Transaction> getTransactionsForDay(DateTime date) {
    return _allTransactions
        .where(
          (tx) =>
              !tx.isHidden && // hidden transactions are excluded
              tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day,
        )
        .toList();
  }

  /// All non-deleted transactions for a given day — includes hidden ones.
  /// Use ONLY on the Delete screen so users can delete hidden transactions too.
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

  /// Visible (non-hidden) transactions only.
  /// Use this everywhere: Dashboard, Analytics, Forest, SpentWrap calculations.
  List<Transaction> get visibleTransactions =>
      _allTransactions.where((tx) => !tx.isHidden).toList();

  // ── Widget sync ───────────────────────────────────────────────────────────

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