import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';
import 'package:jaswallet_app/features/salto/data/repositories/salto_repository.dart';
import 'package:jaswallet_app/features/salto/data/services/salto_key_manager.dart';

import '../../helpers/fake_auth_storage.dart';

// ── Minimal fakes ──────────────────────────────────────────────────────────

/// FakeAuthStorageService extended with in-memory SALTO key storage.
class _SaltoFakeAuthStorage extends FakeAuthStorageService {
  String? _keyHex;
  DateTime? _storedAt;

  void seedKey({required String keyHex, required DateTime storedAt}) {
    _keyHex = keyHex;
    _storedAt = storedAt;
  }

  @override
  Future<String?> getSaltoDigitalKey() async {
    if (_keyHex == null || _storedAt == null) return null;
    const ttl = Duration(days: 7);
    if (DateTime.now().difference(_storedAt!) > ttl) return null;
    return _keyHex;
  }

  @override
  Future<DateTime?> getSaltoDigitalKeyStoredAt() async => _storedAt;
}

class _FakeSaltoRepository implements SaltoRepository {
  int getDigitalKeyCalls = 0;
  bool forceRefreshReceived = false;
  String? keyToReturn = 'aabbccdd';

  @override
  Future<String?> getDigitalKey({bool forceRefresh = false}) async {
    getDigitalKeyCalls++;
    forceRefreshReceived = forceRefresh;
    return keyToReturn;
  }

  @override
  Future<SaltoMobileStatus> getMobileStatus({CancelToken? cancelToken}) async =>
      throw UnimplementedError();

  @override
  Future<SaltoMobileStatus?> getCachedMobileStatus() async => null;

  @override
  Future<SaltoMobileStatus> activateMobileAccess() async =>
      throw UnimplementedError();
}

// ── Helpers ──────────────────────────────────────────────────────────────────

SaltoKeyManager _makeManager({
  _FakeSaltoRepository? repo,
  _SaltoFakeAuthStorage? storage,
}) {
  return SaltoKeyManager(
    repository: repo ?? _FakeSaltoRepository(),
    authStorage: storage ?? _SaltoFakeAuthStorage(),
  );
}

// ── SaltoKey.isValid ──────────────────────────────────────────────────────────

void main() {
  group('SaltoKey.isValid', () {
    test('true for a brand-new key', () {
      final issuedAt = DateTime.now();
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.isValid, isTrue);
    });

    test('true for a 6-day-old key', () {
      final issuedAt = DateTime.now().subtract(const Duration(days: 6));
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.isValid, isTrue);
    });

    test('false once the 7-day TTL has elapsed', () {
      final issuedAt = DateTime.now().subtract(const Duration(days: 7, seconds: 1));
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.isValid, isFalse);
    });
  });

  // ── SaltoKey.needsRefresh ───────────────────────────────────────────────────

  group('SaltoKey.needsRefresh', () {
    test('false when more than 2 days remain', () {
      final issuedAt = DateTime.now().subtract(const Duration(days: 4));
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.needsRefresh, isFalse);
    });

    test('true when fewer than 2 days remain', () {
      final issuedAt = DateTime.now().subtract(const Duration(days: 6));
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.needsRefresh, isTrue);
    });

    test('true for a nearly expired key (6 days + 20 hours old)', () {
      final issuedAt =
          DateTime.now().subtract(const Duration(days: 6, hours: 20));
      final key = SaltoKey(
        keyHex: 'abc',
        issuedAt: issuedAt,
        expiresAt: issuedAt.add(const Duration(days: 7)),
      );
      expect(key.needsRefresh, isTrue);
    });
  });

  // ── SaltoKeyManager.isKeyValid ────────────────────────────────────────────

  group('SaltoKeyManager.isKeyValid', () {
    late SaltoKeyManager manager;
    setUp(() => manager = _makeManager());

    test('valid when issued just now', () {
      expect(manager.isKeyValid(issuedAt: DateTime.now()), isTrue);
    });

    test('valid at 6 days old', () {
      final issuedAt = DateTime.now().subtract(const Duration(days: 6));
      expect(manager.isKeyValid(issuedAt: issuedAt), isTrue);
    });

    test('invalid when older than 7 days', () {
      final issuedAt =
          DateTime.now().subtract(const Duration(days: 7, seconds: 1));
      expect(manager.isKeyValid(issuedAt: issuedAt), isFalse);
    });
  });

  // ── SaltoKeyManager.needsBackgroundRefresh ────────────────────────────────

  group('SaltoKeyManager.needsBackgroundRefresh', () {
    late SaltoKeyManager manager;
    setUp(() => manager = _makeManager());

    test('false when 4 days old (3 days remaining)', () {
      expect(
        manager.needsBackgroundRefresh(
          issuedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        isFalse,
      );
    });

    test('true when 5+ days old (< 2 days remaining)', () {
      expect(
        manager.needsBackgroundRefresh(
          issuedAt: DateTime.now().subtract(const Duration(days: 5, hours: 1)),
        ),
        isTrue,
      );
    });

    test('false for a brand-new key', () {
      expect(
        manager.needsBackgroundRefresh(issuedAt: DateTime.now()),
        isFalse,
      );
    });
  });

  // ── SaltoKeyManager.loadCachedKey ─────────────────────────────────────────

  group('SaltoKeyManager.loadCachedKey', () {
    test('returns null when storage is empty', () async {
      final manager = _makeManager(storage: _SaltoFakeAuthStorage());
      expect(await manager.loadCachedKey(), isNull);
    });

    test('returns SaltoKey when storage has a fresh key', () async {
      final storage = _SaltoFakeAuthStorage();
      final issuedAt = DateTime.now().subtract(const Duration(days: 2));
      storage.seedKey(keyHex: 'deadbeef', storedAt: issuedAt);

      final manager = _makeManager(storage: storage);
      final key = await manager.loadCachedKey();

      expect(key, isNotNull);
      expect(key!.keyHex, 'deadbeef');
      expect(key.isValid, isTrue);
    });

    test('returns null when persisted key is expired (> 7 days old)', () async {
      final storage = _SaltoFakeAuthStorage();
      storage.seedKey(
        keyHex: 'oldkey',
        storedAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      final manager = _makeManager(storage: storage);
      final key = await manager.loadCachedKey();

      expect(key, isNull);
    });

    test('returned key has correct expiresAt (issuedAt + 7 days)', () async {
      final storage = _SaltoFakeAuthStorage();
      final issuedAt = DateTime.now().subtract(const Duration(days: 1));
      storage.seedKey(keyHex: 'abc', storedAt: issuedAt);

      final manager = _makeManager(storage: storage);
      final key = await manager.loadCachedKey();

      expect(
        key!.expiresAt.difference(issuedAt).inHours,
        closeTo(7 * 24, 1),
      );
    });
  });

  // ── SaltoKeyManager.prewarm ───────────────────────────────────────────────

  group('SaltoKeyManager.prewarm', () {
    test('fetches key from backend when no key is cached', () async {
      final repo = _FakeSaltoRepository();
      final manager = _makeManager(repo: repo, storage: _SaltoFakeAuthStorage());

      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.getDigitalKeyCalls, greaterThan(0));
    });

    test('still calls getDigitalKey when key is fresh (primes in-memory cache)',
        () async {
      final repo = _FakeSaltoRepository();
      final storage = _SaltoFakeAuthStorage();
      storage.seedKey(
        keyHex: 'freshkey',
        storedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final manager = _makeManager(repo: repo, storage: storage);
      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.getDigitalKeyCalls, greaterThan(0));
    });

    test('force-refreshes when key is nearly expired (needsRefresh == true)',
        () async {
      final repo = _FakeSaltoRepository();
      final storage = _SaltoFakeAuthStorage();
      storage.seedKey(
        keyHex: 'oldkey',
        storedAt: DateTime.now().subtract(const Duration(days: 6)),
      );

      final manager = _makeManager(repo: repo, storage: storage);
      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.forceRefreshReceived, isTrue);
    });

    test('silently ignores repository errors', () async {
      final repo = _FakeSaltoRepository()..keyToReturn = null;
      final manager = _makeManager(repo: repo, storage: _SaltoFakeAuthStorage());

      // Should not throw.
      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('force-refreshes (forceRefresh=true) when key is expired (> 7 days)',
        () async {
      final repo = _FakeSaltoRepository();
      final storage = _SaltoFakeAuthStorage();
      storage.seedKey(
        keyHex: 'expiredkey',
        storedAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      final manager = _makeManager(repo: repo, storage: storage);
      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.getDigitalKeyCalls, 1);
      expect(
        repo.forceRefreshReceived,
        isTrue,
        reason: 'Expired key must trigger forceRefresh=true so the backend '
            're-issues a fresh SALTO Ship key',
      );
    });

    test('uses forceRefresh=false when no key was ever stored', () async {
      final repo = _FakeSaltoRepository();
      final storage = _SaltoFakeAuthStorage(); // no seedKey call

      final manager = _makeManager(repo: repo, storage: storage);
      manager.prewarm();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.getDigitalKeyCalls, 1);
      expect(
        repo.forceRefreshReceived,
        isFalse,
        reason: 'Never-issued key should use forceRefresh=false (normal fetch)',
      );
    });
  });

  // ── SaltoKeyManager.refreshKey ────────────────────────────────────────────

  group('SaltoKeyManager.refreshKey', () {
    test('calls repository with forceRefresh=true', () async {
      final repo = _FakeSaltoRepository();
      final manager = _makeManager(repo: repo);

      await manager.refreshKey();

      expect(repo.getDigitalKeyCalls, 1);
      expect(repo.forceRefreshReceived, isTrue);
    });

    test('returns the key returned by the repository', () async {
      final repo = _FakeSaltoRepository()..keyToReturn = 'freshkey';
      final manager = _makeManager(repo: repo);

      final key = await manager.refreshKey();

      expect(key, 'freshkey');
    });

    test('returns null when repository has no key', () async {
      final repo = _FakeSaltoRepository()..keyToReturn = null;
      final manager = _makeManager(repo: repo);

      final key = await manager.refreshKey();

      expect(key, isNull);
    });
  });

  // ── Expiry-detection invariant ─────────────────────────────────────────────

  group('Expiry-detection invariant', () {
    test(
        'loadCachedKey returns null for expired key '
        'but storedAt is still readable (timestamp not deleted on TTL expiry)',
        () async {
      final storage = _SaltoFakeAuthStorage();
      storage.seedKey(
        keyHex: 'expiredkey',
        storedAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      final manager = _makeManager(storage: storage);

      final key = await manager.loadCachedKey();
      final storedAt = await storage.getSaltoDigitalKeyStoredAt();

      expect(key, isNull, reason: 'Key should be expired (8 days old)');
      expect(
        storedAt,
        isNotNull,
        reason: 'Timestamp must survive TTL expiry so prewarm can detect '
            '"was-expired" vs "never-issued"',
      );
    });

    test('loadCachedKey and storedAt are both null when key was never issued',
        () async {
      final storage = _SaltoFakeAuthStorage();
      final manager = _makeManager(storage: storage);

      final key = await manager.loadCachedKey();
      final storedAt = await storage.getSaltoDigitalKeyStoredAt();

      expect(key, isNull);
      expect(storedAt, isNull);
    });
  });
}
