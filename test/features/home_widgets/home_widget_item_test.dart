import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/home_widgets/domain/entities/home_widget_item.dart';

void main() {
  // ── HomeWidgetItem.copyWith ───────────────────────────────────────────────

  group('HomeWidgetItem.copyWith', () {
    const base = HomeWidgetItem(
      id: 'weather',
      name: 'Weather',
      isVisible: true,
      order: 3,
    );

    test('returns identical item when no args passed', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.name, base.name);
      expect(copy.isVisible, base.isVisible);
      expect(copy.order, base.order);
    });

    test('replaces isVisible only', () {
      final copy = base.copyWith(isVisible: false);
      expect(copy.isVisible, isFalse);
      expect(copy.id, base.id);
      expect(copy.order, base.order);
    });

    test('replaces order only', () {
      final copy = base.copyWith(order: 99);
      expect(copy.order, 99);
      expect(copy.id, base.id);
      expect(copy.isVisible, base.isVisible);
    });

    test('replaces all fields', () {
      final copy = base.copyWith(
        id: 'events',
        name: 'Events',
        isVisible: false,
        order: 7,
      );
      expect(copy.id, 'events');
      expect(copy.name, 'Events');
      expect(copy.isVisible, isFalse);
      expect(copy.order, 7);
    });
  });

  // ── HomeWidgetIds static helpers ──────────────────────────────────────────

  group('HomeWidgetIds.isFintechSubWidget', () {
    test('returns true for all fintech sub-widget IDs', () {
      for (final id in HomeWidgetIds.fintechSubWidgets) {
        expect(HomeWidgetIds.isFintechSubWidget(id), isTrue, reason: id);
      }
    });

    test('returns false for non-fintech IDs', () {
      expect(HomeWidgetIds.isFintechSubWidget(HomeWidgetIds.stories), isFalse);
      expect(HomeWidgetIds.isFintechSubWidget(HomeWidgetIds.weather), isFalse);
      expect(HomeWidgetIds.isFintechSubWidget(HomeWidgetIds.events), isFalse);
      expect(HomeWidgetIds.isFintechSubWidget(HomeWidgetIds.jobFinder), isFalse);
    });

    test('returns false for trading sub-widget IDs', () {
      for (final id in HomeWidgetIds.tradingSubWidgets) {
        expect(HomeWidgetIds.isFintechSubWidget(id), isFalse, reason: id);
      }
    });
  });

  group('HomeWidgetIds.isTradingSubWidget', () {
    test('returns true for all trading sub-widget IDs', () {
      for (final id in HomeWidgetIds.tradingSubWidgets) {
        expect(HomeWidgetIds.isTradingSubWidget(id), isTrue, reason: id);
      }
    });

    test('returns false for fintech sub-widget IDs', () {
      for (final id in HomeWidgetIds.fintechSubWidgets) {
        expect(HomeWidgetIds.isTradingSubWidget(id), isFalse, reason: id);
      }
    });

    test('returns false for unrelated IDs', () {
      expect(HomeWidgetIds.isTradingSubWidget(HomeWidgetIds.stories), isFalse);
      expect(HomeWidgetIds.isTradingSubWidget(HomeWidgetIds.exchange), isFalse);
    });
  });

  group('HomeWidgetIds.isAnyFintechSubWidget', () {
    test('returns true for fintech sub-widgets', () {
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.fintechCards),
        isTrue,
      );
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.fintechHistory),
        isTrue,
      );
    });

    test('returns true for trading sub-widgets', () {
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.tradingStocks),
        isTrue,
      );
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.tradingCrypto),
        isTrue,
      );
    });

    test('returns false for top-level widgets', () {
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.fintech),
        isFalse,
      );
      expect(
        HomeWidgetIds.isAnyFintechSubWidget(HomeWidgetIds.stories),
        isFalse,
      );
    });
  });

  // ── HomeWidgetIds list coverage ───────────────────────────────────────────

  group('HomeWidgetIds lists', () {
    test('fintechSubWidgets contains exactly 6 items', () {
      expect(HomeWidgetIds.fintechSubWidgets.length, 6);
    });

    test('tradingSubWidgets contains exactly 5 items', () {
      expect(HomeWidgetIds.tradingSubWidgets.length, 5);
    });

    test('fintechSubWidgets and tradingSubWidgets have no overlap', () {
      final overlap = HomeWidgetIds.fintechSubWidgets
          .toSet()
          .intersection(HomeWidgetIds.tradingSubWidgets.toSet());
      expect(overlap, isEmpty);
    });
  });
}
