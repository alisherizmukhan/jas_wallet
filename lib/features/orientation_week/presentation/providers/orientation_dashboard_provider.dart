import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/orientation_dashboard.dart';
import '../../domain/repositories/orientation_repository.dart';
import 'orientation_repository_provider.dart';

class OrientationDashboardState {
  const OrientationDashboardState({
    required this.dashboard,
    required this.isLoading,
    required this.isOffline,
    this.error,
  });

  const OrientationDashboardState.initial()
      : dashboard = null,
        isLoading = true,
        isOffline = false,
        error = null;

  final OrientationDashboard? dashboard;
  final bool isLoading;
  final bool isOffline;
  final Object? error;

  bool get hasData => dashboard != null;

  OrientationDashboardState copyWith({
    OrientationDashboard? dashboard,
    bool? isLoading,
    bool? isOffline,
    Object? error,
    bool clearError = false,
  }) {
    return OrientationDashboardState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OrientationDashboardNotifier extends StateNotifier<OrientationDashboardState> {
  OrientationDashboardNotifier(this._repo) : super(const OrientationDashboardState.initial()) {
    load();
  }

  final OrientationRepository _repo;

  Future<void> load({bool isRetry = false}) async {
    state = state.copyWith(isLoading: true, isOffline: false, clearError: true);
    try {
      final dashboard = await _repo.getDashboard();
      state = state.copyWith(dashboard: dashboard, isLoading: false, clearError: true);
    } catch (e) {
      final isConnected = await ConnectivityService.isConnected();
      state = state.copyWith(isLoading: false, isOffline: !isConnected, error: e);
    }
  }

}

final orientationDashboardProvider =
    StateNotifierProvider<OrientationDashboardNotifier, OrientationDashboardState>(
  (ref) => OrientationDashboardNotifier(ref.read(orientationRepositoryProvider)),
);
