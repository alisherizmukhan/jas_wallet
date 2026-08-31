import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/social_meal_redeem_response.dart';
import '../domain/entities/svc_meal_state.dart';
import 'social_meal_repository_provider.dart';

/// Manages the Social Meal Program (SVC) state.
///
/// Caches `isMember` in SharedPreferences so the hub can render instantly
/// without hitting the network on every cold start. The cache is refreshed
/// when it is older than [_staleDuration].
class SVCMealNotifier extends StateNotifier<SVCMealState> {
  SVCMealNotifier(this._ref) : super(SVCMealState.initial());

  final Ref _ref;

  static const _keyIsMember = 'svc_is_member';
  static const _keyLastChecked = 'svc_last_checked';
  static const _staleDuration = Duration(days: 2);

  /// Cancels the previous [loadState] call's request when a new one
  /// supersedes it (e.g. a pull-to-refresh fired while a background load
  /// is still in flight) — otherwise both requests complete independently
  /// and whichever response arrives last silently wins.
  CancelToken? _loadCancelToken;

  /// Restore cached membership flag from SharedPreferences.
  /// Called at app startup so the hub knows whether to show SVC instantly.
  Future<void> restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(_keyIsMember);
      if (cached != null) {
        state = state.copyWith(isMember: cached, isLoaded: true);
      }
    } catch (_) {
      // Best-effort cache read
    }
  }

  /// Load state from the API and persist the membership flag.
  /// If the cache is still fresh, skips the network call unless [force] is true.
  /// Returns `true` when the API call succeeded.
  Future<bool> loadState({bool force = false}) async {
    if (!force) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastChecked = prefs.getInt(_keyLastChecked) ?? 0;
        final age = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastChecked));
        if (age < _staleDuration && state.isLoaded) {
          return true; // cache is fresh, skip network call
        }
      } catch (_) {
        // On failure, proceed with the network call
      }
    }

    _loadCancelToken?.cancel('superseded by a newer loadState() call');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;

    try {
      final status = await _ref
          .read(socialMealRepositoryProvider)
          .getStatus(cancelToken: cancelToken);
      state = state.copyWith(
        isMember: status.isMember,
        todayMealsUsedCount: status.todayMealsUsed,
        todayRemainingMealsCount: status.remainingMealsToday,
        isLoaded: true,
        isProcessing: false,
      );
      _persistCache(status.isMember);
      return true;
    } catch (e) {
      if (cancelToken.isCancelled) return false;
      state = state.copyWith(
        isLoaded: true,
        isProcessing: false,
      );
      return false;
    }
  }

  @override
  void dispose() {
    _loadCancelToken?.cancel('SVCMealNotifier disposed');
    super.dispose();
  }

  Future<void> _persistCache(bool isMember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsMember, isMember);
      await prefs.setInt(
          _keyLastChecked, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Best-effort cache write
    }
  }

  /// Attempt to redeem a meal via QR code.
  ///
  /// Returns a [ScanResult] indicating success/failure with full response data.
  Future<ScanResult> redeemMeal(String qrCode) async {
    if (state.lastScanTime != null) {
      final elapsed = DateTime.now().difference(state.lastScanTime!);
      if (elapsed.inSeconds < 5) {
        return ScanResult.error('Please wait before scanning again');
      }
    }

    if (!state.isMember) {
      return ScanResult.error('You are not a social meal program member');
    }

    if (state.isDailyLimitReached) {
      return ScanResult.error(
        'Daily meal limit reached '
        '(${SVCMealState.maxMealsPerDay}/${SVCMealState.maxMealsPerDay})',
      );
    }

    state = state.copyWith(isProcessing: true);

    try {
      final response =
          await _ref.read(socialMealRepositoryProvider).redeemMeal(qrCode);

      state = state.copyWith(
        todayMealsUsedCount: response.todayMealsUsed,
        todayRemainingMealsCount: response.remainingSlotsToday,
        isProcessing: false,
        lastScanTime: DateTime.now(),
      );

      return ScanResult.success(response);
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      return ScanResult.error(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCAN RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a QR code meal redemption attempt.
class ScanResult {
  final bool isSuccess;
  final String? errorMessage;

  /// The full backend response when the redemption succeeded.
  final SocialMealRedeemResponse? response;

  const ScanResult._({
    required this.isSuccess,
    this.errorMessage,
    this.response,
  });

  factory ScanResult.success(SocialMealRedeemResponse response) =>
      ScanResult._(isSuccess: true, response: response);

  factory ScanResult.error(String message) =>
      ScanResult._(isSuccess: false, errorMessage: message);
}

// ─────────────────────────────────────────────────────────────────────────────
// RIVERPOD PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// Global SVC meal program state provider.
final svcMealProvider =
    StateNotifierProvider<SVCMealNotifier, SVCMealState>((ref) {
  return SVCMealNotifier(ref);
});
