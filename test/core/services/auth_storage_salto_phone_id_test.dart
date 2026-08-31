import 'dart:async';

import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/core/services/auth_storage_service.dart';

/// In-memory [FlutterSecureStoragePlatform] that deterministically
/// reproduces the concurrent-first-read race at the STORAGE layer, while
/// remaining correct to use against BOTH the buggy and the fixed
/// [AuthStorageService.getOrCreateSaltoMobilePhoneId] implementation.
///
/// Any [read] callers that arrive within a short grace window of each
/// other are held at a barrier and released together, so each one
/// observes storage in the exact state it was in before *any* of them
/// could have written — the real first-run race between (for example) the
/// status fetch and an activation attempt reading `mobile_phone_id`
/// concurrently.
///
/// The grace-window release (rather than requiring an exact reader count)
/// is what lets the *same* fake correctly exercise both possibilities:
/// pre-fix, two high-level callers each reach [read] and race; post-fix,
/// only ONE high-level caller ever reaches [read] at all (the second
/// instead awaits the first's in-flight future) — this fake must not hang
/// waiting for a second reader that the fix correctly prevents from ever
/// arriving.
class _RacyFakeSecureStoragePlatform extends FlutterSecureStoragePlatform {
  final Map<String, String> data = {};
  int readCalls = 0;
  int writeCalls = 0;

  Completer<void>? _barrier;

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    readCalls++;
    // Snapshot the value at the moment this reader ARRIVES, not after it
    // is released. Empirically, once multiple readers are parked on a
    // shared completer, Dart does not resume their continuations in a
    // fair/interleaved way — one reader's entire read-then-write chain can
    // run to completion before another already-waiting reader's
    // continuation is even scheduled. Reading `data[key]` fresh at
    // release time would then flakily observe a write that landed *while*
    // this reader was parked, masking the exact race being tested. All
    // readers that have arrived so far are guaranteed to have done so
    // before any of them could have written (writes only ever happen
    // after a full round trip back through the caller), so the snapshot
    // taken here is always pre-write for every concurrent caller.
    final snapshot = data[key];
    _barrier ??= Completer<void>();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 40), () {
        if (!_barrier!.isCompleted) _barrier!.complete();
      }),
    );
    await _barrier!.future;
    // Released — either because every reader that was ever going to show
    // up within the grace window has arrived, or the window simply
    // elapsed (the fixed code's expected path, where no second reader
    // ever arrives).
    return snapshot;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    writeCalls++;
    data[key] = value;
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      data.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async =>
      data.remove(key);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async =>
      data.clear();

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      data;
}

void main() {
  group('AuthStorageService.getOrCreateSaltoMobilePhoneId — concurrency', () {
    test('two callers racing on a fresh install receive the SAME id, not '
        'two independently-generated ones', () async {
      final fakePlatform = _RacyFakeSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = fakePlatform;
      final storage = AuthStorageService();

      final results = await Future.wait([
        storage.getOrCreateSaltoMobilePhoneId(),
        storage.getOrCreateSaltoMobilePhoneId(),
      ]);

      expect(results[0], results[1]);
      expect(results[0], isNotEmpty);
    });

    test('only ONE id is ever persisted despite both callers racing', () async {
      final fakePlatform = _RacyFakeSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = fakePlatform;
      final storage = AuthStorageService();

      await Future.wait([
        storage.getOrCreateSaltoMobilePhoneId(),
        storage.getOrCreateSaltoMobilePhoneId(),
      ]);

      // The de-duplication guard means the second caller never reaches
      // read()/write() at all — it awaits the first caller's in-flight
      // future instead. Without the guard this would be 2.
      expect(fakePlatform.writeCalls, 1);
    });

    test('three-way race still converges on a single persisted id', () async {
      final fakePlatform = _RacyFakeSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = fakePlatform;
      final storage = AuthStorageService();

      final results = await Future.wait([
        storage.getOrCreateSaltoMobilePhoneId(),
        storage.getOrCreateSaltoMobilePhoneId(),
        storage.getOrCreateSaltoMobilePhoneId(),
      ]);

      expect(results.toSet(), hasLength(1));
      expect(fakePlatform.writeCalls, 1);
    });

    test('subsequent calls after the id exists reuse the persisted value '
        'without any further write', () async {
      final fakePlatform = _RacyFakeSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = fakePlatform;
      final storage = AuthStorageService();

      final first = await storage.getOrCreateSaltoMobilePhoneId();
      final writesAfterFirst = fakePlatform.writeCalls;

      final second = await storage.getOrCreateSaltoMobilePhoneId();
      final third = await storage.getOrCreateSaltoMobilePhoneId();

      expect(second, first);
      expect(third, first);
      expect(fakePlatform.writeCalls, writesAfterFirst);
    });

    test('the in-flight guard clears after completion — a later call reads '
        'fresh rather than hanging on a long-finished future', () async {
      final fakePlatform = _RacyFakeSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = fakePlatform;
      final storage = AuthStorageService();

      final first = await storage.getOrCreateSaltoMobilePhoneId();
      final second = await storage.getOrCreateSaltoMobilePhoneId();

      expect(second, first);
    });
  });
}
