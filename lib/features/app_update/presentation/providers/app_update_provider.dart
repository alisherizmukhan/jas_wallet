import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_update_remote_config_service.dart';
import '../../domain/entities/app_update_decision.dart';
import '../../domain/services/app_update_service.dart';

final appUpdateRemoteConfigServiceProvider = Provider<AppUpdateRemoteConfigService>(
  (ref) => AppUpdateRemoteConfigService(),
);

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    remoteConfigService: ref.read(appUpdateRemoteConfigServiceProvider),
  );
});

/// Holds the current [AppUpdateDecision]. Starts at
/// [AppUpdateDecision.unknown] — [check] must be called explicitly once
/// Firebase is initialized (see `lib/main.dart`'s `_initializeInBackground`,
/// which is the correct startup integration point: Firebase Remote Config
/// cannot be used before `Firebase.initializeApp()` resolves, and that call
/// already happens off the critical path, post-first-frame).
class AppUpdateNotifier extends StateNotifier<AppUpdateDecision> {
  AppUpdateNotifier(this._service) : super(AppUpdateDecision.unknown);

  final AppUpdateService _service;

  /// Runs the update check. Safe to call more than once — a redundant call
  /// is cheap, not a duplicate network fetch, since Remote Config itself
  /// enforces `minimumFetchInterval` caching underneath.
  Future<void> check() async {
    final decision = await _service.evaluate();
    if (!mounted) return;
    state = decision;
  }
}

final appUpdateStateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateDecision>((ref) {
  return AppUpdateNotifier(ref.read(appUpdateServiceProvider));
});
