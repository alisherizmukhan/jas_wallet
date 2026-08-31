import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../models/salto_mobile_status.dart';
import '../services/salto_key_refresh_policy.dart';
import 'salto_repository.dart';

class SaltoRepositoryException implements Exception {
  const SaltoRepositoryException(this.message, {this.isTimeout = false});

  final String message;

  /// True when the request was *sent* but no response arrived in time, i.e.
  /// the server may still be working on it. Only the activation POST sets
  /// this, and only for send/receive timeouts — a connect timeout or a
  /// connection error never reached the server and is safely retryable.
  ///
  /// Callers must not invite the user to "try again" on this: activation is
  /// destructive and non-idempotent, so a resend can cancel the very key the
  /// still-running first request is issuing.
  final bool isTimeout;

  @override
  String toString() => message;
}

enum _SaltoOperation { status, activation, key }

/// Implementation of [SaltoRepository] using JasWallet backend API.
class SaltoRepositoryImpl implements SaltoRepository {
  SaltoRepositoryImpl({
    required ApiClient apiClient,
    required AuthStorageService authStorage,
  }) : _client = apiClient,
       _authStorage = authStorage;

  final ApiClient _client;
  final AuthStorageService _authStorage;
  static const _keyCacheTtl = Duration(minutes: 10);
  static const _keyRequestTimeout = Duration(seconds: 6);

  /// Activation gets a far longer budget than the client's 15s default.
  ///
  /// `POST /salto/me/activate-mobile` is not a normal request: the backend
  /// runs six to nine *sequential* blocking SHIP round trips behind it
  /// (read user → ensure link → set mobile policy → set app type → cancel
  /// old key → re-issue key → re-read status), each with its own 30s server
  /// -side budget. On the default 15s the client routinely gave up while the
  /// server was still mid-sequence — the user saw a generic "try again"
  /// error, tapped again, and a second destructive activation raced the
  /// first. This budget is sized to outlast the realistic worst case rather
  /// than the average one.
  static const _activationRequestTimeout = Duration(seconds: 90);

  String? _cachedDigitalKeyHex;
  DateTime? _cachedDigitalKeyAt;
  Future<String?>? _inFlightKeyRequest;
  Future<String?>? _inFlightForceRefreshRequest;

  /// How long a successful [getMobileStatus] network fetch is considered
  /// "fresh" by [isStatusFresh] — lets [saltoStatusProvider] (which is
  /// autoDispose and rebuilt every time the user re-enters the SALTO Access
  /// page) skip its background network refresh when the previous tab visit
  /// already fetched status moments ago, instead of hitting
  /// `/salto/me/status` on every single tab switch.
  static const _statusCacheTtl = Duration(seconds: 90);
  DateTime? _lastStatusFetchAt;
  Future<SaltoMobileStatus>? _inFlightStatusRequest;

  /// Whether the last successful network status fetch is still within
  /// [_statusCacheTtl].
  bool isStatusFresh() {
    final at = _lastStatusFetchAt;
    return at != null && DateTime.now().difference(at) < _statusCacheTtl;
  }

  /// [cancelToken] lets a caller abandon this request (e.g. the page that
  /// started it is disposed before the response arrives) instead of
  /// letting it run to completion for a result nobody will read. Only
  /// meaningful on the non-coalesced path — a caller arriving while another
  /// request is already in flight shares that request's outcome regardless
  /// of its own token, since cancelling would also cancel the first
  /// caller's still-wanted result.
  @override
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken}) {
    // Coalesce concurrent callers (e.g. a pull-to-refresh firing alongside
    // the status provider's own background refresh) into one request.
    final inFlight = _inFlightStatusRequest;
    if (inFlight != null) return inFlight;

    final requestFuture = _fetchMobileStatus(cancelToken: cancelToken);
    _inFlightStatusRequest = requestFuture;
    return requestFuture.whenComplete(() {
      if (identical(_inFlightStatusRequest, requestFuture)) {
        _inFlightStatusRequest = null;
      }
    });
  }

  Future<SaltoMobileStatus> _fetchMobileStatus({CancelToken? cancelToken}) async {
    try {
      final mobilePhoneId = await _authStorage.getOrCreateSaltoMobilePhoneId();
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/salto/me/status',
        queryParameters: {'mobile_phone_id': mobilePhoneId},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data == null) throw Exception('Invalid response');
      final status = SaltoMobileStatus.fromJson(data);
      _lastStatusFetchAt = DateTime.now();
      // Persist for offline fallback.
      await _authStorage.saveSaltoMobileStatus(jsonEncode(status.toJson()));
      return status;
    } on DioException catch (e) {
      // Network failure — try cached status.
      final cached = await _getCachedMobileStatus();
      if (cached != null) return cached;
      throw _mapError(e, operation: _SaltoOperation.status);
    }
  }

  /// Fetches status straight from the network, with **no cached fallback**.
  ///
  /// [getMobileStatus] deliberately falls back to the last persisted status
  /// so the Open button is never blocked — but that makes it useless for
  /// answering "did the activation that just timed out actually land?", since
  /// a stale cached `false` is indistinguishable from a real one. This throws
  /// instead, so the caller can tell "server says not yet" apart from "could
  /// not reach the server".
  Future<SaltoMobileStatus> getFreshMobileStatus() async {
    final mobilePhoneId = await _authStorage.getOrCreateSaltoMobilePhoneId();
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/salto/me/status',
      queryParameters: {'mobile_phone_id': mobilePhoneId},
    );
    final data = response.data;
    if (data == null) throw const SaltoRepositoryException('Invalid response');
    final status = SaltoMobileStatus.fromJson(data);
    _lastStatusFetchAt = DateTime.now();
    await _authStorage.saveSaltoMobileStatus(jsonEncode(status.toJson()));
    return status;
  }

  Future<SaltoMobileStatus?> _getCachedMobileStatus() async {
    final jsonStr = await _authStorage.getSaltoMobileStatus();
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SaltoMobileStatus.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SaltoMobileStatus> activateMobileAccess() async {
    try {
      final mobilePhoneId = await _authStorage.getOrCreateSaltoMobilePhoneId();
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/salto/me/activate-mobile',
        data: {
          'confirm_disable_card': true,
          'mobile_phone_id': mobilePhoneId,
        },
        options: Options(
          sendTimeout: _activationRequestTimeout,
          receiveTimeout: _activationRequestTimeout,
        ),
      );
      final data = response.data;
      if (data == null) throw Exception('Invalid response');
      return SaltoMobileStatus.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e, operation: _SaltoOperation.activation);
    }
  }

  @override
  Future<SaltoMobileStatus?> getCachedMobileStatus() => _getCachedMobileStatus();

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // 1. In-memory cache (10 min).
      final memCached = _getCachedKey();
      if (memCached != null) return memCached;

      final inFlightRequest = _inFlightKeyRequest;
      if (inFlightRequest != null) return inFlightRequest;

      // 2. Persistent 7-day cache — return immediately without a network call.
      final persisted = await _authStorage.getSaltoDigitalKey();
      if (persisted != null) {
        _cacheKey(persisted); // prime in-memory cache
        unawaited(_backgroundRefreshIfStale());
        return persisted;
      }
    } else {
      // Deduplicate concurrent forceRefresh=true calls (e.g. prewarm + unlock).
      final inFlight = _inFlightForceRefreshRequest;
      if (inFlight != null) return inFlight;
    }

    // 3. Network fetch.
    final requestFuture = _fetchDigitalKeyFromApi(forceRefresh: forceRefresh);
    if (!forceRefresh) {
      _inFlightKeyRequest = requestFuture;
    } else {
      _inFlightForceRefreshRequest = requestFuture;
    }

    try {
      final key = await requestFuture;
      if (key != null && key.isNotEmpty) return key;
      return _authStorage.getSaltoDigitalKey();
    } on SaltoRepositoryException {
      final persisted = await _authStorage.getSaltoDigitalKey();
      if (persisted != null) return persisted;
      rethrow;
    } finally {
      if (!forceRefresh && identical(_inFlightKeyRequest, requestFuture)) {
        _inFlightKeyRequest = null;
      }
      if (forceRefresh && identical(_inFlightForceRefreshRequest, requestFuture)) {
        _inFlightForceRefreshRequest = null;
      }
    }
  }

  /// Silently refresh the digital key when the persisted copy is getting
  /// old. The threshold is jittered ±12h per device (see
  /// [SaltoKeyRefreshPolicy.jitterFor]) so a cohort of devices whose keys
  /// were all issued around the same time don't all cross it in the same
  /// instant and stampede the SALTO backend at once.
  Future<void> _backgroundRefreshIfStale() async {
    final storedAt = await _authStorage.getSaltoDigitalKeyStoredAt();
    if (storedAt == null) return;

    final mobilePhoneId = await _authStorage.getOrCreateSaltoMobilePhoneId();
    final earlyRefreshThreshold = SaltoKeyRefreshPolicy.baseEarlyRefreshThreshold +
        SaltoKeyRefreshPolicy.jitterFor(mobilePhoneId);
    final staleAge = SaltoKeyRefreshPolicy.keyTtl - earlyRefreshThreshold;
    if (DateTime.now().difference(storedAt) < staleAge) return;

    try {
      await _fetchDigitalKeyFromApi(forceRefresh: false);
    } catch (_) {}
  }

  Future<String?> _fetchDigitalKeyFromApi({required bool forceRefresh}) async {
    try {
      final mobilePhoneId = await _authStorage.getOrCreateSaltoMobilePhoneId();
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/salto/me/key',
        queryParameters: {
          if (forceRefresh) 'refresh': true,
          'mobile_phone_id': mobilePhoneId,
        },
        options: Options(
          connectTimeout: _keyRequestTimeout,
          receiveTimeout: _keyRequestTimeout,
          sendTimeout: _keyRequestTimeout,
        ),
      );
      final data = response.data;
      if (data == null) return null;
      final keyHex = data['digital_key_hex'] as String?;
      _cacheKey(keyHex);
      return keyHex;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 409) {
        return null;
      }

      final cachedKey = _getCachedKey();
      if (cachedKey != null) {
        return cachedKey;
      }

      // Try 7-day persistent cache before throwing.
      final persisted = await _authStorage.getSaltoDigitalKey();
      if (persisted != null) return persisted;

      throw _mapError(e, operation: _SaltoOperation.key);
    }
  }

  String? _getCachedKey() {
    final key = _cachedDigitalKeyHex;
    if (key == null || key.isEmpty) return null;

    final cachedAt = _cachedDigitalKeyAt;
    if (cachedAt == null) return null;

    final isFresh = DateTime.now().difference(cachedAt) <= _keyCacheTtl;
    if (!isFresh) {
      _cachedDigitalKeyHex = null;
      _cachedDigitalKeyAt = null;
      return null;
    }

    return key;
  }

  void _cacheKey(String? keyHex) {
    final normalized = keyHex?.trim();
    if (normalized == null || normalized.isEmpty) {
      _cachedDigitalKeyHex = null;
      _cachedDigitalKeyAt = null;
      return;
    }

    _cachedDigitalKeyHex = normalized;
    _cachedDigitalKeyAt = DateTime.now();
    // Also persist for 7-day offline use.
    _authStorage.saveSaltoDigitalKey(normalized);
  }

  SaltoRepositoryException _mapError(
    DioException e, {
    required _SaltoOperation operation,
  }) {
    final detail = _extractDetail(e)?.toLowerCase() ?? '';
    final statusCode = e.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return const SaltoRepositoryException(
        'Your session expired. Please sign in again and try once more.',
      );
    }

    // The request reached the server but the response didn't come back in
    // time — for activation that means the destructive sequence may still be
    // running, so this is flagged rather than folded into the generic
    // connectivity copy that tells the user to try again.
    if (operation == _SaltoOperation.activation && _isInFlightTimeout(e)) {
      return const SaltoRepositoryException(
        'Enabling mobile access is taking longer than usual. Do not retry — '
        'we are checking whether it completed.',
        isTimeout: true,
      );
    }

    if (_isConnectivityError(e)) {
      switch (operation) {
        case _SaltoOperation.status:
          return const SaltoRepositoryException(
            'Could not load access status right now. Check your internet and try again.',
          );
        case _SaltoOperation.activation:
          return const SaltoRepositoryException(
            'Could not enable mobile access right now. Please try again in a moment.',
          );
        case _SaltoOperation.key:
          return const SaltoRepositoryException(
            'Could not prepare the mobile key right now. Check your internet and try again.',
          );
      }
    }

    if (operation == _SaltoOperation.activation) {
      if (detail.contains('complete your first name') ||
          detail.contains('student/card id') ||
          detail.contains('student card id is required')) {
        return const SaltoRepositoryException(
          'Complete your profile first, then try enabling mobile access again.',
        );
      }
      if (detail.contains('no salto user found')) {
        return const SaltoRepositoryException(
          'We could not find your university access record. Please contact support if this continues.',
        );
      }
      if (detail.contains('multiple salto users') ||
          detail.contains('does not match') ||
          detail.contains('already linked')) {
        return const SaltoRepositoryException(
          'Your access record could not be confirmed automatically. Please contact support.',
        );
      }
      if (detail.contains(
        'key expiration exceeds the maximum allowed for the specified mobile app',
      )) {
        return const SaltoRepositoryException(
          'Your university access profile is not yet configured for mobile access. Please contact support or the security office.',
        );
      }
      if (detail.contains('could not obtain salto key') ||
          detail.contains('ship connectivity') ||
          detail.contains('space configuration')) {
        return const SaltoRepositoryException(
          'Mobile access was not prepared successfully. Please try again later or contact support.',
        );
      }
      return const SaltoRepositoryException(
        'Could not enable mobile access right now. Please try again later.',
      );
    }

    if (operation == _SaltoOperation.key) {
      if (detail.contains('another device') ||
          detail.contains('re-enable mobile access on this phone')) {
        return const SaltoRepositoryException(
          'Mobile access is linked to another device. Re-enable access on this phone to continue.',
        );
      }
      return const SaltoRepositoryException(
        'Could not prepare access in the app right now. Please try again.',
      );
    }

    return const SaltoRepositoryException(
      'Could not load SALTO access right now. Please try again.',
    );
  }

  String? _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is Map<String, dynamic>) {
        final error = detail['error'];
        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    }
    return e.message;
  }

  /// A timeout that happened *after* the request went out, so the server may
  /// have received and acted on it. A `connectionTimeout`/`connectionError`
  /// is deliberately excluded: those never delivered the request.
  bool _isInFlightTimeout(DioException e) {
    return e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  bool _isConnectivityError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }
}
