import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/story.dart';

/// Persistent local state for story view tracking.
class StoryStorageService {
  static const String _watchedKeyPrefix = 'stories_watched_';
  static const String _defaultViewerScope = 'guest';

  static StoryStorageService? _instance;
  static StoryStorageService get instance =>
      _instance ??= StoryStorageService._();

  StoryStorageService._();

  SharedPreferences? _prefs;
  bool _initialized = false;
  Future<void>? _initFuture;
  String _viewerScope = _defaultViewerScope;
  Set<String> _viewedIds = {};

  String get _watchedKey => '$_watchedKeyPrefix$_viewerScope';

  Future<void> init({String? viewerId}) async {
    if (_initialized) {
      await setViewerScope(viewerId);
      return;
    }
    final inFlight = _initFuture;
    if (inFlight != null) return inFlight;
    _initFuture = _doInit(viewerId);
    return _initFuture!;
  }

  Future<void> _doInit(String? viewerId) async {
    _prefs = await SharedPreferences.getInstance();
    _viewerScope = _normalizeViewerScope(viewerId);
    _loadViewedForCurrentViewer();
    _initialized = true;
  }

  Future<void> setViewerScope(String? viewerId) async {
    if (!_initialized) return;
    final nextScope = _normalizeViewerScope(viewerId);
    if (nextScope == _viewerScope) return;
    _viewerScope = nextScope;
    _loadViewedForCurrentViewer();
  }

  String _normalizeViewerScope(String? viewerId) {
    final trimmed = viewerId?.trim() ?? '';
    return trimmed.isEmpty ? _defaultViewerScope : trimmed;
  }

  void _loadViewedForCurrentViewer() {
    final raw = _prefs?.getStringList(_watchedKey);
    _viewedIds = raw != null ? raw.toSet() : {};
  }

  Future<void> _persistViewed() async {
    await _prefs?.setStringList(_watchedKey, _viewedIds.toList());
  }

  Future<void> markViewed(String storyId) async {
    _viewedIds.add(storyId);
    await _persistViewed();
  }

  Future<void> removeViewed(String storyId) async {
    _viewedIds.remove(storyId);
    await _persistViewed();
  }

  bool isViewed(String storyId) => _viewedIds.contains(storyId);

  bool areAllViewed(String authorId, List<Story> stories) {
    final userStories = stories.where((s) => s.authorId == authorId && !s.isExpired);
    return userStories.every((s) => _viewedIds.contains(s.id));
  }

  int getFirstUnviewedIndex(String authorId, List<Story> stories) {
    for (int i = 0; i < stories.length; i++) {
      if (!_viewedIds.contains(stories[i].id)) return i;
    }
    return 0;
  }

  Future<void> clearAll() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _viewedIds.clear();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_watchedKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}

typedef StoryService = StoryStorageService;
