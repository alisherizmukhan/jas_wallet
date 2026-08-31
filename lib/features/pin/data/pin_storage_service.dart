import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../core/services/auth_storage_service.dart';

/// Maximum allowed failed PIN attempts before locking.
const int maxPinAttempts = 5;

/// Lock duration after max failed attempts.
const Duration pinLockDuration = Duration(seconds: 30);

/// Service for secure PIN storage and verification.
///
/// PINs are hashed using HMAC-SHA256 with a random salt before storage.
/// The raw PIN is never persisted.
class PinStorageService {
  PinStorageService(this._authStorage);

  final AuthStorageService _authStorage;

  String? _cachedPinHash;
  String? _cachedPinSalt;
  int? _cachedFailedAttempts;
  DateTime? _cachedLockUntil;
  bool _pinMaterialLoaded = false;
  bool _lockStateLoaded = false;
  Future<void>? _warmUpFuture;

  Future<void> _ensurePinMaterialLoaded() async {
    if (_pinMaterialLoaded) return;
    final values = await Future.wait<String?>([
      _authStorage.getPinHash(),
      _authStorage.getPinSalt(),
    ]);
    _cachedPinHash = values[0];
    _cachedPinSalt = values[1];
    _pinMaterialLoaded = true;
  }

  Future<void> _ensureLockStateLoaded() async {
    if (_lockStateLoaded) return;
    final values = await Future.wait<Object?>([
      _authStorage.getPinFailedAttempts(),
      _authStorage.getPinLockUntil(),
    ]);
    _cachedFailedAttempts = (values[0] as int?) ?? 0;
    _cachedLockUntil = values[1] as DateTime?;
    _lockStateLoaded = true;
  }

  /// Preload PIN material and lock state before first user input.
  Future<void> warmUp() async {
    if (_pinMaterialLoaded && _lockStateLoaded) return;

    final inFlight = _warmUpFuture;
    if (inFlight != null) {
      return inFlight;
    }

    _warmUpFuture = _doWarmUp();
    try {
      await _warmUpFuture!;
    } finally {
      _warmUpFuture = null;
    }
  }

  Future<void> _doWarmUp() async {
    await Future.wait<void>([
      _ensurePinMaterialLoaded(),
      _ensureLockStateLoaded(),
    ]);
    await _clearExpiredLockIfNeeded();
  }

  Future<void> _clearExpiredLockIfNeeded() async {
    final lockUntil = _cachedLockUntil;
    if (lockUntil == null) return;
    if (lockUntil.isAfter(DateTime.now())) return;

    _cachedLockUntil = null;
    _cachedFailedAttempts = 0;
    await _authStorage.clearPinLock();
  }

  /// Generate a cryptographically secure random salt.
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hash a PIN using HMAC-SHA256 with the given salt.
  String _hashPin(String pin, String salt) {
    final key = utf8.encode(salt);
    final bytes = utf8.encode(pin);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Create and persist a new PIN (hashed + salted).
  Future<void> createPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _authStorage.savePinHash(hash: hash, salt: salt);
    await _authStorage.resetPinFailedAttempts();

    _cachedPinHash = hash;
    _cachedPinSalt = salt;
    _cachedFailedAttempts = 0;
    _cachedLockUntil = null;
    _pinMaterialLoaded = true;
    _lockStateLoaded = true;
  }

  /// Verify an entered PIN against the stored hash.
  ///
  /// Returns `true` if the PIN matches, `false` otherwise.
  /// Manages failed attempt tracking and lock-out logic.
  Future<bool> verifyPin(String pin) async {
    await warmUp();

    if (_cachedLockUntil != null) {
      return false;
    }

    final storedHash = _cachedPinHash;
    final storedSalt = _cachedPinSalt;

    if (storedHash == null || storedSalt == null) return false;

    final inputHash = _hashPin(pin, storedSalt);
    final isCorrect = inputHash == storedHash;

    if (isCorrect) {
      _cachedFailedAttempts = 0;
      _cachedLockUntil = null;
      // Fire-and-forget: clear counter in background so unlock is instant.
      unawaited(_authStorage.resetPinFailedAttempts());
    } else {
      final attempts = await _authStorage.incrementPinFailedAttempts(
        current: _cachedFailedAttempts,
      );
      _cachedFailedAttempts = attempts;

      if (attempts >= maxPinAttempts) {
        final lockUntil = DateTime.now().add(pinLockDuration);
        _cachedLockUntil = lockUntil;
        await _authStorage.setPinLockUntil(lockUntil);
      }
    }

    return isCorrect;
  }

  /// Whether the PIN entry is currently locked due to too many failures.
  Future<bool> isLocked() async {
    await _ensureLockStateLoaded();
    await _clearExpiredLockIfNeeded();
    return _cachedLockUntil != null;
  }

  /// Get remaining lock time. Returns [Duration.zero] if not locked.
  Future<Duration> getRemainingLockTime() async {
    await _ensureLockStateLoaded();
    await _clearExpiredLockIfNeeded();
    final lockUntil = _cachedLockUntil;
    if (lockUntil == null) return Duration.zero;
    final remaining = lockUntil.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get current number of failed attempts.
  Future<int> getFailedAttempts() async {
    await _ensureLockStateLoaded();
    return _cachedFailedAttempts ?? 0;
  }

  /// Whether a PIN has been set up.
  Future<bool> hasPin() async {
    return _authStorage.hasPin();
  }

  /// Change the PIN (requires old PIN verification first).
  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    await createPin(newPin);
    return true;
  }
}
