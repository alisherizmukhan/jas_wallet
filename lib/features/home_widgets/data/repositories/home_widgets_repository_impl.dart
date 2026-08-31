import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/home_widget_item.dart';
import '../../domain/repositories/home_widgets_repository.dart';

/// Device-local implementation of [HomeWidgetsRepository].
///
/// Widget visibility and order are a per-device layout preference, so they are
/// persisted in [SharedPreferences] (no backend / DB needed). On first launch,
/// or whenever the saved config is missing/corrupt, the [_defaults] layout is
/// used. New widget ids introduced in future app versions are merged in from
/// [_defaults] so they appear even for users with an older saved config.
class HomeWidgetsRepositoryImpl implements HomeWidgetsRepository {
  static const String _prefsKey = 'home_widgets_config_v1';

  /// In-memory cache; lazily hydrated from [SharedPreferences] on first access.
  List<HomeWidgetItem>? _widgets;

  /// Canonical default layout — single source of truth for first run and reset.
  List<HomeWidgetItem> _defaults() => const [
        HomeWidgetItem(id: HomeWidgetIds.stories, name: 'Stories', isVisible: true, order: 0),
        HomeWidgetItem(id: HomeWidgetIds.saltoCard, name: 'Salto Card', isVisible: true, order: 1),
        HomeWidgetItem(id: HomeWidgetIds.events, name: 'Events', isVisible: true, order: 2),
        HomeWidgetItem(id: HomeWidgetIds.weather, name: 'Weather', isVisible: true, order: 3),
        HomeWidgetItem(id: HomeWidgetIds.exchange, name: 'Exchange Rates', isVisible: true, order: 4),
        HomeWidgetItem(id: HomeWidgetIds.fintech, name: 'FinTech', isVisible: true, order: 5),
        HomeWidgetItem(id: HomeWidgetIds.fintechCards, name: 'Cards Carousel', isVisible: true, order: 6),
        HomeWidgetItem(id: HomeWidgetIds.fintechSpend, name: 'Spend this month', isVisible: true, order: 7),
        HomeWidgetItem(id: HomeWidgetIds.fintechWealth, name: 'Total Wealth', isVisible: true, order: 8),
        HomeWidgetItem(id: HomeWidgetIds.fintechPayments, name: 'Upcoming Payments', isVisible: true, order: 9),
        HomeWidgetItem(id: HomeWidgetIds.fintechPayees, name: 'Recent Payees', isVisible: true, order: 10),
        HomeWidgetItem(id: HomeWidgetIds.fintechHistory, name: 'Transaction History', isVisible: true, order: 11),
        HomeWidgetItem(id: HomeWidgetIds.tradingStocks, name: 'Stocks', isVisible: true, order: 12),
        HomeWidgetItem(id: HomeWidgetIds.tradingCrypto, name: 'Crypto', isVisible: true, order: 13),
        HomeWidgetItem(id: HomeWidgetIds.tradingPortfolio, name: 'Portfolio', isVisible: true, order: 14),
        HomeWidgetItem(id: HomeWidgetIds.tradingNews, name: 'Trading News', isVisible: false, order: 15),
        HomeWidgetItem(id: HomeWidgetIds.tradingMarket, name: 'Market Overview', isVisible: false, order: 16),
        HomeWidgetItem(id: HomeWidgetIds.course, name: 'Course', isVisible: true, order: 17),
        HomeWidgetItem(id: HomeWidgetIds.jobFinder, name: 'Job Finder', isVisible: true, order: 18),
        HomeWidgetItem(id: HomeWidgetIds.aiChat, name: 'AI-Chat', isVisible: false, order: 19),
        HomeWidgetItem(id: HomeWidgetIds.habits, name: 'Habits', isVisible: false, order: 20),
        HomeWidgetItem(id: HomeWidgetIds.library, name: 'Library', isVisible: false, order: 21),
        HomeWidgetItem(id: HomeWidgetIds.market, name: 'Market', isVisible: false, order: 22),
        HomeWidgetItem(id: HomeWidgetIds.blogNews, name: 'Blog & News', isVisible: false, order: 23),
        HomeWidgetItem(id: HomeWidgetIds.social, name: 'Social', isVisible: false, order: 24),
        HomeWidgetItem(id: HomeWidgetIds.rent, name: 'Rent', isVisible: false, order: 25),
        HomeWidgetItem(id: HomeWidgetIds.documents, name: 'Documents', isVisible: false, order: 26),
        HomeWidgetItem(id: HomeWidgetIds.forum, name: 'Forum', isVisible: false, order: 27),
      ];

  Future<void> _ensureLoaded() async {
    if (_widgets != null) return;
    _widgets = await _loadFromPrefs();
  }

  Future<List<HomeWidgetItem>> _loadFromPrefs() async {
    final defaults = _defaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return defaults;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return defaults;

      // id -> saved {isVisible, order}
      final saved = <String, ({bool isVisible, int order})>{};
      for (final entry in decoded) {
        if (entry is Map &&
            entry['id'] is String &&
            entry['v'] is bool &&
            entry['o'] is int) {
          saved[entry['id'] as String] =
              (isVisible: entry['v'] as bool, order: entry['o'] as int);
        }
      }
      if (saved.isEmpty) return defaults;

      // Merge: apply saved state to known widgets, keep new widgets from defaults.
      final merged = defaults.map((d) {
        final s = saved[d.id];
        return s == null
            ? d
            : d.copyWith(isVisible: s.isVisible, order: s.order);
      }).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return merged;
    } catch (_) {
      return defaults;
    }
  }

  Future<void> _persist() async {
    final widgets = _widgets;
    if (widgets == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = widgets
          .map((w) => {'id': w.id, 'v': w.isVisible, 'o': w.order})
          .toList();
      await prefs.setString(_prefsKey, jsonEncode(payload));
    } catch (_) {
      // Persistence is best-effort; in-memory state still reflects the change.
    }
  }

  @override
  Future<List<HomeWidgetItem>> getWidgets() async {
    await _ensureLoaded();
    return List.unmodifiable(_widgets!);
  }

  @override
  Future<List<HomeWidgetItem>> getVisibleWidgets() async {
    await _ensureLoaded();
    return _widgets!.where((w) => w.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<void> setWidgetVisibility(String widgetId, bool isVisible) async {
    await _ensureLoaded();
    // Stories is always visible and cannot be hidden
    if (widgetId == HomeWidgetIds.stories && !isVisible) return;

    _widgets = _widgets!.map((widget) {
      if (widget.id == widgetId) {
        return widget.copyWith(isVisible: isVisible);
      }
      return widget;
    }).toList();
    await _persist();
  }

  @override
  Future<void> reorderWidgets(List<String> orderedIds) async {
    await _ensureLoaded();
    final current = _widgets!;
    final reordered = <HomeWidgetItem>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final widget = current.firstWhere(
        (w) => w.id == orderedIds[i],
        orElse: () => throw Exception('Widget not found: ${orderedIds[i]}'),
      );
      reordered.add(widget.copyWith(order: i));
    }
    _widgets = reordered;
    await _persist();
  }

  @override
  Future<List<HomeWidgetItem>> resetToDefaults() async {
    _widgets = _defaults();
    await _persist();
    return List.unmodifiable(_widgets!);
  }
}
