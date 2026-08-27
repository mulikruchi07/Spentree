// lib/core/entitlement_service.dart
//
// Single source of truth for "is this signed-in user Pro right now" on the
// client, PLUS the display-only trial/billing fields used by the Pro
// upgrade sheet and the payment-successful/welcome screens.
//
// FAIL-CLOSED CONTRACT (unchanged from before):
//   - No signed-in user            -> isPro = false
//   - RPC/network error             -> isPro = false
//   - Row missing / null is_pro     -> isPro = false
//   - Expired pro_expires_at        -> isPro = false (enforced in SQL)
//   - Anything ambiguous            -> isPro = false
//
// TRIAL CONTRACT:
//   - hasUsedTrial is read-only from the client's point of view. The only
//     way it ever becomes true is the server-side start_free_trial() RPC,
//     which is atomic and can only ever succeed once per account — see the
//     SQL migration for the race-safety argument. Nothing in this file can
//     reset it, and no amount of client state tampering changes what the
//     server has already recorded.
//   - startTrial() calls that RPC and refreshes local state from its
//     result. On any failure (including "already used"), isPro is left
//     exactly as it was — this method never optimistically grants Pro.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum TrialStartResult { success, alreadyUsed, failed }

class EntitlementService extends ChangeNotifier {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  EntitlementService._internal();

  final _supabase = Supabase.instance.client;

  bool _isPro = false;
  bool get isPro => _isPro;

  DateTime? _proExpiresAt;
  DateTime? get proExpiresAt => _proExpiresAt;

  bool _hasUsedTrial = false;
  bool get hasUsedTrial => _hasUsedTrial;

  String? _trialPlan; // 'annual' | 'monthly' | null
  String? get trialPlan => _trialPlan;

  DateTime? _trialEndsAt;
  DateTime? get trialEndsAt => _trialEndsAt;

  DateTime? _nextBillingAt;
  DateTime? get nextBillingAt => _nextBillingAt;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _resolvedForUserId;

  /// True only if this account has never used a trial AND isn't already
  /// Pro through some other source. Drives whether the upgrade sheet offers
  /// "Start N days free trial" at all.
  bool get isTrialEligible => !_hasUsedTrial && !_isPro;

  Future<void> refresh() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _setState(
        isPro: false,
        expiresAt: null,
        hasUsedTrial: false,
        trialPlan: null,
        trialEndsAt: null,
        nextBillingAt: null,
        forUserId: null,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .rpc('get_entitlement')
          .timeout(const Duration(seconds: 10));

      final rows = response as List?;
      if (rows == null || rows.isEmpty) {
        _setState(
          isPro: false,
          expiresAt: null,
          hasUsedTrial: false,
          trialPlan: null,
          trialEndsAt: null,
          nextBillingAt: null,
          forUserId: user.id,
        );
        return;
      }

      final row = rows.first as Map<String, dynamic>;
      _setState(
        isPro: row['is_pro'] as bool? ?? false,
        expiresAt: _parseDate(row['pro_expires_at']),
        hasUsedTrial: row['has_used_trial'] as bool? ?? false,
        trialPlan: row['trial_plan'] as String?,
        trialEndsAt: _parseDate(row['trial_ends_at']),
        nextBillingAt: _parseDate(row['next_billing_at']),
        forUserId: user.id,
      );
    } catch (e) {
      debugPrint("Entitlement refresh failed, failing closed: $e");
      _setState(
        isPro: false,
        expiresAt: null,
        hasUsedTrial: false,
        trialPlan: null,
        trialEndsAt: null,
        nextBillingAt: null,
        forUserId: user.id,
      );
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  void _setState({
    required bool isPro,
    required DateTime? expiresAt,
    required bool hasUsedTrial,
    required String? trialPlan,
    required DateTime? trialEndsAt,
    required DateTime? nextBillingAt,
    required String? forUserId,
  }) {
    _isPro = isPro;
    _proExpiresAt = expiresAt;
    _hasUsedTrial = hasUsedTrial;
    _trialPlan = trialPlan;
    _trialEndsAt = trialEndsAt;
    _nextBillingAt = nextBillingAt;
    _resolvedForUserId = forUserId;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetForNewSession() async {
    _isPro = false;
    _proExpiresAt = null;
    _hasUsedTrial = false;
    _trialPlan = null;
    _trialEndsAt = null;
    _nextBillingAt = null;
    _resolvedForUserId = null;
    _isLoading = true;
    notifyListeners();

    if (_supabase.auth.currentUser != null) {
      await refresh();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isProForCurrentUser {
    final currentId = _supabase.auth.currentUser?.id;
    if (currentId == null || currentId != _resolvedForUserId) return false;
    return _isPro;
  }

  /// Claims the one-time free trial for the given plan ('annual' or
  /// 'monthly'). Talks to the server-side, race-safe start_free_trial()
  /// RPC — this is the ONLY path that can turn hasUsedTrial from false to
  /// true, and it can only ever succeed once per account.
  Future<TrialStartResult> startTrial(String plan) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return TrialStartResult.failed;

    try {
      final response = await _supabase
          .rpc('start_free_trial', params: {'plan': plan})
          .timeout(const Duration(seconds: 10));

      final rows = response as List?;
      if (rows == null || rows.isEmpty) return TrialStartResult.failed;

      final row = rows.first as Map<String, dynamic>;
      _setState(
        isPro: row['is_pro'] as bool? ?? false,
        expiresAt: _parseDate(row['trial_ends_at']),
        hasUsedTrial: true,
        trialPlan: plan,
        trialEndsAt: _parseDate(row['trial_ends_at']),
        nextBillingAt: _parseDate(row['next_billing_at']),
        forUserId: user.id,
      );
      return TrialStartResult.success;
    } on PostgrestException catch (e) {
      if (e.message.contains('trial_already_used')) {
        // Someone else beat us to it (double-tap / another device) — sync
        // local state to reality rather than leaving it stale.
        await refresh();
        return TrialStartResult.alreadyUsed;
      }
      debugPrint("startTrial failed: $e");
      return TrialStartResult.failed;
    } catch (e) {
      debugPrint("startTrial failed: $e");
      return TrialStartResult.failed;
    }
  }
}