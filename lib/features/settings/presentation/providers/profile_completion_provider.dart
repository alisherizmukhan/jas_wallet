import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/routing/app_router.dart';
import '../../../experience/providers/experience_provider.dart';
import '../../../skills/providers/skills_provider.dart';
import '../../../academy/providers/academy_provider.dart';
import '../../../activity/providers/user_activity_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';

/// Profile sections that count toward the 10-item completion score.
///
/// Order mirrors the canonical sequence shown in the completion card:
/// photo → username → gender → dob → phone →
/// aboutMe → experience → skills → activity → academy.
///
/// Full name is intentionally excluded — it is sourced from SALTO and
/// always present; students cannot change it.
enum ProfileSection {
  photo,
  username,
  gender,
  dob,
  phone,
  aboutMe,
  experience,
  skills,
  activity,
  academy,
}

/// State for profile completion — includes dismissed flag and loading state.
class ProfileCompletionState {
  final Map<ProfileSection, bool> sectionsFilled;
  final bool isDismissed;
  final bool isLoading;

  const ProfileCompletionState({
    this.sectionsFilled = const {},
    this.isDismissed = false,
    this.isLoading = true,
  });

  /// Number of completed sections.
  int get completedCount => sectionsFilled.values.where((v) => v).length;

  /// Total number of sections — always 10.
  int get totalCount => ProfileSection.values.length;

  /// Completion percentage (0–100).
  int get percentage =>
      totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

  /// Whether every section is filled.
  bool get isComplete => completedCount == totalCount;

  /// Whether to show the completion card.
  bool get shouldShowCard => !isDismissed && !isComplete && !isLoading;

  /// Fields that are incomplete, as string names (matches gamification keys).
  List<String> get missingFields => sectionsFilled.entries
      .where((e) => !e.value)
      .map((e) => e.key.name)
      .toList(growable: false);

  ProfileCompletionState copyWith({
    Map<ProfileSection, bool>? sectionsFilled,
    bool? isDismissed,
    bool? isLoading,
  }) {
    return ProfileCompletionState(
      sectionsFilled: sectionsFilled ?? this.sectionsFilled,
      isDismissed: isDismissed ?? this.isDismissed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Dismissed state provider — loads from SharedPreferences.
final _profileCompletionDismissedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('profile_completion_dismissed') ?? false;
});

/// Provider that computes profile completion by watching all relevant providers.
///
/// Single source of truth for the profile page completion card and
/// section highlight borders. The gamification layer derives from
/// [user_profile.profileCompletionProvider] in features/user which
/// uses the same logic with the same string keys.
final profileCompletionProvider = Provider<ProfileCompletionState>((ref) {
  // Watch all data providers reactively.
  final userAsync = ref.watch(userProvider);
  final experienceAsync = ref.watch(experienceListProvider);
  final skillsAsync = ref.watch(skillsListProvider);
  final academyAsync = ref.watch(academyListProvider);
  final activityList = ref.watch(userActivityListProvider);
  final dismissedAsync = ref.watch(_profileCompletionDismissedProvider);

  // Show loading until ALL critical providers have resolved at least once.
  // This prevents the card from showing incorrect low completion while async
  // list providers (experience, skills, academy, activity) are still loading.
  final hasAnyUserData = userAsync.valueOrNull != null;
  final isInitialLoading =
      (!hasAnyUserData && userAsync.isLoading) ||
      dismissedAsync.isLoading ||
      (experienceAsync.isLoading && experienceAsync.valueOrNull == null) ||
      (skillsAsync.isLoading && skillsAsync.valueOrNull == null) ||
      (academyAsync.isLoading && academyAsync.valueOrNull == null) ||
      ref.read(userActivityListProvider.notifier).isInitializing;

  if (isInitialLoading) {
    return const ProfileCompletionState(isLoading: true);
  }

  final user = userAsync.valueOrNull;
  final sectionsFilled = <ProfileSection, bool>{};

  // 1. Profile photo
  sectionsFilled[ProfileSection.photo] =
      user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty;

  // 2. Username — a real handle (not an email fallback, min 3 chars)
  final uname = user?.username.trim() ?? '';
  sectionsFilled[ProfileSection.username] =
      uname.isNotEmpty && !uname.contains('@') && uname.length >= 3;

  // 3. Gender
  sectionsFilled[ProfileSection.gender] =
      user?.gender != null && user!.gender!.trim().isNotEmpty;

  // 4. Date of birth — backend field: date_of_birth
  sectionsFilled[ProfileSection.dob] = user?.dateOfBirth != null;

  // 5. Phone
  sectionsFilled[ProfileSection.phone] =
      user?.phone != null && user!.phone!.trim().isNotEmpty;

  // 6. About Me — uses bio from userProvider (backend-persisted)
  sectionsFilled[ProfileSection.aboutMe] =
      user?.bio != null && user!.bio!.trim().isNotEmpty;

  // 7. Experience
  sectionsFilled[ProfileSection.experience] = experienceAsync.maybeWhen(
    data: (list) => list.isNotEmpty,
    orElse: () => experienceAsync.valueOrNull?.isNotEmpty ?? false,
  );

  // 8. Skills
  sectionsFilled[ProfileSection.skills] = skillsAsync.maybeWhen(
    data: (list) => list.isNotEmpty,
    orElse: () => skillsAsync.valueOrNull?.isNotEmpty ?? false,
  );

  // 9. Activity — StateNotifierProvider<…, List<…>>, empty until loaded
  sectionsFilled[ProfileSection.activity] = activityList.isNotEmpty;

  // 10. Academy
  sectionsFilled[ProfileSection.academy] = academyAsync.maybeWhen(
    data: (list) => list.isNotEmpty,
    orElse: () => academyAsync.valueOrNull?.isNotEmpty ?? false,
  );

  final isDismissed = dismissedAsync.valueOrNull ?? false;

  final state = ProfileCompletionState(
    sectionsFilled: sectionsFilled,
    isDismissed: isDismissed,
    isLoading: false,
  );

  // Auto-dismiss permanently once profile reaches 100%.
  if (state.isComplete && !isDismissed) {
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completion_dismissed', true);
      ref.invalidate(_profileCompletionDismissedProvider);
    });
  }

  return state;
});

/// Notifier for profile completion actions (dismiss, reset, routing).
class ProfileCompletionActionsNotifier extends StateNotifier<bool> {
  ProfileCompletionActionsNotifier(this._ref) : super(false);

  final Ref _ref;
  static const String _dismissedKey = 'profile_completion_dismissed';

  /// Dismiss the completion card (user tapped X).
  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    _ref.invalidate(_profileCompletionDismissedProvider);
  }

  /// Reset dismissed state (for testing or when user wants to see it again).
  Future<void> resetDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, false);
    _ref.invalidate(_profileCompletionDismissedProvider);
  }

  /// Get the first incomplete section for routing.
  ProfileSection? getFirstIncompleteSection() {
    final state = _ref.read(profileCompletionProvider);
    for (final section in ProfileSection.values) {
      if (state.sectionsFilled[section] != true) {
        return section;
      }
    }
    return null;
  }

  /// Get the route for a specific section.
  ///
  /// Resume sections (aboutMe, experience, skills, academy, activity) navigate
  /// to the MyProfile page where those sections are visible and auto-scrollable.
  /// Basic profile sections (photo, username, gender, dob, phone) navigate to
  /// EditProfile where the inline fields are.
  String getRouteForSection(ProfileSection section) {
    switch (section) {
      case ProfileSection.aboutMe:
      case ProfileSection.experience:
      case ProfileSection.skills:
      case ProfileSection.academy:
      case ProfileSection.activity:
        return AppRoutes.myProfile;
      case ProfileSection.phone:
      case ProfileSection.photo:
      case ProfileSection.username:
      case ProfileSection.gender:
      case ProfileSection.dob:
        return AppRoutes.editProfile;
    }
  }
}

/// Provider for profile completion actions (dismiss, etc.).
final profileCompletionActionsProvider =
    StateNotifierProvider<ProfileCompletionActionsNotifier, bool>((ref) {
  return ProfileCompletionActionsNotifier(ref);
});
