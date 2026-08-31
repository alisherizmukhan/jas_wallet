import 'package:dio/dio.dart';

import '../models/salto_mobile_status.dart';

/// Repository for SALTO digital key API.
abstract class SaltoRepository {
  /// Return the user's current SALTO mobile activation state.
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken});

  /// Return the cached mobile status without a network call.
  /// Returns null if no valid cached status is available.
  Future<SaltoMobileStatus?> getCachedMobileStatus();

  /// Explicitly switch the user from physical card to mobile access.
  Future<SaltoMobileStatus> activateMobileAccess();

  /// Fetch digital key hex for the current user.
  /// Returns null if not configured or error.
  Future<String?> getDigitalKey({bool forceRefresh = false});
}
