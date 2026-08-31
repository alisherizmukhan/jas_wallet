import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/routing/app_router.dart';
import 'package:jaswallet_app/features/settings/presentation/providers/profile_completion_provider.dart';

void main() {
  // ── ProfileCompletionState computed properties ────────────────────────────

  group('ProfileCompletionState.completedCount', () {
    test('returns 0 when no sections are filled', () {
      const state = ProfileCompletionState(
        sectionsFilled: {},
        isLoading: false,
      );
      expect(state.completedCount, 0);
    });

    test('counts only true values', () {
      const state = ProfileCompletionState(
        sectionsFilled: {
          ProfileSection.aboutMe: true,
          ProfileSection.experience: false,
          ProfileSection.skills: true,
        },
        isLoading: false,
      );
      expect(state.completedCount, 2);
    });

    test('counts all 10 sections when fully complete', () {
      final all = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: true,
      };
      final state = ProfileCompletionState(
        sectionsFilled: all,
        isLoading: false,
      );
      expect(state.completedCount, ProfileSection.values.length);
    });
  });

  group('ProfileCompletionState.totalCount', () {
    test('equals the number of ProfileSection enum values', () {
      const state = ProfileCompletionState();
      expect(state.totalCount, ProfileSection.values.length);
      expect(state.totalCount, 10);
    });
  });

  group('ProfileCompletionState.percentage', () {
    test('returns 0 when no sections are filled', () {
      const state = ProfileCompletionState(
        sectionsFilled: {},
        isLoading: false,
      );
      expect(state.percentage, 0);
    });

    test('returns 100 when all sections are filled', () {
      final all = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: true,
      };
      final state = ProfileCompletionState(
        sectionsFilled: all,
        isLoading: false,
      );
      expect(state.percentage, 100);
    });

    test('rounds to nearest integer', () {
      // 1 out of 10 = 10% (1/10*100 = 10.0 → rounds to 10)
      const state = ProfileCompletionState(
        sectionsFilled: {ProfileSection.aboutMe: true},
        isLoading: false,
      );
      expect(state.percentage, 10);
    });

    test('5 of 10 sections → 50%', () {
      const state = ProfileCompletionState(
        sectionsFilled: {
          ProfileSection.photo: true,
          ProfileSection.dob: true,
          ProfileSection.gender: true,
          ProfileSection.username: true,
          ProfileSection.phone: true,
        },
        isLoading: false,
      );
      expect(state.percentage, 50);
    });
  });

  group('ProfileCompletionState.isComplete', () {
    test('returns false when sections map is empty', () {
      const state = ProfileCompletionState(
        sectionsFilled: {},
        isLoading: false,
      );
      expect(state.isComplete, isFalse);
    });

    test('returns false when some sections are not filled', () {
      const state = ProfileCompletionState(
        sectionsFilled: {
          ProfileSection.aboutMe: true,
          ProfileSection.experience: false,
        },
        isLoading: false,
      );
      expect(state.isComplete, isFalse);
    });

    test('returns true when all 10 sections are filled', () {
      final all = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: true,
      };
      final state = ProfileCompletionState(
        sectionsFilled: all,
        isLoading: false,
      );
      expect(state.isComplete, isTrue);
    });
  });

  group('ProfileCompletionState.shouldShowCard', () {
    final allFilled = <ProfileSection, bool>{
      for (final s in ProfileSection.values) s: true,
    };
    final partialFilled = <ProfileSection, bool>{
      ProfileSection.aboutMe: true,
      ProfileSection.experience: false,
    };

    test('returns false when loading', () {
      final state = ProfileCompletionState(
        sectionsFilled: partialFilled,
        isDismissed: false,
        isLoading: true,
      );
      expect(state.shouldShowCard, isFalse);
    });

    test('returns false when dismissed', () {
      final state = ProfileCompletionState(
        sectionsFilled: partialFilled,
        isDismissed: true,
        isLoading: false,
      );
      expect(state.shouldShowCard, isFalse);
    });

    test('returns false when profile is complete (all 10 sections)', () {
      final state = ProfileCompletionState(
        sectionsFilled: allFilled,
        isDismissed: false,
        isLoading: false,
      );
      expect(state.shouldShowCard, isFalse);
    });

    test('returns true when not loading, not dismissed, not complete', () {
      final state = ProfileCompletionState(
        sectionsFilled: partialFilled,
        isDismissed: false,
        isLoading: false,
      );
      expect(state.shouldShowCard, isTrue);
    });
  });

  // ── ProfileCompletionState.copyWith ───────────────────────────────────────

  group('ProfileCompletionState.copyWith', () {
    const initial = ProfileCompletionState(
      sectionsFilled: {ProfileSection.aboutMe: true},
      isDismissed: false,
      isLoading: true,
    );

    test('returns same values when no args provided', () {
      final copy = initial.copyWith();
      expect(copy.isDismissed, initial.isDismissed);
      expect(copy.isLoading, initial.isLoading);
      expect(copy.sectionsFilled, initial.sectionsFilled);
    });

    test('updates isDismissed only', () {
      final copy = initial.copyWith(isDismissed: true);
      expect(copy.isDismissed, isTrue);
      expect(copy.isLoading, initial.isLoading);
    });

    test('updates isLoading only', () {
      final copy = initial.copyWith(isLoading: false);
      expect(copy.isLoading, isFalse);
      expect(copy.isDismissed, initial.isDismissed);
    });

    test('updates sectionsFilled', () {
      final newMap = <ProfileSection, bool>{ProfileSection.skills: true};
      final copy = initial.copyWith(sectionsFilled: newMap);
      expect(copy.sectionsFilled, newMap);
    });
  });

  // ── ProfileSection enum coverage ─────────────────────────────────────────

  group('ProfileSection enum', () {
    test('has exactly 10 values', () {
      expect(ProfileSection.values.length, 10);
    });

    test('contains all 10 expected sections', () {
      expect(
        ProfileSection.values,
        containsAll([
          ProfileSection.photo,
          ProfileSection.username,
          ProfileSection.gender,
          ProfileSection.dob,
          ProfileSection.phone,
          ProfileSection.aboutMe,
          ProfileSection.experience,
          ProfileSection.skills,
          ProfileSection.academy,
          ProfileSection.activity,
        ]),
      );
    });

    test('includes username section', () {
      expect(ProfileSection.values, contains(ProfileSection.username));
    });
  });

  // ── ProfileCompletionActionsNotifier.getRouteForSection ───────────────────

  group('ProfileCompletionActionsNotifier.getRouteForSection', () {
    late ProviderContainer container;
    late ProfileCompletionActionsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(profileCompletionActionsProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('phone routes to edit profile page (inline editing)', () {
      expect(
        notifier.getRouteForSection(ProfileSection.phone),
        AppRoutes.editProfile,
      );
    });

    test('phone route is /profile/edit', () {
      expect(
        notifier.getRouteForSection(ProfileSection.phone),
        '/profile/edit',
      );
    });

    test('dob routes to edit profile page', () {
      expect(
        notifier.getRouteForSection(ProfileSection.dob),
        '/profile/edit',
      );
    });

    test('gender routes to edit profile page', () {
      expect(
        notifier.getRouteForSection(ProfileSection.gender),
        '/profile/edit',
      );
    });

    test('photo routes to edit profile page', () {
      expect(
        notifier.getRouteForSection(ProfileSection.photo),
        '/profile/edit',
      );
    });

    test('aboutMe routes to my-profile page (scroll-to section)', () {
      expect(
        notifier.getRouteForSection(ProfileSection.aboutMe),
        AppRoutes.myProfile,
      );
    });

    test('experience routes to my-profile page (scroll-to section)', () {
      expect(
        notifier.getRouteForSection(ProfileSection.experience),
        AppRoutes.myProfile,
      );
    });

    test('phone route equals editProfile (phone is now inline)', () {
      expect(
        notifier.getRouteForSection(ProfileSection.phone),
        AppRoutes.editProfile,
      );
    });

    test('username routes to edit profile page', () {
      expect(
        notifier.getRouteForSection(ProfileSection.username),
        '/profile/edit',
      );
    });
  });

  // ── Phone section completion state ────────────────────────────────────────

  group('ProfileCompletionState — phone section', () {
    test('phone section false when absent', () {
      const state = ProfileCompletionState(
        sectionsFilled: {ProfileSection.phone: false},
        isLoading: false,
      );
      expect(state.sectionsFilled[ProfileSection.phone], isFalse);
      expect(state.isComplete, isFalse);
    });

    test('phone section true when present', () {
      final all = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: true,
      };
      final state = ProfileCompletionState(
        sectionsFilled: all,
        isLoading: false,
      );
      expect(state.sectionsFilled[ProfileSection.phone], isTrue);
      expect(state.isComplete, isTrue);
    });

    test('profile not complete when only phone is missing', () {
      final allExceptPhone = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: s != ProfileSection.phone,
      };
      final state = ProfileCompletionState(
        sectionsFilled: allExceptPhone,
        isLoading: false,
      );
      expect(state.isComplete, isFalse);
      expect(state.completedCount, 9); // 10 - 1
    });

    test('profile not complete when only username is missing', () {
      final allExceptUsername = <ProfileSection, bool>{
        for (final s in ProfileSection.values) s: s != ProfileSection.username,
      };
      final state = ProfileCompletionState(
        sectionsFilled: allExceptUsername,
        isLoading: false,
      );
      expect(state.isComplete, isFalse);
      expect(state.completedCount, 9);
    });

    test('username section fills when set', () {
      const state = ProfileCompletionState(
        sectionsFilled: {ProfileSection.username: true},
        isLoading: false,
      );
      expect(state.sectionsFilled[ProfileSection.username], isTrue);
    });
  });
}

