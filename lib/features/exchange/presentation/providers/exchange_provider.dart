import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/home_cache_service.dart';
import '../../data/exchange_service.dart';
import '../../domain/entities/exchange_data.dart';

// ─── Testable service provider ────────────────────────────────────────────────

final exchangeServiceProvider = Provider<ExchangeService>(
  (ref) => ExchangeService.instance,
);

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// State is nullable: [null] means no data available (offline + no cache).
class ExchangeNotifier extends StateNotifier<AsyncValue<ExchangeData?>> {
  ExchangeNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  final ExchangeService _service;
  bool _isFetching = false;

  Future<void> _init() async {
    // 1. Load from persistent cache — instant, no network.
    // loadExchangeJson returns null past the TTL, so non-null == fresh.
    final json = await HomeCacheService.loadExchangeJson();
    if (!mounted) return;
    if (json != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        state = AsyncValue.data(_fromJson(map));
        // 2. Fresh cache — skip the startup fetch entirely; the next fetch
        // happens when the TTL lapses or the user pulls to refresh.
        return;
      } catch (_) {}
    }

    // 3. No fresh cache: background network refresh.
    unawaited(_fetch());
  }

  Future<void> _fetch() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      _service.refresh(); // clear in-memory cache
      final data = await _service.fetchRates();
      if (!mounted) return;
      await HomeCacheService.saveExchangeJson(jsonEncode(_toJson(data)));
      state = AsyncValue.data(data);
    } catch (_) {
      if (!mounted) return;
      // If still loading (no cache), show null (no-data state in widget).
      if (state is AsyncLoading) state = const AsyncValue.data(null);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => _fetch();

  // ─── JSON helpers ──────────────────────────────────────────────────────

  static Map<String, dynamic> _toJson(ExchangeData e) => {
        'usdToKzt': e.usdToKzt,
        'eurToKzt': e.eurToKzt,
        if (e.rubToKzt != null) 'rubToKzt': e.rubToKzt,
        if (e.lastUpdated != null)
          'lastUpdated': e.lastUpdated!.toIso8601String(),
      };

  static ExchangeData _fromJson(Map<String, dynamic> j) => ExchangeData(
        usdToKzt: (j['usdToKzt'] as num).toDouble(),
        eurToKzt: (j['eurToKzt'] as num).toDouble(),
        rubToKzt: (j['rubToKzt'] as num?)?.toDouble(),
        lastUpdated: j['lastUpdated'] != null
            ? DateTime.tryParse(j['lastUpdated'] as String)
            : null,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final exchangeProvider =
    StateNotifierProvider<ExchangeNotifier, AsyncValue<ExchangeData?>>(
  (ref) => ExchangeNotifier(ref.watch(exchangeServiceProvider)),
);
