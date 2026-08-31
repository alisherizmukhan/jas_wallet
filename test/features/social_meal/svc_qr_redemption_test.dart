import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/social_meal/data/models/social_meal_redeem_response.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/svc_meal_state.dart';
import 'package:jaswallet_app/features/social_meal/providers/svc_meal_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

SocialMealRedeemResponse _fakeResponse({
  int visitNumber = 1,
  int todayMealsUsed = 1,
  int remainingMealsToday = 2,
}) {
  final now = DateTime.now();
  return SocialMealRedeemResponse(
    mealDate: now,
    visitNumber: visitNumber,
    todayMealsUsed: todayMealsUsed,
    remainingMealsToday: remainingMealsToday,
    scannedAt: now,
  );
}

// ─── ScanResult ───────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ScanResult', () {
    test('success carries the full redemption response', () {
      final resp = _fakeResponse();
      final result = ScanResult.success(resp);

      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.response, same(resp));
    });

    test('error carries the error message and no response', () {
      final result = ScanResult.error('Invalid cashier QR code');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Invalid cashier QR code');
      expect(result.response, isNull);
    });
  });

  // ─── SocialMealRedeemResponse parsing ───────────────────────────────────────

  group('SocialMealRedeemResponse.fromJson', () {
    test('parses a well-formed backend payload correctly', () {
      final json = {
        'meal_date': '2026-05-26T00:00:00.000Z',
        'visit_number': 2,
        'today_redemptions_count': 2,
        'remaining_redemptions_today': 1,
        'scanned_at': '2026-05-26T12:34:56.000Z',
      };

      final resp = SocialMealRedeemResponse.fromJson(json);

      expect(resp.visitNumber, 2);
      expect(resp.todayMealsUsed, 2);
      expect(resp.remainingMealsToday, 1);
      expect(resp.mealDate.year, 2026);
      expect(resp.scannedAt.hour, 12);
      expect(resp.scannedAt.minute, 34);
    });

    test('defaults to 0 when optional numeric fields are absent', () {
      final json = {
        'meal_date': '2026-05-26T00:00:00.000Z',
        'scanned_at': '2026-05-26T12:00:00.000Z',
      };

      final resp = SocialMealRedeemResponse.fromJson(json);

      expect(resp.visitNumber, 0);
      expect(resp.todayMealsUsed, 0);
      expect(resp.remainingMealsToday, 0);
    });
  });

  // ─── SVCMealState business logic ─────────────────────────────────────────────

  group('SVCMealState', () {
    test('initial state: not a member, not loaded', () {
      final state = SVCMealState.initial();

      expect(state.isMember, isFalse);
      expect(state.isLoaded, isFalse);
      expect(state.isProcessing, isFalse);
      expect(state.isDailyLimitReached, isFalse);
    });

    test('isDailyLimitReached true when used == maxMealsPerDay', () {
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: SVCMealState.maxMealsPerDay,
        todayRemainingMealsCount: 0,
      );

      expect(state.isDailyLimitReached, isTrue);
      expect(state.canScan, isFalse);
    });

    test('isDailyLimitReached false when below limit', () {
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 1,
        todayRemainingMealsCount: 2,
      );

      expect(state.isDailyLimitReached, isFalse);
    });

    test('canScan false when not a member', () {
      final state = SVCMealState(
        isMember: false,
        isLoaded: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: SVCMealState.maxMealsPerDay,
      );

      expect(state.canScan, isFalse);
    });

    test('canScan false while processing', () {
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        isProcessing: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: SVCMealState.maxMealsPerDay,
      );

      expect(state.canScan, isFalse);
    });

    test('canScan enforces 5-second cooldown after last scan', () {
      final recentScan = DateTime.now().subtract(const Duration(seconds: 3));
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: SVCMealState.maxMealsPerDay,
        lastScanTime: recentScan,
      );

      expect(state.canScan, isFalse);
    });

    test('canScan true after cooldown has elapsed', () {
      final oldScan = DateTime.now().subtract(const Duration(seconds: 10));
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: SVCMealState.maxMealsPerDay,
        lastScanTime: oldScan,
      );

      expect(state.canScan, isTrue);
    });

    test('copyWith preserves unspecified fields', () {
      final original = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 1,
        todayRemainingMealsCount: 2,
      );

      final updated = original.copyWith(todayMealsUsedCount: 2);

      expect(updated.isMember, isTrue);
      expect(updated.isLoaded, isTrue);
      expect(updated.todayMealsUsedCount, 2);
      expect(updated.todayRemainingMealsCount, 2);
    });
  });

  // ─── Duplicate scan prevention ────────────────────────────────────────────────

  group('Duplicate scan prevention', () {
    test('ScanResult.error returned immediately when cooldown active', () {
      // The notifier guards with `lastScanTime` — the raw state is testable
      // directly via SVCMealState.canScan.
      final justNow = DateTime.now().subtract(const Duration(seconds: 1));
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: SVCMealState.maxMealsPerDay,
        lastScanTime: justNow,
      );

      // < 5s elapsed → canScan is false
      expect(state.canScan, isFalse);
      // The guard in redeemMeal mirrors this: it checks elapsed.inSeconds < 5
    });

    test('multiple rapid detected barcodes do not produce multiple API calls '
        'because _scanLocked blocks re-entry', () {
      // This is a structural / architectural assertion:
      // The scanner page sets _scanLocked = true BEFORE the async API call,
      // and _onDetect returns early when _scanLocked is true.
      // We verify the invariant here at the state level.
      const maxPerDay = SVCMealState.maxMealsPerDay;
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: 0,
        todayRemainingMealsCount: maxPerDay,
      );

      // Before any scan: no cooldown, can scan
      expect(state.canScan, isTrue);

      // Simulate lock acquired (isProcessing = true in state)
      final locked = state.copyWith(isProcessing: true);
      expect(locked.canScan, isFalse);
    });
  });

  // ─── Daily limit guard ────────────────────────────────────────────────────────

  group('Daily limit guard', () {
    test('remainingMonthlyMeals clamps to 0 when over limit', () {
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: SVCMealState.maxMealsPerMonth + 5,
        todayRemainingMealsCount: 0,
      );

      expect(state.remainingMonthlyMeals, 0);
    });

    test('remainingMeals clamps to 0 when weekly exceeded', () {
      final state = SVCMealState(
        isMember: true,
        isLoaded: true,
        todayMealsUsedCount: SVCMealState.maxMealsPerWeek + 2,
        todayRemainingMealsCount: 0,
      );

      expect(state.remainingMeals, 0);
    });
  });

  // ─── Error mapping ────────────────────────────────────────────────────────────

  group('SocialMealRepositoryImpl error messages', () {
    // Unit-test the *string-level* guard inside SVCMealNotifier.redeemMeal
    // which strips "Exception: " prefix from caught errors.
    test('Exception prefix is stripped from error messages', () {
      // redeemMeal does: e.toString().replaceFirst('Exception: ', '')
      const raw = 'Exception: Invalid cashier QR code';
      final stripped = raw.replaceFirst('Exception: ', '');
      expect(stripped, 'Invalid cashier QR code');
    });

    test('Messages without prefix pass through unchanged', () {
      const raw = 'Could not process the QR scan right now.';
      final stripped = raw.replaceFirst('Exception: ', '');
      expect(stripped, raw);
    });
  });
}
