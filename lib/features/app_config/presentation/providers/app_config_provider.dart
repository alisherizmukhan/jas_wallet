import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_config_repository_impl.dart';
import '../../domain/models/app_config_model.dart';
import '../../domain/repositories/app_config_repository.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return const AppConfigRepositoryImpl();
});

/// Current [AppConfigModel].
///
/// Automatically falls back to [AppConfigModel.fallback] on error so the UI
/// is always functional regardless of backend availability.
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  try {
    return await ref.watch(appConfigRepositoryProvider).getConfig();
  } catch (_) {
    return AppConfigModel.fallback;
  }
});
