import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/home_widgets/domain/entities/home_widget_item.dart';
import 'package:jaswallet_app/features/home_widgets/domain/repositories/home_widgets_repository.dart';
import 'package:jaswallet_app/features/home_widgets/presentation/providers/home_widgets_provider.dart';

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeHomeWidgetsRepository implements HomeWidgetsRepository {
  _FakeHomeWidgetsRepository({
    required List<HomeWidgetItem> initialWidgets,
    this.shouldThrowOnWrite = false,
  }) : _widgets = List<HomeWidgetItem>.from(initialWidgets);

  List<HomeWidgetItem> _widgets;
  final bool shouldThrowOnWrite;

  @override
  Future<List<HomeWidgetItem>> getWidgets() async => List.from(_widgets);

  @override
  Future<List<HomeWidgetItem>> getVisibleWidgets() async =>
      _widgets.where((w) => w.isVisible).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  @override
  Future<void> setWidgetVisibility(String widgetId, bool isVisible) async {
    if (shouldThrowOnWrite) throw Exception('write failed');
    _widgets = _widgets.map((w) {
      if (w.id == widgetId) return w.copyWith(isVisible: isVisible);
      return w;
    }).toList();
  }

  @override
  Future<void> reorderWidgets(List<String> orderedIds) async {
    if (shouldThrowOnWrite) throw Exception('write failed');
    final reordered = <HomeWidgetItem>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final w = _widgets.firstWhere((x) => x.id == orderedIds[i]);
      reordered.add(w.copyWith(order: i));
    }
    _widgets = reordered;
  }

  @override
  Future<List<HomeWidgetItem>> resetToDefaults() async => _widgets;
}

// ── Helpers ────────────────────────────────────────────────────────────────

List<HomeWidgetItem> _defaultWidgets() => [
  const HomeWidgetItem(id: HomeWidgetIds.stories, name: 'Stories', isVisible: true, order: 0),
  const HomeWidgetItem(id: HomeWidgetIds.weather, name: 'Weather', isVisible: true, order: 1),
  const HomeWidgetItem(id: HomeWidgetIds.events, name: 'Events', isVisible: false, order: 2),
];

/// Creates a container, triggers notifier initialization, and waits for load.
Future<ProviderContainer> _makeContainer({
  required List<HomeWidgetItem> widgets,
  bool throwOnWrite = false,
}) async {
  final repo = _FakeHomeWidgetsRepository(
    initialWidgets: widgets,
    shouldThrowOnWrite: throwOnWrite,
  );
  final container = ProviderContainer(
    overrides: [homeWidgetsRepositoryProvider.overrideWithValue(repo)],
  );
  // Read to trigger lazy notifier creation + _loadDataCacheFirst()
  container.read(homeWidgetsProvider);
  // Yield so the micro-task queue drains and _doLoadData() sets state
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return container;
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  // ── Initial load ──────────────────────────────────────────────────────────

  group('HomeWidgetsNotifier — initial load', () {
    test('transitions from loading to data', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      final state = container.read(homeWidgetsProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.length, 3);
    });

    test('loaded data contains expected widget IDs', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      final ids = container.read(homeWidgetsProvider).value!.map((w) => w.id);
      expect(ids, containsAll([
        HomeWidgetIds.stories,
        HomeWidgetIds.weather,
        HomeWidgetIds.events,
      ]));
    });
  });

  // ── toggleVisibility ──────────────────────────────────────────────────────

  group('HomeWidgetsNotifier.toggleVisibility', () {
    test('hides a visible widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      await container
          .read(homeWidgetsProvider.notifier)
          .toggleVisibility(HomeWidgetIds.weather);

      final weather = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.weather);
      expect(weather.isVisible, isFalse);
    });

    test('shows a hidden widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      // Events starts hidden
      await container
          .read(homeWidgetsProvider.notifier)
          .toggleVisibility(HomeWidgetIds.events);

      final events = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.events);
      expect(events.isVisible, isTrue);
    });

    test('Stories widget cannot be toggled off', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      await container
          .read(homeWidgetsProvider.notifier)
          .toggleVisibility(HomeWidgetIds.stories);

      final stories = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.stories);
      expect(stories.isVisible, isTrue);
    });

    test('reverts optimistic update on write error', () async {
      final container = await _makeContainer(
        widgets: _defaultWidgets(),
        throwOnWrite: true,
      );
      addTearDown(container.dispose);

      await container
          .read(homeWidgetsProvider.notifier)
          .toggleVisibility(HomeWidgetIds.weather);

      // Should revert back to original (visible=true) since write threw
      final weather = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.weather);
      expect(weather.isVisible, isTrue);
    });
  });

  // ── setVisibility ─────────────────────────────────────────────────────────

  group('HomeWidgetsNotifier.setVisibility', () {
    test('sets hidden widget to visible', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      await container
          .read(homeWidgetsProvider.notifier)
          .setVisibility(HomeWidgetIds.events, true);

      final events = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.events);
      expect(events.isVisible, isTrue);
    });

    test('cannot hide Stories widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      await container
          .read(homeWidgetsProvider.notifier)
          .setVisibility(HomeWidgetIds.stories, false);

      final stories = container
          .read(homeWidgetsProvider)
          .value!
          .firstWhere((w) => w.id == HomeWidgetIds.stories);
      expect(stories.isVisible, isTrue);
    });
  });

  // ── reorder ───────────────────────────────────────────────────────────────

  group('HomeWidgetsNotifier.reorder', () {
    test('moves item from first to second position', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      // Items: [stories(0), weather(1), events(2)]
      // Moving index 0 to position 2 (adjusted → 1)
      await container
          .read(homeWidgetsProvider.notifier)
          .reorder(0, 2);

      final after = container.read(homeWidgetsProvider).value!;
      // weather should now be first, stories second
      expect(after[0].id, HomeWidgetIds.weather);
      expect(after[1].id, HomeWidgetIds.stories);
    });

    test('reverts on write error', () async {
      final container = await _makeContainer(
        widgets: _defaultWidgets(),
        throwOnWrite: true,
      );
      addTearDown(container.dispose);

      final before = container.read(homeWidgetsProvider).value!;
      final originalOrder = before.map((w) => w.id).toList();

      await container.read(homeWidgetsProvider.notifier).reorder(0, 2);

      final after = container.read(homeWidgetsProvider).value!;
      expect(after.map((w) => w.id).toList(), originalOrder);
    });
  });

  // ── isVisible ─────────────────────────────────────────────────────────────

  group('HomeWidgetsNotifier.isVisible', () {
    test('returns true for visible widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      expect(
        container.read(homeWidgetsProvider.notifier).isVisible(HomeWidgetIds.weather),
        isTrue,
      );
    });

    test('returns false for hidden widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      expect(
        container.read(homeWidgetsProvider.notifier).isVisible(HomeWidgetIds.events),
        isFalse,
      );
    });

    test('returns false for unknown widget ID', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      expect(
        container.read(homeWidgetsProvider.notifier).isVisible('non_existent'),
        isFalse,
      );
    });
  });

  // ── visibleWidgets ────────────────────────────────────────────────────────

  group('HomeWidgetsNotifier.visibleWidgets', () {
    test('returns only visible widgets sorted by order', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      final visible = container.read(homeWidgetsProvider.notifier).visibleWidgets;

      // stories (order 0) and weather (order 1) are visible; events is hidden
      expect(visible.length, 2);
      expect(visible[0].id, HomeWidgetIds.stories);
      expect(visible[1].id, HomeWidgetIds.weather);
    });
  });

  // ── isWidgetVisibleProvider ───────────────────────────────────────────────

  group('isWidgetVisibleProvider', () {
    test('returns true for visible widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      expect(
        container.read(isWidgetVisibleProvider(HomeWidgetIds.weather)),
        isTrue,
      );
    });

    test('returns false for hidden widget', () async {
      final container = await _makeContainer(widgets: _defaultWidgets());
      addTearDown(container.dispose);

      expect(
        container.read(isWidgetVisibleProvider(HomeWidgetIds.events)),
        isFalse,
      );
    });
  });
}
