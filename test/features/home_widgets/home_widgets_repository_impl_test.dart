import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/home_widgets/data/repositories/home_widgets_repository_impl.dart';
import 'package:jaswallet_app/features/home_widgets/domain/entities/home_widget_item.dart';

void main() {
  late HomeWidgetsRepositoryImpl repo;

  setUp(() {
    repo = HomeWidgetsRepositoryImpl();
  });

  // ── getWidgets ────────────────────────────────────────────────────────────

  group('HomeWidgetsRepositoryImpl.getWidgets', () {
    test('returns a non-empty list', () async {
      final widgets = await repo.getWidgets();
      expect(widgets, isNotEmpty);
    });

    test('includes Stories widget', () async {
      final widgets = await repo.getWidgets();
      expect(
        widgets.any((w) => w.id == HomeWidgetIds.stories),
        isTrue,
      );
    });

    test('Stories widget is initially visible', () async {
      final widgets = await repo.getWidgets();
      final stories = widgets.firstWhere((w) => w.id == HomeWidgetIds.stories);
      expect(stories.isVisible, isTrue);
    });

    test('includes weather, events, exchange widgets', () async {
      final widgets = await repo.getWidgets();
      final ids = widgets.map((w) => w.id).toSet();
      expect(ids, containsAll([
        HomeWidgetIds.weather,
        HomeWidgetIds.events,
        HomeWidgetIds.exchange,
      ]));
    });
  });

  // ── getVisibleWidgets ─────────────────────────────────────────────────────

  group('HomeWidgetsRepositoryImpl.getVisibleWidgets', () {
    test('returns only visible widgets', () async {
      final visible = await repo.getVisibleWidgets();
      expect(visible.every((w) => w.isVisible), isTrue);
    });

    test('returns widgets sorted by order', () async {
      final visible = await repo.getVisibleWidgets();
      for (var i = 0; i < visible.length - 1; i++) {
        expect(
          visible[i].order,
          lessThanOrEqualTo(visible[i + 1].order),
        );
      }
    });

    test('count is less than or equal to getWidgets count', () async {
      final all = await repo.getWidgets();
      final visible = await repo.getVisibleWidgets();
      expect(visible.length, lessThanOrEqualTo(all.length));
    });
  });

  // ── setWidgetVisibility ───────────────────────────────────────────────────

  group('HomeWidgetsRepositoryImpl.setWidgetVisibility', () {
    test('hides a visible widget', () async {
      await repo.setWidgetVisibility(HomeWidgetIds.weather, false);
      final widgets = await repo.getWidgets();
      final weather = widgets.firstWhere((w) => w.id == HomeWidgetIds.weather);
      expect(weather.isVisible, isFalse);
    });

    test('shows a hidden widget', () async {
      // tradingNews starts hidden
      await repo.setWidgetVisibility(HomeWidgetIds.tradingNews, true);
      final widgets = await repo.getWidgets();
      final w = widgets.firstWhere((w) => w.id == HomeWidgetIds.tradingNews);
      expect(w.isVisible, isTrue);
    });

    test('cannot hide Stories widget', () async {
      await repo.setWidgetVisibility(HomeWidgetIds.stories, false);
      final widgets = await repo.getWidgets();
      final stories = widgets.firstWhere((w) => w.id == HomeWidgetIds.stories);
      expect(stories.isVisible, isTrue);
    });

    test('does not affect other widgets', () async {
      await repo.setWidgetVisibility(HomeWidgetIds.weather, false);
      final widgets = await repo.getWidgets();
      final events = widgets.firstWhere((w) => w.id == HomeWidgetIds.events);
      expect(events.isVisible, isTrue);
    });
  });

  // ── reorderWidgets ────────────────────────────────────────────────────────

  group('HomeWidgetsRepositoryImpl.reorderWidgets', () {
    test('assigns sequential order values', () async {
      final initial = await repo.getWidgets();
      final ids = initial.map((w) => w.id).toList().reversed.toList();
      await repo.reorderWidgets(ids);

      final after = await repo.getWidgets();
      for (int i = 0; i < ids.length; i++) {
        final widget = after.firstWhere((w) => w.id == ids[i]);
        expect(widget.order, i);
      }
    });

    test('throws when an unknown id is provided', () async {
      expect(
        () => repo.reorderWidgets(['non_existent_widget_id']),
        throwsException,
      );
    });
  });

  // ── resetToDefaults ───────────────────────────────────────────────────────

  group('HomeWidgetsRepositoryImpl.resetToDefaults', () {
    test('restores widgets after visibility changes', () async {
      // course and jobFinder are visible by default in both initial and reset lists
      await repo.setWidgetVisibility(HomeWidgetIds.course, false);
      await repo.setWidgetVisibility(HomeWidgetIds.jobFinder, false);

      await repo.resetToDefaults();

      final widgets = await repo.getWidgets();
      final course = widgets.firstWhere((w) => w.id == HomeWidgetIds.course);
      final jobFinder = widgets.firstWhere((w) => w.id == HomeWidgetIds.jobFinder);
      expect(course.isVisible, isTrue);
      expect(jobFinder.isVisible, isTrue);
    });

    test('returns a non-empty list', () async {
      final result = await repo.resetToDefaults();
      expect(result, isNotEmpty);
    });

    test('Stories widget remains visible after reset', () async {
      final result = await repo.resetToDefaults();
      final stories = result.firstWhere((w) => w.id == HomeWidgetIds.stories);
      expect(stories.isVisible, isTrue);
    });
  });
}
