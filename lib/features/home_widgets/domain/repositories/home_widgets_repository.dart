import '../entities/home_widget_item.dart';

/// Abstract repository for Home Widget configuration.
/// In the future, this will be implemented by a remote data source.
abstract class HomeWidgetsRepository {
  /// Get all available widgets with their visibility and order.
  Future<List<HomeWidgetItem>> getWidgets();

  /// Get only visible widgets in display order.
  Future<List<HomeWidgetItem>> getVisibleWidgets();

  /// Update widget visibility.
  Future<void> setWidgetVisibility(String widgetId, bool isVisible);

  /// Reorder widgets.
  Future<void> reorderWidgets(List<String> orderedIds);

  /// Reset to default configuration.
  Future<List<HomeWidgetItem>> resetToDefaults();
}
