import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/home_widgets_repository_impl.dart';
import '../../domain/entities/home_widget_item.dart';
import '../../domain/repositories/home_widgets_repository.dart';

/// Provider for home widgets repository
final homeWidgetsRepositoryProvider = Provider<HomeWidgetsRepository>((ref) {
  return HomeWidgetsRepositoryImpl();
});

/// Provider for managing home widget visibility and order
/// Implements cache-first loading to prevent loading spinners.
class HomeWidgetsNotifier extends StateNotifier<AsyncValue<List<HomeWidgetItem>>> {
  HomeWidgetsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadDataCacheFirst();
  }

  final HomeWidgetsRepository _repository;
  
  /// Memory cache of last loaded widgets
  List<HomeWidgetItem>? _cachedWidgets;
  Future<void>? _inFlightLoad;

  /// Load data with cache-first strategy:
  /// 1. If cache exists, show it immediately (no loading state)
  /// 2. Fetch fresh data in background
  /// 3. Update state only if data changed
  Future<void> _loadDataCacheFirst() async {
    // If we have cached data, use it immediately (no loading spinner)
    if (_cachedWidgets != null) {
      state = AsyncValue.data(_cachedWidgets!);
      // Still refresh in background
      _refreshInBackground();
      return;
    }

    // No cache - show loading and fetch
    await _loadData();
  }

  Future<void> _loadData() async {
    // Prevent duplicate requests
    if (_inFlightLoad != null) {
      return _inFlightLoad;
    }

    _inFlightLoad = _doLoadData();
    try {
      await _inFlightLoad;
    } finally {
      _inFlightLoad = null;
    }
  }

  Future<void> _doLoadData() async {
    try {
      final data = await _repository.getWidgets();
      _cachedWidgets = data;
      state = AsyncValue.data(data);
    } catch (e, st) {
      // Only show error if no cached data
      if (_cachedWidgets != null) {
        state = AsyncValue.data(_cachedWidgets!);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _refreshInBackground() {
    // Fire and forget background refresh
    _repository.getWidgets().then((data) {
      if (!mounted) return;
      if (!_areWidgetsEqual(_cachedWidgets, data)) {
        _cachedWidgets = data;
        state = AsyncValue.data(data);
      }
    }).catchError((_) {
      // Silently ignore background refresh errors
    });
  }

  bool _areWidgetsEqual(List<HomeWidgetItem>? a, List<HomeWidgetItem>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || 
          a[i].isVisible != b[i].isVisible || 
          a[i].order != b[i].order) {
        return false;
      }
    }
    return true;
  }

  /// Toggle visibility of a widget (Stories cannot be hidden)
  Future<void> toggleVisibility(String widgetId) async {
    // Stories is always visible and cannot be toggled
    if (widgetId == HomeWidgetIds.stories) return;
    
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = currentList.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: !widget.isVisible);
      }
      return widget;
    }).toList();

    // Optimistic update
    state = AsyncValue.data(updated);

    try {
      await _repository.setWidgetVisibility(widgetId, !currentList.firstWhere((w) => w.id == widgetId).isVisible);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
    }
  }

  /// Set visibility of a widget (Stories cannot be hidden)
  Future<void> setVisibility(String widgetId, bool isVisible) async {
    // Stories is always visible and cannot be hidden
    if (widgetId == HomeWidgetIds.stories && !isVisible) return;
    
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = currentList.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: isVisible);
      }
      return widget;
    }).toList();

    // Optimistic update
    state = AsyncValue.data(updated);

    try {
      await _repository.setWidgetVisibility(widgetId, isVisible);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
    }
  }

  /// Reorder widgets
  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    var adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }
    final mutableList = List<HomeWidgetItem>.from(currentList);
    final item = mutableList.removeAt(oldIndex);
    mutableList.insert(adjustedNewIndex, item);
    
    // Update order values
    final updated = mutableList.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();
    
    // Optimistic update
    state = AsyncValue.data(updated);
    
    try {
      await _repository.reorderWidgets(updated.map((w) => w.id).toList());
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
    }
  }

  /// Reorder only the five supported top-level widgets; sub-widgets are unaffected.
  /// [oldIndex] and [newIndex] are already-adjusted (post-removal) list indices.
  Future<void> reorderTopLevel(int oldIndex, int newIndex) async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    const supported = {
      HomeWidgetIds.stories,
      HomeWidgetIds.saltoCard,
      HomeWidgetIds.events,
      HomeWidgetIds.weather,
      HomeWidgetIds.exchange,
    };

    final topLevel = currentList
        .where((w) => supported.contains(w.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final rest = currentList
        .where((w) => !supported.contains(w.id))
        .toList();

    if (oldIndex < 0 || oldIndex >= topLevel.length) return;

    final item = topLevel.removeAt(oldIndex);
    topLevel.insert(newIndex.clamp(0, topLevel.length), item);

    final updatedTopLevel = topLevel.asMap().entries.map((e) {
      return e.value.copyWith(order: e.key);
    }).toList();

    final updated = [...updatedTopLevel, ...rest];
    state = AsyncValue.data(updated);

    try {
      await _repository.reorderWidgets(updated.map((w) => w.id).toList());
    } catch (e) {
      state = AsyncValue.data(currentList);
    }
  }

  /// Check if a widget is visible
  bool isVisible(String widgetId) {
    return state.valueOrNull?.firstWhere(
      (w) => w.id == widgetId,
      orElse: () => const HomeWidgetItem(id: '', name: '', isVisible: false, order: 0),
    ).isVisible ?? false;
  }

  /// Get visible widgets sorted by order
  List<HomeWidgetItem> get visibleWidgets {
    final list = state.valueOrNull ?? [];
    return list.where((w) => w.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}

/// Provider for home widgets state
final homeWidgetsProvider = StateNotifierProvider<HomeWidgetsNotifier, AsyncValue<List<HomeWidgetItem>>>((ref) {
  return HomeWidgetsNotifier(ref.watch(homeWidgetsRepositoryProvider));
});

/// Provider to check if a specific widget is visible
final isWidgetVisibleProvider = Provider.family<bool, String>((ref, widgetId) {
  final widgetsAsync = ref.watch(homeWidgetsProvider);
  return widgetsAsync.valueOrNull?.firstWhere(
    (w) => w.id == widgetId,
    orElse: () => const HomeWidgetItem(id: '', name: '', isVisible: false, order: 0),
  ).isVisible ?? false;
});