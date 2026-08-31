import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../data/repositories/referral_repository_impl.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/referral_model.dart';
import '../../domain/repositories/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepositoryImpl(ref.watch(apiClientProvider));
});

final referralProvider =
    StateNotifierProvider<ReferralNotifier, AsyncValue<ReferralModel>>((ref) {
      return ReferralNotifier(
        repository: ref.watch(referralRepositoryProvider),
        ref: ref,
      );
    });

class ReferralNotifier extends StateNotifier<AsyncValue<ReferralModel>> {
  ReferralNotifier({required this.repository, required this.ref})
    : super(const AsyncValue.loading()) {
    _load();
  }

  final ReferralRepository repository;
  final Ref ref;

  /// Cancels the previous [refresh] call's request when a new one
  /// supersedes it (e.g. rapid retry-button taps) — otherwise both requests
  /// complete independently and whichever response arrives last silently
  /// wins, regardless of which tap came first.
  CancelToken? _refreshCancelToken;

  @override
  void dispose() {
    _refreshCancelToken?.cancel('ReferralNotifier disposed');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = ref.read(userProvider).valueOrNull;
      if (user == null) {
        state = AsyncValue.error('User not loaded', StackTrace.current);
        return;
      }
      final model = await repository.getReferral(
        userId: user.id,
        username: user.username,
      );
      if (mounted) state = AsyncValue.data(model);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) return;

    _refreshCancelToken?.cancel('superseded by a newer refresh() call');
    final cancelToken = CancelToken();
    _refreshCancelToken = cancelToken;

    try {
      // Re-fetch the full record (code + count) so a transient stats call can
      // never blank out the code, and the counter always reflects the server.
      final model = await repository.getReferral(
        userId: user.id,
        username: user.username,
        cancelToken: cancelToken,
      );
      if (mounted) state = AsyncValue.data(model);
    } catch (_) {
      // Keep the currently displayed data on a refresh failure (including a
      // cancellation — the newer, superseding call owns state from here).
    }
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

// BACKEND: calls GET /referral/leaderboard?limit=10
// Returns [] until the backend endpoint is connected (see ReferralRepositoryImpl.getLeaderboard).
final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  // Select only the two fields this fetch depends on. Watching the whole
  // userProvider re-executed the leaderboard request on EVERY profile
  // emission (background refresh, bio edit, …) for as long as this
  // non-autoDispose provider stayed alive.
  final (userId, myAvatar) = ref.watch(
    userProvider.select((u) {
      final user = u.valueOrNull;
      return (user?.id, user?.avatarUrl);
    }),
  );
  if (userId == null) return [];
  final entries = await ref
      .read(referralRepositoryProvider)
      .getLeaderboard(userId: userId);
  // Inject the current user's known avatar URL into their leaderboard entry
  // in case the backend omits it.
  if (myAvatar == null || myAvatar.isEmpty) return entries;
  return entries.map((e) {
    if (e.isCurrentUser && (e.avatarUrl == null || e.avatarUrl!.isEmpty)) {
      return LeaderboardEntry(
        name: e.name,
        referralCount: e.referralCount,
        isCurrentUser: true,
        avatarUrl: myAvatar,
      );
    }
    return e;
  }).toList();
});
