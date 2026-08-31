import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/auth_repository.dart';

/// API client provider (Dio with auth interceptor).
final apiClientProvider = Provider<ApiClient>((ref) {
  final authStorage = ref.watch(authStorageServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return ApiClient(
    authStorage: authStorage,
    onSessionExpired: () => authNotifier.forceReAuth(),
  );
});

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authStorage = ref.watch(authStorageServiceProvider);
  return AuthRepositoryImpl(apiClient: apiClient, authStorage: authStorage);
});
