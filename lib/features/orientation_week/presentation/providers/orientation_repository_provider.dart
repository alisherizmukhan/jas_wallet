import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../data/repositories/orientation_repository_hybrid_impl.dart';
import '../../domain/repositories/orientation_repository.dart';

/// Photo Quest, tokens, the leaderboard, challenges and bingo hit the live
/// backend; the schedule, rewards and mini-games stay on the local mock.
///
/// Watching the locale on purpose: task texts come from the server in the
/// app's language, so switching language rebuilds the repository and every
/// notifier reloads with fresh translations.
final orientationRepositoryProvider = Provider<OrientationRepository>((ref) {
  final languageCode = ref.watch(localeProvider).languageCode;
  return OrientationRepositoryHybridImpl(
    apiClient: ref.watch(apiClientProvider),
    languageCode: () => languageCode,
  );
});
