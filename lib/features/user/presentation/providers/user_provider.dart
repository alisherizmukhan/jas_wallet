import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';

/// Repository provider for user data. Typed to the concrete impl (rather
/// than the domain interface) so [UserNotifier] can reach the offline-queue
/// [UserRepositoryImpl.flushPendingEdit] helper.
final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepositoryImpl(apiClient: apiClient);
});

/// Global user state provider.
/// Provides the current authenticated user throughout the application.
///
/// Listens to [authProvider] and keeps user data warm across session states.
/// When auth status changes to unauthenticated, automatically clears user.
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserEntity?>>((ref) {
      final notifier = UserNotifier(ref.watch(userRepositoryProvider));

      // React to auth STATUS TRANSITIONS only. AuthState is also re-emitted
      // with an unchanged status (biometric flag sync, copyWith updates);
      // hydrating on every emission caused duplicate `/students/me` calls —
      // each of which also re-triggered the avatar download.
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (previous?.status == next.status) return;
        if (next.status == AuthStatus.authenticated) {
          notifier.hydrateFromCacheAndRefresh(authUserId: next.userId);
        } else if (next.status == AuthStatus.needsPinSetup ||
            next.status == AuthStatus.needsBiometricSetup) {
          // Warm cache while user is on setup screens so app opens instantly
          // after setup is completed.
          notifier.hydrateFromCacheAndRefresh(authUserId: next.userId);
        } else if (next.status == AuthStatus.needsLocalAuth) {
          // During lock screen state we avoid network and hydrate from local
          // cache only.
          notifier.loadCachedUser();
        } else if (next.status == AuthStatus.unauthenticated ||
            next.status == AuthStatus.needsOnboarding ||
            next.status == AuthStatus.firstLaunch) {
          notifier.clearUser();
        }
      });

      // Initial warm-up for existing session states.
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated ||
          authState.status == AuthStatus.needsPinSetup ||
          authState.status == AuthStatus.needsBiometricSetup) {
        notifier.hydrateFromCacheAndRefresh(authUserId: authState.userId);
      } else if (authState.status == AuthStatus.needsLocalAuth) {
        notifier.loadCachedUser();
      }

      return notifier;
    });

/// User state notifier for managing user data.
class UserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  UserNotifier(this._repository) : super(const AsyncValue.data(null));

  final UserRepositoryImpl _repository;
  bool _isLoadingUser = false;

  bool isLoadedForAuthUser(String? authUserId) {
    final user = state.valueOrNull;
    if (user == null) return false;

    final loadedId = user.id.trim();
    if (loadedId.isEmpty) return false;

    final targetId = authUserId?.trim();
    if (targetId == null || targetId.isEmpty) return true;

    return loadedId == targetId;
  }

  /// Ensure UI has immediate cache data and trigger silent network refresh.
  void hydrateFromCacheAndRefresh({String? authUserId}) {
    if (!isLoadedForAuthUser(authUserId)) {
      unawaited(loadCachedUser());
    }
    refreshUserInBackground();
  }

  /// Hydrate state from local cache only (no network call).
  Future<void> loadCachedUser() async {
    try {
      final cachedUser = await _repository.getCachedCurrentUser();
      if (cachedUser != null) {
        _setUserIfChanged(cachedUser);
      } else if (state.hasError) {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      // Keep last visible state to avoid UI flicker.
    }
  }

  /// Load user from repository. Called when auth state becomes authenticated.
  Future<void> loadUser({
    bool forceRefresh = false,
    bool showLoadingWhenEmpty = true,
  }) async {
    if (_isLoadingUser) return;
    _isLoadingUser = true;

    try {
      if (!forceRefresh) {
        final cachedUser = await _repository.getCachedCurrentUser();
        if (cachedUser != null) {
          _setUserIfChanged(cachedUser);
        } else if (showLoadingWhenEmpty && state.valueOrNull == null) {
          state = const AsyncValue.loading();
        }
      } else if (showLoadingWhenEmpty && state.valueOrNull == null) {
        state = const AsyncValue.loading();
      }

      final freshUser = await _repository.refreshCurrentUser();
      if (freshUser != null) {
        _setUserIfChanged(freshUser);
      } else if (state.valueOrNull == null) {
        state = const AsyncValue.data(null);
      }
      // Opportunistic replay of a profile edit queued after an earlier
      // connectivity failure — fire-and-forget, never blocks or affects
      // this load. No-ops instantly when nothing is queued.
      unawaited(_repository.flushPendingEdit());
    } catch (_) {
      // Keep last visible data and avoid switching to error-state screens.
      if (state.valueOrNull == null) {
        state = const AsyncValue.data(null);
      }
    } finally {
      _isLoadingUser = false;
    }
  }

  /// Update user data
  Future<void> updateUser(UserEntity user) async {
    try {
      final updated = await _repository.updateUser(user);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update user profile fields
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? phone,
    String? email,
    String? studentId,
    String? gender,
    DateTime? dateOfBirth,
    String? city,
    String? avatarUrl,
  }) async {
    // If no user exists yet (e.g. during registration), create one
    final currentUser =
        state.valueOrNull ??
        const UserEntity(id: '', firstName: '', lastName: '', username: '');

    final updated = currentUser.copyWith(
      firstName: firstName,
      lastName: lastName,
      username: username,
      bio: bio,
      phone: phone,
      email: email,
      studentId: studentId,
      gender: gender,
      dateOfBirth: dateOfBirth,
      city: city,
      avatarUrl: avatarUrl,
    );
    final previousStateUser = currentUser;

    final hasStableIdentity = updated.id.trim().isNotEmpty;
    state = AsyncValue.data(updated);

    // Registration/login drafts can have empty id before auth is finalized.
    // In that case keep draft only in notifier state.
    if (!hasStableIdentity) return;

    try {
      final persisted = await _repository.updateUser(updated);
      state = AsyncValue.data(persisted);
    } catch (e, st) {
      state = AsyncValue.data(previousStateUser);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update bio only
  void updateBio(String bio) {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    state = AsyncValue.data(currentUser.copyWith(bio: bio));
  }

  /// Update email
  void updateEmail(String email) {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    state = AsyncValue.data(currentUser.copyWith(email: email));
  }

  /// Update phone number
  void updatePhoneNumber(String phone) {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    state = AsyncValue.data(currentUser.copyWith(phone: phone));
  }

  /// Update avatar
  Future<void> updateAvatar(String? path) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    final normalizedPath = path?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) return;

    final previousUser = currentUser;
    final optimisticUser = currentUser.copyWith(avatarUrl: normalizedPath);
    state = AsyncValue.data(optimisticUser);

    final hasStableIdentity = optimisticUser.id.trim().isNotEmpty;
    if (!hasStableIdentity) return;

    try {
      final persisted = _shouldUploadAvatarBinary(normalizedPath)
          ? await _repository.uploadAvatar(normalizedPath)
          : await _repository.updateUser(optimisticUser);
      state = AsyncValue.data(persisted);
    } catch (e, st) {
      state = AsyncValue.data(previousUser);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;

    final hasStableIdentity = currentUser.id.trim().isNotEmpty;
    if (!hasStableIdentity) return;

    final previousUser = currentUser;
    state = AsyncValue.data(currentUser.copyWith(avatarUrl: ''));

    try {
      final persisted = await _repository.deleteAvatar();
      state = AsyncValue.data(persisted);
    } catch (e, st) {
      state = AsyncValue.data(previousUser);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Update date of birth
  void updateDateOfBirth(DateTime date) {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    state = AsyncValue.data(currentUser.copyWith(dateOfBirth: date));
  }

  /// Update gender
  void updateGender(String gender) {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    state = AsyncValue.data(currentUser.copyWith(gender: gender));
  }

  /// Clear user (logout)
  void clearUser() {
    _repository.clearCache();
    state = const AsyncValue.data(null);
  }

  /// Refresh user data from server
  Future<void> refreshUser({bool showLoadingWhenEmpty = false}) async {
    await loadUser(
      forceRefresh: true,
      showLoadingWhenEmpty: showLoadingWhenEmpty,
    );
  }

  /// Refresh user silently without blocking current UI state.
  void refreshUserInBackground() {
    unawaited(loadUser(forceRefresh: true, showLoadingWhenEmpty: false));
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _repository.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool _shouldUploadAvatarBinary(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return false;
    return true;
  }

  void _setUserIfChanged(UserEntity? nextUser) {
    final currentUser = state.valueOrNull;
    if (_isSameUser(currentUser, nextUser)) return;
    state = AsyncValue.data(nextUser);
  }

  bool _isSameUser(UserEntity? a, UserEntity? b) {
    if (identical(a, b)) return true;
    return a == b;
  }
}

/// Global user stats provider.
final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStatsEntity>>((
      ref,
    ) {
      return UserStatsNotifier(ref.watch(userRepositoryProvider));
    });

/// User stats notifier for managing statistics data.
class UserStatsNotifier extends StateNotifier<AsyncValue<UserStatsEntity>> {
  UserStatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  final UserRepositoryImpl _repository;

  Future<void> _loadStats() async {
    try {
      final stats = await _repository.getUserStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Refresh stats from server
  Future<void> refreshStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getUserStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Global achievements provider.
final achievementsProvider =
    StateNotifierProvider<
      AchievementsNotifier,
      AsyncValue<List<AchievementEntity>>
    >((ref) {
      return AchievementsNotifier();
    });

/// Achievements notifier for managing achievement data.
class AchievementsNotifier
    extends StateNotifier<AsyncValue<List<AchievementEntity>>> {
  AchievementsNotifier() : super(const AsyncValue.data([]));

  Future<void> refreshAchievements() async {
    // No-op until backend endpoint is implemented.
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// USER ROLE PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

/// Current user's actual role from their profile.
final userRoleProvider = Provider<UserRole>((ref) {
  final userAsync = ref.watch(userProvider);
  return userAsync.valueOrNull?.role ?? UserRole.student;
});
