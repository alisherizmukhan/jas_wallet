import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/exchange/domain/entities/exchange_data.dart';

void main() {
  // ── ExchangeData construction ─────────────────────────────────────────────

  group('ExchangeData', () {
    test('stores required fields correctly', () {
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
      );
      expect(data.usdToKzt, 450.5);
      expect(data.eurToKzt, 490.0);
    });

    test('rubToKzt is null by default', () {
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
      );
      expect(data.rubToKzt, isNull);
    });

    test('stores rubToKzt when provided', () {
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
        rubToKzt: 5.1,
      );
      expect(data.rubToKzt, 5.1);
    });

    test('lastUpdated is null by default', () {
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
      );
      expect(data.lastUpdated, isNull);
    });

    test('stores lastUpdated when provided', () {
      final timestamp = DateTime(2024, 6, 1, 12);
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
        lastUpdated: timestamp,
      );
      expect(data.lastUpdated, timestamp);
    });

    test('accepts zero rubToKzt (edge case)', () {
      // The service filters out 0 values before construction,
      // but the entity itself accepts 0
      final data = ExchangeData(
        usdToKzt: 450.5,
        eurToKzt: 490.0,
        rubToKzt: 0.0,
      );
      expect(data.rubToKzt, 0.0);
    });
  });
}
