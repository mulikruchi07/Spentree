import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/core/database/local_database_service.dart';
import 'package:spentree/core/database/local_budget.dart';

/// A monthly spending limit set on a single category (e.g. "Food &
/// Beverages: Rs.3000 for April 2026"). Thin, immutable view model wrapping
/// a LocalBudget row — same relationship BucketService's public model has
/// to LocalBucket.
class CategoryBudget {
  final int localId;
  final String? cloudId;
  final String category;
  final double limit;
  final DateTime month; // normalized to the 1st of the month

  CategoryBudget({
    required this.localId,
    required this.cloudId,
    required this.category,
    required this.limit,
    required DateTime month,
  }) : month = DateTime(month.year, month.month, 1);

  factory CategoryBudget.fromLocal(LocalBudget b) => CategoryBudget(
    localId: b.id,
    cloudId: b.cloudId,
    category: b.category,
    limit: b.limit,
    month: b.month,
  );

  /// Stable id for widget keys / removeBudget-style APIs elsewhere in the
  /// UI that expect a String id.
  String get id => cloudId ?? 'local_$localId';
}

/// Budgets is a fully Pro feature — same shape of sync service as
/// BucketService: offline-first (Isar is the source of truth the UI reads
/// from), pushes local changes up via encrypt-budget, pulls the account's
/// budgets down via decrypt-budget on sign-in. Both Edge Functions enforce
/// the Pro gate server-side themselves — this class doesn't duplicate that
/// check for correctness, it's purely a sync/cache layer.
class BudgetService extends ChangeNotifier {
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final _supabase = Supabase.instance.client;
  Isar get _isar => LocalDatabaseService.isar;

  List<CategoryBudget> _budgets = [];
  List<CategoryBudget> get budgets => List.unmodifiable(_budgets);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _monthKey(DateTime month) => "${month.year}-${month.month}";

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Call once at app startup (alongside TransactionService/BucketService
  /// initService()) for an already-signed-in user.
  Future<void> initService() async {
    await _loadFromLocal();
    await _pullFromSupabase();
    await _pushPendingChanges();
  }

  /// Call on sign-in AND sign-out, same as BucketService.resetForNewSession
  /// — wipes in-memory state immediately so a different account signing in
  /// on this device can never see a stale list from a previous session
  /// while its own pull is still in flight.
  Future<void> resetForNewSession() async {
    _budgets = [];
    notifyListeners();

    if (_supabase.auth.currentUser != null) {
      await initService();
    }
  }

  Future<void> _loadFromLocal() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final rows = await _isar.localBudgets
        .filter()
        .userIdEqualTo(uid)
        .isDeletedEqualTo(false)
        .findAll();
    _budgets = rows.map(CategoryBudget.fromLocal).toList();
    notifyListeners();
  }

  // ── Server sync ──────────────────────────────────────────────────────────

  Future<void> _pullFromSupabase() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.functions
          .invoke('decrypt-budget', body: {})
          .timeout(const Duration(seconds: 15));

      if (response.status != 200) {
        debugPrint("decrypt-budget returned status ${response.status}");
        return;
      }

      final rows = response.data as List;

      await _isar.writeTxn(() async {
        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final cloudId = map['id'] as String;
          final category = map['category'] as String;
          final limit = double.tryParse(map['limit_amount'].toString()) ?? 0.0;
          final monthYear = (map['month_year'] as String).split('-');
          final month = DateTime(
            int.parse(monthYear[0]),
            int.parse(monthYear[1]),
            1,
          );

          final existing = await _isar.localBudgets
              .filter()
              .cloudIdEqualTo(cloudId)
              .findFirst();

          if (existing != null) {
            existing
              ..category = category
              ..limit = limit
              ..month = month
              ..isSynced = true
              ..isDeleted = false;
            await _isar.localBudgets.put(existing);
          } else {
            final local = LocalBudget()
              ..cloudId = cloudId
              ..userId = uid
              ..category = category
              ..limit = limit
              ..month = month
              ..isSynced = true
              ..isDeleted = false;
            await _isar.localBudgets.put(local);
          }
        }
      });

      await _loadFromLocal();
    } catch (e) {
      debugPrint("Budget pull failed (offline?): $e");
      // Offline-first: keep whatever's already cached locally, retried on
      // next initService()/app resume.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _pushPendingChanges() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final pending = await _isar.localBudgets
        .filter()
        .userIdEqualTo(uid)
        .isSyncedEqualTo(false)
        .findAll();

    for (final local in pending) {
      await _syncOne(local);
    }
  }

  Future<void> _syncOne(LocalBudget local) async {
    try {
      if (local.isDeleted) {
        if (local.cloudId != null) {
          await _supabase.functions
              .invoke(
                'encrypt-budget',
                body: {'action': 'delete', 'cloud_id': local.cloudId},
              )
              .timeout(const Duration(seconds: 15));
        }
        await _isar.writeTxn(() async {
          await _isar.localBudgets.delete(local.id);
        });
        return;
      }

      final response = await _supabase.functions
          .invoke(
            'encrypt-budget',
            body: {
              'action': local.cloudId == null ? 'insert' : 'update',
              if (local.cloudId != null) 'cloud_id': local.cloudId,
              'category': local.category,
              'limit_amount': local.limit.toString(),
              'month_year': _monthKey(local.month),
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        await _isar.writeTxn(() async {
          local.isSynced = true;
          if (local.cloudId == null && data['id'] != null) {
            local.cloudId = data['id'] as String;
          }
          await _isar.localBudgets.put(local);
        });
      } else {
        debugPrint("encrypt-budget failed: status ${response.status}");
      }
    } catch (e) {
      debugPrint("Budget sync deferred (offline?): $e");
      // isSynced stays false — retried on next initService() call.
    }
  }

  // ── Public API used by the UI ───────────────────────────────────────────

  List<CategoryBudget> budgetsForMonth(DateTime month) {
    return _budgets
        .where(
          (b) => b.month.year == month.year && b.month.month == month.month,
        )
        .toList();
  }

  /// Categories that don't already have a budget set for this month — this
  /// is what the New Budget screen's dropdown is limited to.
  List<String> availableCategoriesForMonth(
    DateTime month,
    List<String> allCategories,
  ) {
    final used = budgetsForMonth(month).map((b) => b.category).toSet();
    return allCategories.where((c) => !used.contains(c)).toList();
  }

  /// Sum of every category limit already set for this month — this is
  /// what shrinks the slider's max for the NEXT category being added.
  double allocatedTotalForMonth(DateTime month) {
    return budgetsForMonth(month).fold(0.0, (sum, b) => sum + b.limit);
  }

  Future<void> addBudget({
    required String category,
    required double limit,
    required DateTime month,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    final local = LocalBudget()
      ..userId = uid
      ..category = category
      ..limit = limit
      ..month = DateTime(month.year, month.month, 1)
      ..isSynced = false
      ..isDeleted = false;

    await _isar.writeTxn(() async {
      await _isar.localBudgets.put(local);
    });

    await _loadFromLocal();
    unawaited(_syncOne(local)); // retried on next initService() if it fails
  }

  Future<void> removeBudget(String id) async {
    final match = _budgets.where((b) => b.id == id).toList();
    if (match.isEmpty) return;
    final target = match.first;

    final local = await _isar.localBudgets.get(target.localId);
    if (local == null) return;

    await _isar.writeTxn(() async {
      local.isDeleted = true;
      local.isSynced = false;
      await _isar.localBudgets.put(local);
    });

    await _loadFromLocal();
    unawaited(_syncOne(local));
  }
}
