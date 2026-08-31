import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/pin/data/pin_storage_service.dart';

import '../../helpers/fake_auth_storage.dart';

void main() {
  late FakeAuthStorageService storage;
  late PinStorageService service;

  setUp(() {
    storage = FakeAuthStorageService();
    service = PinStorageService(storage);
  });

  // ── createPin / verifyPin ──────────────────────────────────────────────────

  group('PinStorageService — create and verify', () {
    test('verifyPin returns true for correct PIN after createPin', () async {
      await service.createPin('1234');
      expect(await service.verifyPin('1234'), isTrue);
    });

    test('verifyPin returns false for wrong PIN', () async {
      await service.createPin('1234');
      expect(await service.verifyPin('9999'), isFalse);
    });

    test('raw PIN is never persisted in storage', () async {
      await service.createPin('5678');
      final hash = await storage.getPinHash();
      final salt = await storage.getPinSalt();
      expect(hash, isNotNull);
      expect(salt, isNotNull);
      expect(hash, isNot(contains('5678')));
    });

    test('hasPin returns true after createPin', () async {
      expect(await service.hasPin(), isFalse);
      await service.createPin('0000');
      expect(await service.hasPin(), isTrue);
    });

    test('failed attempts reset to 0 after createPin', () async {
      await service.createPin('1111');
      await service.verifyPin('wrong');
      await service.verifyPin('wrong');
      expect(await service.getFailedAttempts(), 2);

      // Creating a new PIN resets everything
      await service.createPin('2222');
      expect(await service.getFailedAttempts(), 0);
    });
  });

  // ── failed attempts ───────────────────────────────────────────────────────

  group('PinStorageService — failed attempts', () {
    test('failed attempts increment on each wrong PIN', () async {
      await service.createPin('1234');

      await service.verifyPin('wrong');
      expect(await service.getFailedAttempts(), 1);

      await service.verifyPin('wrong');
      expect(await service.getFailedAttempts(), 2);
    });

    test('failed attempts reset to 0 on correct PIN', () async {
      await service.createPin('1234');
      await service.verifyPin('bad');
      await service.verifyPin('bad');
      expect(await service.getFailedAttempts(), 2);

      await service.verifyPin('1234');
      expect(await service.getFailedAttempts(), 0);
    });

    test('locked after maxPinAttempts wrong entries', () async {
      await service.createPin('1234');

      for (var i = 0; i < maxPinAttempts; i++) {
        await service.verifyPin('bad');
      }

      expect(await service.isLocked(), isTrue);
    });

    test('verifyPin returns false immediately when locked', () async {
      await service.createPin('1234');

      for (var i = 0; i < maxPinAttempts; i++) {
        await service.verifyPin('bad');
      }

      // Even correct PIN returns false while locked
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('getFailedAttempts returns current count', () async {
      await service.createPin('0000');
      expect(await service.getFailedAttempts(), 0);

      await service.verifyPin('wrong');
      await service.verifyPin('wrong');
      await service.verifyPin('wrong');
      expect(await service.getFailedAttempts(), 3);
    });
  });

  // ── lock state ────────────────────────────────────────────────────────────

  group('PinStorageService — lock state', () {
    test('isLocked returns false when not locked', () async {
      await service.createPin('1234');
      expect(await service.isLocked(), isFalse);
    });

    test('getRemainingLockTime returns Duration.zero when not locked', () async {
      await service.createPin('1234');
      expect(await service.getRemainingLockTime(), Duration.zero);
    });

    test('getRemainingLockTime returns positive duration when locked', () async {
      await service.createPin('1234');

      for (var i = 0; i < maxPinAttempts; i++) {
        await service.verifyPin('bad');
      }

      final remaining = await service.getRemainingLockTime();
      expect(remaining, greaterThan(Duration.zero));
    });
  });

  // ── changePin ─────────────────────────────────────────────────────────────

  group('PinStorageService — changePin', () {
    test('changePin succeeds with correct old PIN and new PIN verifies', () async {
      await service.createPin('1234');
      final result = await service.changePin('1234', '5678');
      expect(result, isTrue);
      expect(await service.verifyPin('5678'), isTrue);
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('changePin fails with wrong old PIN', () async {
      await service.createPin('1234');
      final result = await service.changePin('9999', '5678');
      expect(result, isFalse);
      // Original PIN is still valid
      expect(await service.verifyPin('1234'), isTrue);
    });
  });

  // ── warmUp ────────────────────────────────────────────────────────────────

  group('PinStorageService — warmUp', () {
    test('warmUp completes without error', () async {
      await service.createPin('1234');
      // warmUp can be called multiple times safely
      await service.warmUp();
      await service.warmUp();
      // PIN still verifies after warmUp
      expect(await service.verifyPin('1234'), isTrue);
    });
  });
}
