import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spentree/core/database/local_bucket.dart';
import 'package:spentree/core/database/local_database_service.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/transaction_service.dart';

/// A bucket groups two or more existing expenses together (e.g. "Goa
/// Friends Trip"). `id` is a locally-generated identity used by the UI
/// (widget keys, expand/collapse state, navigation) — it has nothing to
/// do with sync and the three screens never need to know about `localId`
/// / `cloudId` below.
class Bucket {
  final String id;
  String name;
  List<LocalTransaction> transactions;

  // Sync bookkeeping only — invisible to the UI layer.
  int? localId; // LocalBucket.id (Isar)
  String? cloudId; // Supabase buckets.id

  Bucket({
    required this.id,
    required this.name,
    List<LocalTransaction>? transactions,
    this.localId,
    this.cloudId,
  }) : transactions = transactions ?? [];

  double get total => transactions.fold(0.0, (sum, t) => sum + t.amount);

  Set<int> get transactionIds => transactions.map((t) => t.id).toSet();

  /// The month this bucket "lives" in on the Buckets list — whichever
  /// month among its expenses has the most expense cards. Ties go to the
  /// more recent month.
  DateTime get dominantMonth {
    if (transactions.isEmpty) return DateTime.now();
    final Map<String, int> counts = {};
    final Map<String, DateTime> keyToDate = {};

    for (final tx in transactions) {
      final key = "${tx.dateTime.year}-${tx.dateTime.month}";
      counts[key] = (counts[key] ?? 0) + 1;
      keyToDate[key] = DateTime(tx.dateTime.year, tx.dateTime.month);
    }

    String bestKey = counts.keys.first;
    for (final key in counts.keys) {
      final better =
          counts[key]! > counts[bestKey]! ||
          (counts[key] == counts[bestKey] &&
              keyToDate[key]!.isAfter(keyToDate[bestKey]!));
      if (better) bestKey = key;
    }
    return keyToDate[bestKey]!;
  }
}

/// Caps how many bucket-sync network calls can be in flight at once,
/// shared by live edits AND the startup offline-sync sweep — so a burst
/// of activity (or a big backlog after being offline) never fires a pile
/// of simultaneous requests at Supabase.
class _Semaphore {
  _Semaphore(this._max);
  final int _max;
  int _current = 0;
  final Queue<Completer<void>> _waiting = Queue();

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    } else {
      _current--;
    }
  }

  Future<T> run<T>(Future<T> Function() task) async {
    await acquire();
    try {
      return await task();
    } finally {
      release();
    }
  }
}

class BucketService extends ChangeNotifier {
  static final BucketService _instance = BucketService._internal();
  factory BucketService() => _instance;
  BucketService._internal() {
    // Re-resolve every bucket's expenses against live TransactionService
    // data on every change (edit, delete, SMS import) — persists that
    // resolution locally and re-syncs to Supabase when it changes what's
    // stored there.
    TransactionService().addListener(_syncWithTransactions);
  }

  final _supabase = Supabase.instance.client;
  final _networkGate = _Semaphore(3);

  final List<Bucket> _buckets = [];
  List<Bucket> get buckets => List.unmodifiable(_buckets);

  bool _isInitialized = false;
  String? _initializedForUserId;

  // Gates _syncWithTransactions() below. Off during sign-out and during
  // the gap between a fresh sign-in and this service's own load
  // finishing — those are exactly the windows where TransactionService
  // can transiently report an EMPTY list while it's clearing/reloading
  // for a session change, which is not a real "all transactions were
  // deleted" signal and must never be treated as one.
  bool _listeningEnabled = false;

  // Per-bucket (by Isar localId) debounce timer + serialized push chain —
  // together these mean: rapid edits to the same bucket collapse into one
  // network call carrying the latest state, and that call can never
  // overlap with another push for the same row (the exact race that was
  // creating duplicate/orphaned cloud rows).
  final Map<int, Timer> _debounceTimers = {};
  final Map<int, Future<void>> _pushChains = {};

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ==========================================
  // 1. INITIALIZE / RESET
  // ==========================================

  /// Call once after TransactionService.initService() — either right
  /// after a fresh sign-in, or at app launch if a session already exists.
  Future<void> initService() async {
    final userId = _supabase.auth.currentUser?.id;

    // Already initialized for THIS account — nothing to do. This guard is
    // what makes it safe to call initService() defensively from more than
    // one place without re-pulling on every call.
    if (_isInitialized && _initializedForUserId == userId) return;

    await _loadFromLocal();

    await _pullFromSupabase()
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => debugPrint(
            "Bucket pull timed out — likely offline, proceeding with local data",
          ),
        )
        .catchError((e) => debugPrint("Bucket pull failed: $e"));
    await _loadFromLocal();

    _isInitialized = true;
    _initializedForUserId = userId;
    _listeningEnabled = true;
    unawaited(_syncOfflineBuckets());
  }

  /// MUST be called on sign-out AND right after a fresh sign-in — wire
  /// this into your auth-state listener (see notes in my reply). Clears
  /// only the IN-MEMORY state; nothing here touches Supabase, so a
  /// signed-out user's buckets stay exactly where they are in the cloud
  /// and simply get pulled back down the next time someone signs in.
  Future<void> resetForNewSession() async {
    // First thing, no exceptions: stop reacting to TransactionService
    // while the session is in flux. This is the actual fix — everything
    // below (clearing buckets, timers, etc.) was already safe; the bug
    // was _syncWithTransactions() firing DURING this transition off the
    // back of TransactionService's own logout-triggered clear.
    _listeningEnabled = false;

    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _pushChains.clear();

    _isInitialized = false;
    _initializedForUserId = null;
    _buckets.clear();
    notifyListeners();

    // Re-initialize immediately if someone is actually signed in now
    // (covers the sign-in case in one call); on sign-out this just
    // leaves things empty until the next sign-in calls initService().
    if (_supabase.auth.currentUser != null) {
      await initService();
    }
  }

  // ==========================================
  // 2. LOAD FROM LOCAL ISAR DB
  // ==========================================
  Future<void> _loadFromLocal() async {
    final isar = LocalDatabaseService.isar;
    final userId = _supabase.auth.currentUser?.id;

    final rows = await isar.localBuckets
        .filter()
        .isDeletedEqualTo(false)
        .userIdEqualTo(userId)
        .findAll();

    final txById = <int, LocalTransaction>{
      for (final tx in TransactionService().allTransactions) tx.id: tx,
    };

    _buckets
      ..clear()
      ..addAll(
        rows.map((row) {
          final resolved = row.transactionLocalIds
              .map((id) => txById[id])
              .whereType<LocalTransaction>()
              .toList();
          return Bucket(
            id: row.id.toString(),
            name: row.name,
            transactions: resolved,
            localId: row.id,
            cloudId: row.cloudId,
          );
        }),
      );

    notifyListeners();
  }

  // ==========================================
  // 3. LIVE SYNC AGAINST TRANSACTION CHANGES
  // ==========================================
  Future<void> _syncWithTransactions() async {
    if (!_listeningEnabled) return;
    // TransactionService's own list isn't trustworthy while IT is still
    // mid-load (e.g. right after login, on the loading screen) — an
    // in-flight reload can transiently look empty. Wait for it to settle
    // before treating its contents as authoritative for anything.
    if (TransactionService().isLoading) return;
    if (_buckets.isEmpty) return;

    final isar = LocalDatabaseService.isar;
    final byId = <int, LocalTransaction>{
      for (final tx in TransactionService().allTransactions) tx.id: tx,
    };

    bool anyVisibleChange = false;
    final bucketsToRemove = <Bucket>[];

    for (final bucket in _buckets) {
      // Re-resolve from the PERSISTED id list in Isar, never from the
      // bucket's current in-memory `transactions` — that in-memory list
      // can be an incomplete snapshot taken while TransactionService
      // hadn't finished loading yet, and trusting it here would
      // permanently narrow (and eventually delete) a perfectly fine
      // bucket the first time this ever runs after a fresh login.
      List<int> persistedIds = bucket.transactionIds.toList();
      if (bucket.localId != null) {
        final row = await isar.localBuckets.get(bucket.localId!);
        if (row != null) persistedIds = row.transactionLocalIds;
      }

      final resolved = persistedIds
          .map((id) => byId[id])
          .whereType<LocalTransaction>()
          .toList();

      final contentChanged = !_sameContent(resolved, bucket.transactions);
      if (contentChanged) anyVisibleChange = true;
      bucket.transactions = resolved;

      // A referenced expense was edited elsewhere and deleted, or removed
      // outright — if the bucket can no longer meet the 2-expense
      // minimum, it doesn't get to exist anymore, locally OR in the cloud.
      if (resolved.length < 2) {
        bucketsToRemove.add(bucket);
        continue;
      }

      if (contentChanged && bucket.localId != null) {
        await _persistLocal(bucket);
        _schedulePush(bucket.localId!);
      }
    }

    for (final bucket in bucketsToRemove) {
      _buckets.remove(bucket);
      anyVisibleChange = true;
      if (bucket.localId != null) {
        await _softDeleteLocal(bucket.localId!);
        _scheduleDelete(bucket.localId!);
      }
    }

    if (anyVisibleChange) notifyListeners();
  }

  bool _sameContent(List<LocalTransaction> a, List<LocalTransaction> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].receiverName != b[i].receiverName ||
          a[i].amount != b[i].amount) {
        return false;
      }
    }
    return true;
  }

  // ==========================================
  // 4. MUTATIONS — unchanged signatures, now local-persist + queued push
  // ==========================================

  Future<void> addBucket(Bucket bucket) async {
    _buckets.add(bucket);
    notifyListeners();

    final isar = LocalDatabaseService.isar;
    final row = LocalBucket()
      ..userId = _supabase.auth.currentUser?.id
      ..name = bucket.name
      ..transactionLocalIds = bucket.transactionIds.toList()
      ..isDeleted = false
      ..isSynced = false
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async => await isar.localBuckets.put(row));
    bucket.localId = row.id;

    _schedulePush(row.id);
  }

  /// Commits a name change immediately — used by the inline Edit/Save
  /// control next to the bucket name, independent of the page-level
  /// Save/Cancel which only governs the expense list.
  Future<void> renameBucket(String id, String newName) async {
    final bucket = _buckets.firstWhere((b) => b.id == id);
    bucket.name = newName;
    notifyListeners();

    await _persistLocal(bucket);
    if (bucket.localId != null) _schedulePush(bucket.localId!);
  }

  Future<void> updateTransactions(
    String id,
    List<LocalTransaction> transactions,
  ) async {
    final bucket = _buckets.firstWhere((b) => b.id == id);
    bucket.transactions = transactions;
    notifyListeners();

    await _persistLocal(bucket);
    if (bucket.localId != null) _schedulePush(bucket.localId!);
  }

  Future<void> removeBucket(String id) async {
    final matches = _buckets.where((b) => b.id == id);
    final bucket = matches.isNotEmpty ? matches.first : null;
    _buckets.removeWhere((b) => b.id == id);
    notifyListeners();

    if (bucket?.localId != null) {
      final localId = bucket!.localId!;
      await _softDeleteLocal(localId);
      _scheduleDelete(localId);
    }
  }

  void deleteBucket(String id) => removeBucket(id);

  List<Bucket> bucketsForMonth(DateTime month) {
    return _buckets
        .where(
          (b) =>
              b.transactions.isNotEmpty &&
              b.dominantMonth.year == month.year &&
              b.dominantMonth.month == month.month,
        )
        .toList();
  }

  // ==========================================
  // 5. LOCAL PERSISTENCE HELPERS
  // ==========================================

  Future<void> _persistLocal(Bucket bucket) async {
    final isar = LocalDatabaseService.isar;
    LocalBucket? row = bucket.localId != null
        ? await isar.localBuckets.get(bucket.localId!)
        : null;

    row ??= LocalBucket()
      ..userId = _supabase.auth.currentUser?.id
      ..cloudId = bucket.cloudId;

    row
      ..name = bucket.name
      ..transactionLocalIds = bucket.transactionIds.toList()
      ..isDeleted = false
      ..isSynced = false
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async => await isar.localBuckets.put(row!));
    bucket.localId = row.id;
  }

  Future<void> _softDeleteLocal(int localId) async {
    final isar = LocalDatabaseService.isar;
    final row = await isar.localBuckets.get(localId);
    if (row == null) return;
    row
      ..isDeleted = true
      ..isSynced = false
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async => await isar.localBuckets.put(row));
  }

  // ==========================================
  // 6. DEBOUNCED + SERIALIZED PUSH QUEUE
  //
  //    Two problems this solves at once:
  //    - Rapid edits to the same bucket (rename, then add an expense,
  //      then rename again) previously fired a separate network call
  //      each time, with no ordering guarantee between them. Now they
  //      collapse into ONE call carrying the final state, sent ~500ms
  //      after things go quiet.
  //    - That one call is chained onto `_pushChains[localId]`, so it can
  //      never run concurrently with another push for the SAME row —
  //      including the startup `_syncOfflineBuckets()` sweep. This is
  //      what was causing duplicate/orphaned rows in Supabase before.
  // ==========================================

  void _schedulePush(int localId) {
    _debounceTimers[localId]?.cancel();
    _debounceTimers[localId] = Timer(const Duration(milliseconds: 500), () {
      _debounceTimers.remove(localId);
      _enqueue(localId, () => _pushRowById(localId));
    });
  }

  void _scheduleDelete(int localId) {
    // A delete supersedes any pending edit for the same row — no point
    // pushing an update to something about to be removed.
    _debounceTimers[localId]?.cancel();
    _debounceTimers.remove(localId);
    _enqueue(localId, () => _deleteRowById(localId));
  }

  Future<void> _enqueue(int localId, Future<void> Function() task) {
    final previous = _pushChains[localId] ?? Future.value();
    final next = previous.then((_) => task());
    _pushChains[localId] = next;
    return next;
  }

  // ==========================================
  // 7. CLOUD SYNC (SUPABASE)
  // ==========================================

  Future<void> _syncOfflineBuckets() async {
    final isar = LocalDatabaseService.isar;

    final pendingUpdates = await isar.localBuckets
        .filter()
        .isSyncedEqualTo(false)
        .isDeletedEqualTo(false)
        .findAll();
    final pendingDeletes = await isar.localBuckets
        .filter()
        .isSyncedEqualTo(false)
        .isDeletedEqualTo(true)
        .findAll();

    await Future.wait([
      ...pendingUpdates.map(
        (row) => _enqueue(row.id, () => _pushRowById(row.id)),
      ),
      ...pendingDeletes.map(
        (row) => _enqueue(row.id, () => _deleteRowById(row.id)),
      ),
    ]);
  }

  Future<void> _pullFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _supabase.functions
          .invoke('decrypt-bucket', body: {})
          .timeout(const Duration(seconds: 20));

      if (response.status != 200) {
        debugPrint("Bucket pull failed: status ${response.status}");
        return;
      }

      final rows = response.data as List;
      final isar = LocalDatabaseService.isar;

      // Map transaction cloudIds -> local Isar ids, so a bucket pulled
      // from Supabase can be resolved against on-device data.
      final localIdByCloudId = <String, int>{
        for (final tx in TransactionService().allTransactions)
          if (tx.cloudId != null) tx.cloudId!: tx.id,
      };

      for (final r in rows) {
        final cloudId = r['id'].toString();
        final remoteUpdatedAt =
            DateTime.tryParse(r['updated_at'] ?? '') ?? DateTime.now();

        final remoteTxCloudIds = (r['transaction_ids'] as List).map(
          (e) => e.toString(),
        );
        final localIds = remoteTxCloudIds
            .map((cid) => localIdByCloudId[cid])
            .whereType<int>()
            .toList();

        // Not enough of this bucket's expenses exist on this device yet
        // (e.g. fresh install still finishing its transaction pull) —
        // skip for now; it'll be picked up on a later pull once those
        // transactions have synced down too.
        if (localIds.length < 2) continue;

        final existing = await isar.localBuckets
            .filter()
            .cloudIdEqualTo(cloudId)
            .findFirst();

        if (existing == null) {
          final pulled = LocalBucket()
            ..cloudId = cloudId
            ..userId = user.id
            ..name = r['name'] as String
            ..transactionLocalIds = localIds
            ..isDeleted = false
            ..isSynced = true
            ..updatedAt = remoteUpdatedAt;
          await isar.writeTxn(() async => await isar.localBuckets.put(pulled));
        } else if (existing.isSynced &&
            remoteUpdatedAt.isAfter(existing.updatedAt)) {
          // Edited on another device since this device last saw it, and
          // this device has no unsynced local edit of its own pending —
          // safe to take the remote version (last-write-wins). If this
          // device DOES have a pending local edit (isSynced == false),
          // leave it alone; that edit will overwrite the remote version
          // on its own next push instead.
          existing
            ..name = r['name'] as String
            ..transactionLocalIds = localIds
            ..updatedAt = remoteUpdatedAt;
          await isar.writeTxn(
            () async => await isar.localBuckets.put(existing),
          );
        }
      }
    } catch (e) {
      debugPrint("Bucket pull failed: $e");
    }
  }

  Future<void> _pushRowById(int localId) => _networkGate.run(() async {
    final isar = LocalDatabaseService.isar;
    // Re-fetch fresh right before sending — if several edits queued
    // up, this always sends the LATEST state, not whatever was
    // current when the push was first scheduled.
    final row = await isar.localBuckets.get(localId);
    if (row == null || row.isDeleted) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Only expenses that have themselves synced (have a cloudId)
      // can be referenced in the cloud row. Anything still
      // local-only is left out of this push — the next time
      // TransactionService syncs that expense, _syncWithTransactions
      // above marks this bucket unsynced again, so it gets picked up
      // automatically.
      final txByLocalId = <int, LocalTransaction>{
        for (final tx in TransactionService().allTransactions) tx.id: tx,
      };
      final cloudTxIds = row.transactionLocalIds
          .map((id) => txByLocalId[id]?.cloudId)
          .whereType<String>()
          .toList();

      if (cloudTxIds.length < 2) {
        // Not enough synced expenses yet to satisfy the server-side
        // minimum — leave isSynced=false so this retries automatically
        // once more of this bucket's expenses have their own cloudId.
        return;
      }

      final payload = {
        'action': row.cloudId == null ? 'insert' : 'update',
        'cloud_id': row.cloudId,
        'name': row.name,
        'transaction_ids': cloudTxIds,
      };

      final response = await _supabase.functions
          .invoke('encrypt-bucket', body: payload)
          .timeout(const Duration(seconds: 10));

      if (response.status != 200) {
        throw Exception('Bucket sync failed: status ${response.status}');
      }

      final data = response.data as Map;
      final freshRow = await isar.localBuckets.get(localId);
      if (freshRow == null) return;

      freshRow.isSynced = true;
      if (freshRow.cloudId == null) freshRow.cloudId = data['id'] as String?;
      await isar.writeTxn(() async => await isar.localBuckets.put(freshRow));

      final match = _buckets.where((b) => b.localId == localId);
      if (match.isNotEmpty) match.first.cloudId = freshRow.cloudId;
    } catch (e) {
      debugPrint("Bucket push failed for local id $localId: $e");
      // Left isSynced=false — the next initService()'s offline sweep,
      // or the next edit to this bucket, will retry.
    }
  });

  Future<void> _deleteRowById(int localId) => _networkGate.run(() async {
    final isar = LocalDatabaseService.isar;
    final row = await isar.localBuckets.get(localId);
    if (row == null) return;

    try {
      if (row.cloudId != null) {
        final response = await _supabase.functions
            .invoke(
              'encrypt-bucket',
              body: {'action': 'delete', 'cloud_id': row.cloudId},
            )
            .timeout(const Duration(seconds: 10));

        if (response.status != 200) {
          throw Exception('Bucket delete failed: status ${response.status}');
        }
      }
      // No cloudId means it never made it to Supabase in the first
      // place — nothing remote to clean up, just remove it locally.
      await isar.writeTxn(() async => await isar.localBuckets.delete(localId));
    } catch (e) {
      debugPrint("Bucket delete sync failed for local id $localId: $e");
      // Row stays with isDeleted=true, isSynced=false — retried by
      // the next offline sweep.
    }
  });
}
