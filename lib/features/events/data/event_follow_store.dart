import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/event.dart';

/// Local opt-in list of NU events the user wants reminders for.
///
/// Keys are [NuEvent.reminderKey] (event URL, or title+date). Empty list
/// means no event reminders at all — see [EventReminderScheduler].
class EventFollowStore {
  EventFollowStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  static const String prefsKey = 'event_reminder_followed_keys';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<Set<String>> load() async {
    final prefs = await _prefs;
    return (prefs.getStringList(prefsKey) ?? const []).toSet();
  }

  Future<void> save(Set<String> keys) async {
    final prefs = await _prefs;
    await prefs.setStringList(prefsKey, keys.toList());
  }

  /// Returns the followed set after toggling [event].
  Future<({Set<String> keys, bool followed})> toggle(NuEvent event) async {
    final keys = await load();
    final key = event.reminderKey;
    final followed = !keys.contains(key);
    if (followed) {
      keys.add(key);
    } else {
      keys.remove(key);
    }
    await save(keys);
    return (keys: keys, followed: followed);
  }
}
