import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jaswallet_app/features/social_meal/data/repositories/meal_local_repository_impl.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_badge.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_entry.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_schedule.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_slot.dart';
import 'package:jaswallet_app/features/social_meal/domain/entities/meal_streak.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

MealEntry _entry({
  required MealSlot slot,
  required MealStatus status,
  DateTime? date,
}) {
  final d = _dateOnly(date ?? DateTime.now());
  return MealEntry(
    id: MealEntry.makeId(d, slot),
    date: d,
    slot: slot,
    status: status,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── MealEntry ──────────────────────────────────────────────────────────────

  group('MealEntry', () {
    test('makeId generates correct format', () {
      final date = DateTime(2026, 5, 16);
      expect(
        MealEntry.makeId(date, MealSlot.lunch),
        '2026-05-16_lunch',
      );
    });

    test('canCancel returns true when scheduled and before deadline', () {
      // Create entry for tomorrow — deadline is 24h before meal, so today's
      // schedule should still be cancellable for a far-future date.
      final tomorrow = DateTime.now().add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.scheduled, date: tomorrow);
      expect(entry.canCancel, isTrue);
    });

    test('canCancel returns false when already cancelled', () {
      final tomorrow = DateTime.now().add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: tomorrow);
      expect(entry.canCancel, isFalse);
    });

    test('canCancel returns false when already received', () {
      final tomorrow = DateTime.now().add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.received, date: tomorrow);
      expect(entry.canCancel, isFalse);
    });

    test('cancellationDeadline is 24h before meal start', () {
      final date = DateTime(2026, 5, 20);
      final entry = _entry(slot: MealSlot.lunch, status: MealStatus.scheduled, date: date);
      // Lunch starts at 12:00; deadline should be 2026-05-19 12:00
      final expected = DateTime(2026, 5, 19, 12, 0);
      expect(entry.cancellationDeadline, expected);
    });

    test('cancellationDeadline for breakfast is 24h before 08:00', () {
      final date = DateTime(2026, 5, 20);
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.scheduled, date: date);
      final expected = DateTime(2026, 5, 19, 8, 0);
      expect(entry.cancellationDeadline, expected);
    });

    test('isDeadlinePassed is true for yesterday entry', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.scheduled, date: yesterday);
      expect(entry.isDeadlinePassed, isTrue);
    });

    test('isPast is true when meal window ended', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final entry = _entry(slot: MealSlot.dinner, status: MealStatus.scheduled, date: yesterday);
      expect(entry.isPast, isTrue);
    });

    test('canUndoCancel is true for cancelled meal within deadline', () {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: future);
      expect(entry.canUndoCancel, isTrue);
    });

    test('canUndoCancel is false for scheduled meal', () {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.scheduled, date: future);
      expect(entry.canUndoCancel, isFalse);
    });

    test('canUndoCancel is false for received meal', () {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.received, date: future);
      expect(entry.canUndoCancel, isFalse);
    });

    test('canUndoCancel is false for cancelled meal past deadline', () {
      final yesterday = _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      final entry = _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: yesterday);
      expect(entry.canUndoCancel, isFalse);
    });

    test('copyWith preserves fields and overrides status', () {
      final date = DateTime(2026, 5, 20);
      final original = MealEntry(
        id: 'id',
        date: date,
        slot: MealSlot.lunch,
        status: MealStatus.scheduled,
      );
      final copied = original.copyWith(
        status: MealStatus.cancelled,
        cancelledAt: DateTime(2026, 5, 18),
      );
      expect(copied.id, 'id');
      expect(copied.slot, MealSlot.lunch);
      expect(copied.status, MealStatus.cancelled);
      expect(copied.cancelledAt, DateTime(2026, 5, 18));
    });
  });

  // ── MealSchedule ──────────────────────────────────────────────────────────

  group('MealSchedule', () {
    test('receivedCount sums correct entries', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.received, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.noShow, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.received, date: date),
        ],
      );
      expect(schedule.receivedCount, 2);
    });

    test('cancelledCount sums correct entries', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.received, date: date),
        ],
      );
      expect(schedule.cancelledCount, 2);
    });

    test('allCancelled true when all 3 cancelled', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.cancelled, date: date),
        ],
      );
      expect(schedule.allCancelled, isTrue);
    });

    test('allCancelled false when only 2 cancelled', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.cancelled, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.received, date: date),
        ],
      );
      expect(schedule.allCancelled, isFalse);
    });

    test('hasNoShow true when any noShow', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.noShow, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.received, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.cancelled, date: date),
        ],
      );
      expect(schedule.hasNoShow, isTrue);
    });

    test('copyWithEntry replaces the matching slot entry', () {
      final date = DateTime(2026, 5, 10);
      final original = MealSchedule(
        date: date,
        meals: [
          _entry(slot: MealSlot.breakfast, status: MealStatus.scheduled, date: date),
          _entry(slot: MealSlot.lunch, status: MealStatus.scheduled, date: date),
          _entry(slot: MealSlot.dinner, status: MealStatus.scheduled, date: date),
        ],
      );
      final updated = original.copyWithEntry(
        _entry(slot: MealSlot.lunch, status: MealStatus.cancelled, date: date),
      );
      expect(updated.lunch.status, MealStatus.cancelled);
      expect(updated.breakfast.status, MealStatus.scheduled);
      expect(updated.dinner.status, MealStatus.scheduled);
    });
  });

  // ── MealStreak ────────────────────────────────────────────────────────────

  group('MealStreak', () {
    test('nextMilestone returns correct first milestone', () {
      const streak = MealStreak(
        currentStreak: 0,
        bestStreak: 0,
        totalReceived: 0,
        totalCancelled: 0,
        totalNoShows: 0,
      );
      expect(streak.nextMilestone, 3);
    });

    test('nextMilestone advances past reached milestones', () {
      const streak = MealStreak(
        currentStreak: 5,
        bestStreak: 5,
        totalReceived: 10,
        totalCancelled: 0,
        totalNoShows: 0,
      );
      expect(streak.nextMilestone, 7);
    });

    test('nextMilestone returns null when all milestones passed', () {
      const streak = MealStreak(
        currentStreak: 200,
        bestStreak: 200,
        totalReceived: 500,
        totalCancelled: 0,
        totalNoShows: 0,
      );
      expect(streak.nextMilestone, isNull);
    });

    test('daysToNextMilestone calculates remaining days', () {
      const streak = MealStreak(
        currentStreak: 5,
        bestStreak: 5,
        totalReceived: 5,
        totalCancelled: 0,
        totalNoShows: 0,
      );
      // nextMilestone is 7; 7 - 5 = 2
      expect(streak.daysToNextMilestone, 2);
    });

    test('xpForMilestone returns correct XP values', () {
      expect(MealStreak.xpForMilestone(3), 20);
      expect(MealStreak.xpForMilestone(7), 50);
      expect(MealStreak.xpForMilestone(14), 100);
      expect(MealStreak.xpForMilestone(21), 150);
      expect(MealStreak.xpForMilestone(30), 200);
      expect(MealStreak.xpForMilestone(60), 400);
      expect(MealStreak.xpForMilestone(100), 800);
      expect(MealStreak.xpForMilestone(99), 0); // Non-milestone → 0
    });

    test('milestones list includes 21', () {
      expect(MealStreak.milestones, containsAll([3, 7, 14, 21, 30, 60, 100]));
    });

    test('copyWith updates bestStreak to max(old, new)', () {
      const base = MealStreak(
        currentStreak: 5,
        bestStreak: 10,
        totalReceived: 5,
        totalCancelled: 0,
        totalNoShows: 0,
      );
      // New currentStreak=12 should push bestStreak to 12
      final updated = base.copyWith(currentStreak: 12, bestStreak: 12);
      expect(updated.bestStreak, 12);
    });

    test('MealStreak.zero has all zeros', () {
      expect(MealStreak.zero.currentStreak, 0);
      expect(MealStreak.zero.bestStreak, 0);
      expect(MealStreak.zero.totalReceived, 0);
    });
  });

  // ── MealBadge ─────────────────────────────────────────────────────────────

  group('MealBadge', () {
    test('catalogue has 4 badges in ascending order', () {
      final streaks = MealBadge.catalogue.map((b) => b.requiredStreak).toList();
      expect(streaks, [3, 7, 14, 30]);
    });

    test('evaluateAll unlocks correct badges for streak=7', () {
      final badges = MealBadge.evaluateAll(7);
      expect(badges.where((b) => b.isUnlocked).length, 2); // 3-day + 7-day
      expect(badges.first.isUnlocked, isTrue); // consistent (3)
      expect(badges[1].isUnlocked, isTrue); // week streak (7)
      expect(badges[2].isUnlocked, isFalse); // discipline (14)
      expect(badges[3].isUnlocked, isFalse); // legendary (30)
    });

    test('evaluateAll unlocks all for streak=30', () {
      final badges = MealBadge.evaluateAll(30);
      expect(badges.every((b) => b.isUnlocked), isTrue);
    });

    test('evaluateAll unlocks none for streak=0', () {
      final badges = MealBadge.evaluateAll(0);
      expect(badges.every((b) => !b.isUnlocked), isTrue);
    });

    test('highestUnlocked returns legendary at streak=50', () {
      final badge = MealBadge.highestUnlocked(50);
      expect(badge?.id, 'legendary');
      expect(badge?.emoji, '👑');
    });

    test('highestUnlocked returns null at streak=0', () {
      expect(MealBadge.highestUnlocked(0), isNull);
    });

    test('highestUnlocked returns consistent at streak=3', () {
      final badge = MealBadge.highestUnlocked(3);
      expect(badge?.id, 'consistent');
    });

    test('nameFor returns correct language variant', () {
      final badge = MealBadge.catalogue.first;
      expect(badge.nameFor('en'), 'Consistent Student');
      expect(badge.nameFor('ru'), 'Стабильный студент');
      expect(badge.nameFor('kk'), 'Тұрақты студент');
      expect(badge.nameFor(null), 'Consistent Student'); // Default to en
    });
  });

  // ── MealSlot ──────────────────────────────────────────────────────────────

  group('MealSlot', () {
    test('time ranges are correct', () {
      expect(MealSlot.breakfast.timeRange, '08:00 – 12:00');
      expect(MealSlot.lunch.timeRange, '12:00 – 17:00');
      expect(MealSlot.dinner.timeRange, '17:00 – 00:00');
    });

    test('fromKey round-trips correctly', () {
      for (final slot in MealSlot.values) {
        expect(MealSlot.fromKey(slot.key), slot);
      }
    });

    test('currentSlot returns null before breakfast', () {
      // 07:00 — before any slot
      expect(MealSlot.currentSlot(DateTime(2026, 5, 16, 7, 0)), isNull);
    });

    test('currentSlot returns breakfast during breakfast window', () {
      // 10:00 — within 09:00–11:30
      expect(
        MealSlot.currentSlot(DateTime(2026, 5, 16, 10, 0)),
        MealSlot.breakfast,
      );
    });

    test('currentSlot returns lunch during lunch window', () {
      // 13:00 — within 11:30–17:30
      expect(
        MealSlot.currentSlot(DateTime(2026, 5, 16, 13, 0)),
        MealSlot.lunch,
      );
    });

    test('currentSlot returns dinner during dinner window', () {
      // 20:00 — within 17:30–23:00
      expect(
        MealSlot.currentSlot(DateTime(2026, 5, 16, 20, 0)),
        MealSlot.dinner,
      );
    });
  });

  // ── MealStatus ────────────────────────────────────────────────────────────

  group('MealStatus', () {
    test('fromKey round-trips all values', () {
      for (final status in MealStatus.values) {
        expect(MealStatus.fromKey(status.key), status);
      }
    });

    test('fromKey returns scheduled as default for unknown key', () {
      expect(MealStatus.fromKey('unknown_key'), MealStatus.scheduled);
    });
  });

  // ── Deadline logic (24h rule) ─────────────────────────────────────────────

  group('Deadline logic', () {
    test('meal 3 days away is cancellable', () {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      final entry = _entry(
          slot: MealSlot.breakfast, status: MealStatus.scheduled, date: future);
      expect(entry.canCancel, isTrue);
    });

    test('meal at least 2 days away is always within cancellation window', () {
      // Use a date 3 days in the future — the cancellation deadline (24h before
      // breakfast start) will be 2 days from now at 09:00, which is safely in
      // the future regardless of the current time-of-day.
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      final entry = _entry(
          slot: MealSlot.breakfast, status: MealStatus.scheduled, date: future);
      // Deadline = 2 days from now at 09:00 — always after now
      expect(entry.cancellationDeadline.isAfter(DateTime.now()), isTrue);
      expect(entry.canCancel, isTrue);
    });

    test('yesterday breakfast deadline has passed', () {
      final yesterday = _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      final entry = _entry(
          slot: MealSlot.breakfast, status: MealStatus.scheduled, date: yesterday);
      // Deadline was 2 days ago at 09:00 — definitely passed
      expect(entry.isDeadlinePassed, isTrue);
      expect(entry.canCancel, isFalse);
    });
  });

  // ── Repository — no-show derivation ──────────────────────────────────────

  group('MealLocalRepositoryImpl', () {
    late MealLocalRepositoryImpl repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = MealLocalRepositoryImpl();
    });

    test('getScheduleForDate returns 3 meals for today', () async {
      final schedule = await repo.getScheduleForDate(DateTime.now());
      expect(schedule.meals.length, 3);
      expect(schedule.breakfast.slot, MealSlot.breakfast);
      expect(schedule.lunch.slot, MealSlot.lunch);
      expect(schedule.dinner.slot, MealSlot.dinner);
    });

    test('past meal without action returns noShow', () async {
      // Yesterday — all meals should be no-shows (no stored data)
      final yesterday =
          _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      final schedule = await repo.getScheduleForDate(yesterday);
      expect(schedule.meals.every((m) => m.status == MealStatus.noShow), isTrue);
    });

    test('future meal returns scheduled by default', () async {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 5));
      final schedule = await repo.getScheduleForDate(future);
      expect(schedule.meals.every((m) => m.status == MealStatus.scheduled),
          isTrue);
    });

    test('cancelled meal persists across calls', () async {
      // Use a future date so canCancel is true
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      await repo.cancelMeal(future, MealSlot.breakfast);

      final schedule = await repo.getScheduleForDate(future);
      expect(schedule.breakfast.status, MealStatus.cancelled);
      // Others should still be scheduled
      expect(schedule.lunch.status, MealStatus.scheduled);
    });

    test('markAsReceived persists across calls', () async {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 2));
      await repo.markAsReceived(future, MealSlot.lunch);

      final schedule = await repo.getScheduleForDate(future);
      expect(schedule.lunch.status, MealStatus.received);
      expect(schedule.breakfast.status, MealStatus.scheduled);
    });

    test('cancelMeal throws when deadline has passed', () async {
      // Yesterday — deadline definitely passed
      final yesterday =
          _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      expect(
        () => repo.cancelMeal(yesterday, MealSlot.breakfast),
        throwsA(isA<Exception>()),
      );
    });

    test('undoCancellation restores cancelled meal to scheduled', () async {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      await repo.cancelMeal(future, MealSlot.breakfast);

      // Verify it's cancelled
      final afterCancel = await repo.getScheduleForDate(future);
      expect(afterCancel.breakfast.status, MealStatus.cancelled);

      // Undo the cancellation
      await repo.undoCancellation(future, MealSlot.breakfast);

      final afterUndo = await repo.getScheduleForDate(future);
      expect(afterUndo.breakfast.status, MealStatus.scheduled);
    });

    test('undoCancellation throws when meal is not cancelled', () async {
      final future = _dateOnly(DateTime.now()).add(const Duration(days: 3));
      expect(
        () => repo.undoCancellation(future, MealSlot.lunch),
        throwsA(isA<Exception>()),
      );
    });

    test('undoCancellation throws when undo deadline has passed', () async {
      // Past date — can no longer undo
      final yesterday =
          _dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      expect(
        () => repo.undoCancellation(yesterday, MealSlot.breakfast),
        throwsA(isA<Exception>()),
      );
    });

    test('milestone tracking round-trips correctly', () async {
      const userId = 'user_milestone_test';

      // Not yet awarded
      final before = await repo.isMilestoneAwarded(userId, 7);
      expect(before, isFalse);

      // Mark as awarded
      await repo.markMilestoneAwarded(userId, 7);

      // Now awarded
      final after = await repo.isMilestoneAwarded(userId, 7);
      expect(after, isTrue);
    });

    test('milestone tracking is per-user', () async {
      await repo.markMilestoneAwarded('user_a', 3);

      expect(await repo.isMilestoneAwarded('user_a', 3), isTrue);
      expect(await repo.isMilestoneAwarded('user_b', 3), isFalse);
    });

    test('different milestone levels are tracked independently', () async {
      const userId = 'user_levels_test';

      await repo.markMilestoneAwarded(userId, 7);

      expect(await repo.isMilestoneAwarded(userId, 3), isFalse);
      expect(await repo.isMilestoneAwarded(userId, 7), isTrue);
      expect(await repo.isMilestoneAwarded(userId, 14), isFalse);
    });

    test('computeStreak returns zero for a fresh user', () async {
      final streak = await repo.computeStreak(userId: 'test_fresh');
      // No meals stored → all past meals are no-shows → streak broken immediately
      // Result: currentStreak = 0 (today has no received meals)
      expect(streak.currentStreak, 0);
    });

    test('computeStreak reflects received meal today', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final today = _dateOnly(now);
      // Store a received meal for today's current slot (whichever is active/past)
      // We'll just mark breakfast as received
      await repo.markAsReceived(today, MealSlot.breakfast);

      final streak = await repo.computeStreak(userId: 'test_today_received');
      // Today has 1 received meal → currentStreak = 1
      expect(streak.currentStreak, greaterThanOrEqualTo(1));
    });

    test('getHistory returns list of past schedules', () async {
      final history = await repo.getHistory(limit: 7);
      expect(history.length, 7);
    });

    test('getMonthSchedule returns correct number of days', () async {
      final may2026 = DateTime(2026, 5);
      final schedules = await repo.getMonthSchedule(may2026);
      expect(schedules.length, 31); // May has 31 days
    });
  });

  // ── No-show streak reset ───────────────────────────────────────────────────

  group('No-show streak reset logic', () {
    test('noShow on past day breaks streak (schedule analysis)', () {
      // A day with a no-show should set hasNoShow = true
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          MealEntry(
              id: '1',
              date: date,
              slot: MealSlot.breakfast,
              status: MealStatus.noShow),
          MealEntry(
              id: '2',
              date: date,
              slot: MealSlot.lunch,
              status: MealStatus.received),
          MealEntry(
              id: '3',
              date: date,
              slot: MealSlot.dinner,
              status: MealStatus.cancelled),
        ],
      );
      expect(schedule.hasNoShow, isTrue);
      expect(schedule.hasReceived, isTrue);
    });

    test('allCancelled day does not count as a streak day', () {
      final date = DateTime(2026, 5, 10);
      final schedule = MealSchedule(
        date: date,
        meals: [
          MealEntry(
              id: '1',
              date: date,
              slot: MealSlot.breakfast,
              status: MealStatus.cancelled),
          MealEntry(
              id: '2',
              date: date,
              slot: MealSlot.lunch,
              status: MealStatus.cancelled),
          MealEntry(
              id: '3',
              date: date,
              slot: MealSlot.dinner,
              status: MealStatus.cancelled),
        ],
      );
      // All cancelled — hasNoShow=false, hasReceived=false → streak preserved
      expect(schedule.hasNoShow, isFalse);
      expect(schedule.hasReceived, isFalse);
      expect(schedule.allCancelled, isTrue);
    });
  });
}
