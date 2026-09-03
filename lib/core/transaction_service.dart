import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart' show DateUtils;
import 'package:spentree/core/notification_service.dart';
import 'package:spentree/core/user_profile.dart';
import 'package:spentree/screens/private/private_transaction_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';

// Database Imports
import 'package:spentree/core/database/local_database_service.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/user_data.dart';

class TransactionService extends ChangeNotifier {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  final _supabase = Supabase.instance.client;
  static const MethodChannel _channel = MethodChannel('sms_channel');

  List<LocalTransaction> _transactions = [];
  List<LocalTransaction> get allTransactions => _transactions;

  bool isLoading = true;
  bool _isInitialized = false;

  /// 1. INITIALIZE SERVICE
  Future<void> initService() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      isLoading = false;
      notifyListeners();
      return;
    }

    await _loadFromLocal();
    await userProfileNotifier.retryPendingSync();
    await userProfileNotifier.retryPendingImageSync();
    await _migrateOrphanedLocalRows();
    await _fetchAndParseSms();

    _isInitialized = true;

    await _pullFromSupabase()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => debugPrint(
            "Pull timed out — likely offline, proceeding with local data",
          ),
        )
        .catchError((e) => debugPrint("Pull failed: $e"));
    await _loadFromLocal();

    _syncOfflineTransactions();
  }

  Future<void> _migrateOrphanedLocalRows() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final isar = LocalDatabaseService.isar;
    final orphaned = await isar.localTransactions
        .filter()
        .userIdIsNull()
        .findAll();
    if (orphaned.isEmpty) return;
    for (final tx in orphaned) {
      tx.userId = user.id;
      tx.isSynced = false;
    }
    await isar.writeTxn(() async {
      await isar.localTransactions.putAll(orphaned);
    });
  }

  /// 2. LOAD FROM LOCAL ISAR DB
  Future<void> _loadFromLocal() async {
    final isar = LocalDatabaseService.isar;
    final userId = _supabase.auth.currentUser?.id;
    _transactions = await isar.localTransactions
        .filter()
        .isDeletedEqualTo(false)
        .userIdEqualTo(userId)
        .sortByDateTimeDesc()
        .findAll();

    isLoading = false;
    notifyListeners();
    syncWidget();
  }

  /// 3. THE ULTIMATE SMS PARSER
  Future<void> _fetchAndParseSms() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getString('sms_permission_decision_${user.id}');
    if (consent != 'granted') return;

    final status = await Permission.sms.status;
    if (!status.isGranted) return;

    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSms');
      final isar = LocalDatabaseService.isar;
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        debugPrint("SMS import skipped: no authenticated user.");
        return;
      }

      List<LocalTransaction> newTransactionsToSave = [];
      Set<String> processedHashesThisRun = {};

      for (var sms in result) {
        try {
          String originalBody = sms['body'] ?? '';
          String body = originalBody.toLowerCase();
          String address = sms['address'] ?? 'Unknown';
          int timestamp = sms['date'] ?? 0;

          // --- FILTER 1: EXCLUDE INTENT, REQUESTS, PROMOTIONS, & OTPS ---
          bool isIntentOrRequest =
              body.contains('will be debited') ||
              body.contains('has requested money') ||
              body.contains('requested money') ||
              body.contains('scheduled for') ||
              body.contains('is due on') ||
              body.contains('due by');

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

          if (isIntentOrRequest || isOtp) continue;

          // --- FILTER 2: CREDIT / INFLOW / REVERSALS ---
          const creditKeywords = [
            'credited',
            'received',
            'refund',
            'reversal',
            'reversed',
            'deposited',
            'added',
          ];
          bool isCredit = creditKeywords.any((kw) {
            if (kw == 'cr' && body.contains('credit card')) return false;
            return body.contains(kw);
          });
          if (isCredit) continue;

          // --- FILTER 3: FAILURES ---
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
            'unauthorized',
            'declines',
            'rejection',
          ];
          if (failureKeywords.any((kw) => body.contains(kw))) continue;

          // --- FILTER 4: COMPREHENSIVE DEBIT DETECTION ---
          // Includes standard verbs + "Dr." / "Dr " shorthands + POS + Transfers
          RegExp debitPattern = RegExp(
            r'(?:debited|spent|paid|withdrawn|withdrawal|deducted|deduction|sent to|transfer|transferred|purchase|pos txn|pos|\bdr\.?\b|imps|neft|rtgs|charged|txn of|emi of|bill payment)',
            caseSensitive: false,
          );

          bool isDebit = debitPattern.hasMatch(originalBody);
          bool hasAmount =
              body.contains('rs') || body.contains('inr') || body.contains('₹');

          if (!isDebit || !hasAmount) continue;

          // --- FILTER 5: ROBUST AMOUNT EXTRACTION ---
          // Captures Rs, INR, ₹, and double symbols like "Rs. INR 500.00"
          double amount = 0.0;
          RegExp primaryAmountRegex = RegExp(
            r'(?:rs\.?|inr|₹)\s*(?:inr|rs\.?)?\s*([\d,]+(?:\.\d+)?)',
            caseSensitive: false,
          );
          var amountMatch = primaryAmountRegex.firstMatch(originalBody);

          if (amountMatch != null && amountMatch.group(1) != null) {
            amount =
                double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ??
                0.0;
          } else {
            RegExp fallbackAmountRegex = RegExp(
              r'(?:wdl|cash|prch|txn|\bdr\.?\b)\s+(?:[a-z0-9\-]+\s+)?([\d,]+(?:\.\d+)?)',
              caseSensitive: false,
            );
            var fallbackMatch = fallbackAmountRegex.firstMatch(originalBody);
            if (fallbackMatch != null && fallbackMatch.group(1) != null) {
              amount =
                  double.tryParse(
                    fallbackMatch.group(1)!.replaceAll(',', ''),
                  ) ??
                  0.0;
            }
          }

          if (amount <= 0.0) continue;

          // --- FILTER 6: MANDATE SETUP PING FILTER ---
          // Exclude ONLY setup/registration messages with Rs 1.00 or Rs 2.00 pings.
          // Real recurring AutoPay deductions (Rs 69, 199, etc.) pass right through!
          bool isMandateSetup =
              body.contains('mandate registered') ||
              body.contains('mandate setup') ||
              body.contains('e-mandate authorized') ||
              body.contains('autopay setup') ||
              body.contains('standing instruction registered');

          if (isMandateSetup && (amount == 1.0 || amount == 2.0)) {
            continue;
          }

          // --- FILTER 7: ADVANCED RECEIVER/PAYEE EXTRACTION ---
          String merchant = address;

          RegExp merchantRegex = RegExp(
            r'(?:to|towards|at|vpa|info|merchnt:|merchant:|for upi payment to|spent on card xx\d+ at)\s+([a-zA-Z0-9.\s@-]+?)(?:\s*(?:;|\.|,|\s+(?:ref|rrn|on|from|via|upi|okk|bal|avl|limit|seq|card|a/c|ending|statement|dr|cr|is|if|dial|-)))',
            caseSensitive: false,
          );

          var merchantMatch = merchantRegex.firstMatch(originalBody);

          if (merchantMatch != null && merchantMatch.group(1) != null) {
            merchant = merchantMatch.group(1)!.trim();
          } else {
            if (body.contains('pos')) {
              merchant = "POS Transaction";
            } else if (body.contains('td payin')) {
              merchant = "Term Deposit Pay-In";
            } else {
              RegExp coopBranchRegex = RegExp(
                r'([a-zA-Z\s\-]+(?:\sbranch|\satm|\spos))',
                caseSensitive: false,
              );
              var coopMatch = coopBranchRegex.firstMatch(originalBody);
              if (coopMatch != null && coopMatch.group(1) != null) {
                merchant = coopMatch.group(1)!.trim();
              }
            }
          }

          merchant = merchant
              .replaceAll(RegExp(r'[\s;.]+$'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (merchant.length > 25) {
            merchant = merchant.substring(0, 25) + "...";
          }

          // --- CREATE UNIQUE HASH FOR DEDUPLICATION ---
          String category = _determineCategory(body, merchant);
          DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

          String uniqueSmsHash =
              "${timestamp}_${amount.toStringAsFixed(2)}_${originalBody.hashCode}";

          if (processedHashesThisRun.contains(uniqueSmsHash)) continue;
          processedHashesThisRun.add(uniqueSmsHash);

          final existing = await isar.localTransactions
              .filter()
              .smsHashEqualTo(uniqueSmsHash)
              .userIdEqualTo(currentUserId)
              .findFirst();

          if (existing == null) {
            final newTx = LocalTransaction()
              ..amount = amount
              ..receiverName = merchant
              ..category = category
              ..dateTime = date
              ..type = 'Bank'
              ..isHidden = false
              ..isDeleted = false
              ..isSynced = false
              ..userId = currentUserId
              ..smsHash = uniqueSmsHash;

            newTransactionsToSave.add(newTx);
          }
        } catch (e) {
          debugPrint("Failed to parse individual SMS: $e");
        }
      }

      if (newTransactionsToSave.isNotEmpty) {
        for (var tx in newTransactionsToSave) {
          try {
            await isar.writeTxn(() async {
              await isar.localTransactions.put(tx);
            });
          } catch (e) {
            debugPrint("Skipped a duplicate/conflicting SMS: $e");
          }
        }
        await _loadFromLocal();
        await _checkAndNotifyOverspend();
      }
    } catch (e) {
      debugPrint("Fatal error processing SMS batch: $e");
    }
  }

  /// 4. ADD MANUAL EXPENSE (CASH)
  Future<void> addExpense(
    String title,
    double amount,
    String category,
    DateTime date,
    TimeOfDay time,
  ) async {
    final isar = LocalDatabaseService.isar;

    final newTx = LocalTransaction()
      ..amount = amount
      ..receiverName = title
      ..category = category
      ..type = 'Cash'
      ..dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      )
      ..isHidden = false
      ..isDeleted = false
      ..isSynced = false
      ..userId = _supabase.auth.currentUser?.id;

    await isar.writeTxn(() async {
      await isar.localTransactions.put(newTx);
    });

    await _loadFromLocal();
    _pushToSupabase(newTx);
    await _checkAndNotifyOverspend();
  }

  /// 5. UPDATE EXISTING EXPENSE
  Future<void> updateExpense(
    int localId,
    String title,
    double amount,
    String category,
    TimeOfDay time,
  ) async {
    final isar = LocalDatabaseService.isar;
    final tx = await isar.localTransactions.get(localId);
    if (tx == null) return;

    tx.receiverName = title;
    tx.category = category;

    if (tx.type == 'Cash') {
      tx.amount = amount;
      tx.dateTime = DateTime(
        tx.dateTime.year,
        tx.dateTime.month,
        tx.dateTime.day,
        time.hour,
        time.minute,
      );
    }

    tx.isSynced = false;

    await isar.writeTxn(() async {
      await isar.localTransactions.put(tx);
    });

    await _loadFromLocal();
    _pushToSupabase(tx);
  }

  /// 6. SOFT DELETE TRANSACTION
  Future<void> deleteTransaction(int localId) async {
    final isar = LocalDatabaseService.isar;
    final tx = await isar.localTransactions.get(localId);
    if (tx == null) return;

    tx.isDeleted = true;
    tx.isSynced = false;

    await isar.writeTxn(() async {
      await isar.localTransactions.put(tx);
    });

    await _loadFromLocal();

    if (tx.cloudId != null) {
      _deleteFromSupabase(tx);
    }
  }

  /// 7. HIDE / UNHIDE TRANSACTION
  Future<void> toggleTransactionVisibility(int localId, bool hide) async {
    final isar = LocalDatabaseService.isar;
    final tx = await isar.localTransactions.get(localId);
    if (tx == null) return;

    tx.isHidden = hide;
    tx.isSynced = false;

    await isar.writeTxn(() async {
      await isar.localTransactions.put(tx);
    });

    await _loadFromLocal();
    _pushToSupabase(tx);
  }

  /// 8. MOVE IN / OUT OF PERSONAL VAULT
  Future<void> togglePersonalVisibility(int localId, bool isPersonal) async {
    final isar = LocalDatabaseService.isar;
    final tx = await isar.localTransactions.get(localId);
    if (tx == null) return;

    tx.isPersonal = isPersonal;
    tx.isSynced = false;

    await isar.writeTxn(() async {
      await isar.localTransactions.put(tx);
    });

    await _loadFromLocal();
    _pushToSupabase(tx);
  }

  // ==========================================
  // CLOUD SYNC LOGIC (SUPABASE)
  // ==========================================

  Future<void> _syncOfflineTransactions() async {
    final isar = LocalDatabaseService.isar;

    final pendingUpdates = await isar.localTransactions
        .filter()
        .isSyncedEqualTo(false)
        .isDeletedEqualTo(false)
        .findAll();

    // FIX: Process sequentially instead of using Future.wait concurrency
    for (var tx in pendingUpdates) {
      await _pushToSupabase(tx);
      // Add a 150ms delay to prevent Postgres connection exhaustion
      await Future.delayed(const Duration(milliseconds: 150));
    }

    final pendingDeletes = await isar.localTransactions
        .filter()
        .isSyncedEqualTo(false)
        .isDeletedEqualTo(true)
        .findAll();

    for (var tx in pendingDeletes) {
      await _deleteFromSupabase(tx);
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> _pullFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _supabase.functions
          .invoke('decrypt-transaction', body: {})
          .timeout(const Duration(seconds: 20));

      if (response.status != 200) {
        debugPrint("Pull from Supabase failed: status ${response.status}");
        return;
      }

      final rows = response.data as List;
      final isar = LocalDatabaseService.isar;

      for (final row in rows) {
        final cloudId = row['id'].toString();
        final existing = await isar.localTransactions
            .filter()
            .cloudIdEqualTo(cloudId)
            .findFirst();
        if (existing != null) continue;

        final smsHash = row['sms_hash'] as String?;
        if (smsHash != null) {
          final byHash = await isar.localTransactions
              .filter()
              .smsHashEqualTo(smsHash)
              .findFirst();
          if (byHash != null) continue;
        }

        final pulled = LocalTransaction()
          ..cloudId = cloudId
          ..userId = user.id
          ..amount = double.parse(row['amount'] as String)
          ..receiverName = row['receiver_name'] as String
          ..category = row['category'] as String
          ..dateTime = DateTime.parse(row['date_time'] as String).toLocal()
          ..type = row['type'] as String
          ..isHidden = row['is_hidden'] as bool? ?? false
          ..isPersonal = row['is_personal'] as bool? ?? false
          ..isDeleted = false
          ..isSynced = true
          ..smsHash = smsHash;

        await isar.writeTxn(
          () async => await isar.localTransactions.put(pulled),
        );
      }
    } catch (e) {
      debugPrint("Pull from Supabase failed: $e");
    }
  }

  Future<void> _pushToSupabase(LocalTransaction tx) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final payload = {
        'action': tx.cloudId == null ? 'insert' : 'update',
        'cloud_id': tx.cloudId,
        'user_id': user.id,
        'amount': tx.amount,
        'receiver_name': tx.receiverName,
        'category': tx.category,
        'type': tx.type,
        'date_time': tx.dateTime.toIso8601String(),
        'is_hidden': tx.isHidden,
        'is_personal': tx.isPersonal,
        'sms_hash': tx.smsHash,
      };

      final response = await _supabase.functions
          .invoke('encrypt-transaction', body: payload)
          .timeout(const Duration(seconds: 10));

      if (response.status != 200) throw Exception('Encrypt sync failed');
      final data = response.data as Map;
      if (tx.cloudId == null) tx.cloudId = data['id'];

      tx.isSynced = true;
      final isar = LocalDatabaseService.isar;
      await isar.writeTxn(() async => await isar.localTransactions.put(tx));
    } catch (e) {
      debugPrint("Supabase sync failed: $e");
    }
  }

  Future<void> resetForNewUser() async {
    _isInitialized = false;
    _transactions = [];
    isLoading = true;
    notifyListeners();
    await initService();
  }

  Future<void> _checkAndNotifyOverspend() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('spending_alerts_user_enabled') ?? true)) return;

    final limit = prefs.getInt('daily_expense_limit') ?? 500;
    final todayTotal = getTransactionsForDay(
      DateTime.now(),
    ).fold(0.0, (sum, tx) => sum + tx.amount);

    if (todayTotal > limit) {
      const androidDetails = AndroidNotificationDetails(
        'spend_alerts',
        'Spending Alerts',
        importance: Importance.high,
        priority: Priority.high,
      );
      await FlutterLocalNotificationsPlugin().show(
        0,
        "You've exceeded your daily limit",
        "Today's spending is Rs. ${todayTotal.toStringAsFixed(0)}, over your Rs. $limit limit.",
        const NotificationDetails(android: androidDetails),
      );
    }
  }

  Future<void> _deleteFromSupabase(LocalTransaction tx) async {
    try {
      if (tx.cloudId != null) {
        await _supabase.from('transactions').delete().eq('id', tx.cloudId!);
      }

      if (tx.type == 'Cash') {
        final isar = LocalDatabaseService.isar;
        await isar.writeTxn(() async {
          await isar.localTransactions.delete(tx.id);
        });
      } else {
        tx.isSynced = true;
        final isar = LocalDatabaseService.isar;
        await isar.writeTxn(() async {
          await isar.localTransactions.put(tx);
        });
      }
    } catch (e) {
      debugPrint("Supabase delete failed: $e");
    }
  }

  // ==========================================
  // HELPERS & GETTERS FOR UI
  // ==========================================

  List<LocalTransaction> get personalTransactions => _transactions
      .where((tx) => !tx.isHidden && !tx.isDeleted && tx.isPersonal)
      .toList();

  // UPDATED: Exclude personal transactions from daily dashboard
  List<LocalTransaction> getTransactionsForDay(DateTime date) {
    return _transactions
        .where(
          (tx) =>
              !tx.isHidden &&
              !tx.isPersonal &&
              tx.dateTime.year == date.year &&
              tx.dateTime.month == date.month &&
              tx.dateTime.day == date.day,
        )
        .toList();
  }

  List<LocalTransaction> getAllTransactionsForDay(DateTime date) {
    return _transactions
        .where(
          (tx) =>
              tx.dateTime.year == date.year &&
              tx.dateTime.month == date.month &&
              tx.dateTime.day == date.day,
        )
        .toList();
  }

  List<LocalTransaction> get visibleTransactions => _transactions
      .where(
        (tx) =>
            !tx.isHidden &&
            !tx.isDeleted &&
            !PrivateTransactionService().isPrivate(tx.id),
      )
      .toList();

  String _determineCategory(String body, String merchant) {
    String lowerBody = body.toLowerCase();
    String lowerMerchant = merchant.toLowerCase();

    if (lowerBody.contains('zomato') ||
        lowerBody.contains('swiggy') ||
        lowerBody.contains('mcdonald') ||
        lowerBody.contains('domino') ||
        lowerMerchant.contains('restaurant') ||
        lowerBody.contains('starbucks') ||
        lowerBody.contains('zepto')) {
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

  IconData getIconForCategory(String cat) {
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

  Future<void> syncWidget() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      int limit = prefs.getInt('daily_expense_limit') ?? 500;
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
        final hour = tx.dateTime.hour == 0
            ? 12
            : (tx.dateTime.hour > 12
                  ? tx.dateTime.hour - 12
                  : tx.dateTime.hour);
        final minute = tx.dateTime.minute.toString().padLeft(2, '0');
        final period = tx.dateTime.hour >= 12 ? "PM" : "AM";
        return {
          "title": tx.receiverName,
          "category": tx.category,
          "amount": tx.amount,
          "time": "$hour:$minute $period",
          "isManual": tx.type == 'Cash',
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
