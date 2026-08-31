import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/exchange_data.dart';

/// Fetches exchange rates from fawazahmed0/currency-api (jsDelivr CDN).
/// Singleton with in-memory caching — fetches once per session.
/// Includes Cloudflare fallback as recommended by the API docs.
class ExchangeService {
  ExchangeService._();

  @visibleForTesting
  ExchangeService.forTesting() : this._();

  static final instance = ExchangeService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const _primaryBase =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies';
  static const _fallbackBase =
      'https://latest.currency-api.pages.dev/v1/currencies';

  ExchangeData? _cache;
  Future<ExchangeData>? _pending;

  Future<ExchangeData> fetchRates() {
    if (_cache != null) return Future.value(_cache);
    return _pending ??= _fetch().then((data) {
      _cache = data;
      _pending = null;
      return data;
    }).catchError((Object e) {
      _pending = null;
      throw e;
    });
  }

  /// Fetch with primary URL, fall back to Cloudflare mirror on failure.
  Future<Map<String, dynamic>> _getWithFallback(String currency) async {
    try {
      final resp = await _dio
          .get<Map<String, dynamic>>('$_primaryBase/$currency.min.json');
      if (resp.data != null) return resp.data!;
    } catch (_) {
      // primary failed — try fallback
    }
    final resp = await _dio
        .get<Map<String, dynamic>>('$_fallbackBase/$currency.min.json');
    if (resp.data == null) throw Exception('Empty response for $currency');
    return resp.data!;
  }

  Future<ExchangeData> _fetch() async {
    // Fetch all three in parallel — each returns { "date": "...", "<code>": { "kzt": X } }
    final results = await Future.wait([
      _getWithFallback('usd'),
      _getWithFallback('eur'),
      _getWithFallback('rub'),
    ].map((f) => f.catchError((Object _) => <String, dynamic>{})));

    final usdData = results[0];
    final eurData = results[1];
    final rubData = results[2];

    final usdToKzt =
        ((usdData['usd'] as Map<String, dynamic>?)?['kzt'] as num?)
            ?.toDouble();
    final eurToKzt =
        ((eurData['eur'] as Map<String, dynamic>?)?['kzt'] as num?)
            ?.toDouble();
    final rubToKzt =
        ((rubData['rub'] as Map<String, dynamic>?)?['kzt'] as num?)
            ?.toDouble();

    if (usdToKzt == null || usdToKzt == 0 ||
        eurToKzt == null || eurToKzt == 0) {
      throw Exception('Missing required USD/EUR→KZT rates');
    }

    return ExchangeData(
      usdToKzt: usdToKzt,
      eurToKzt: eurToKzt,
      rubToKzt: rubToKzt != null && rubToKzt > 0 ? rubToKzt : null,
      lastUpdated: DateTime.now(),
    );
  }

  void refresh() {
    _cache = null;
    _pending = null;
  }
}
