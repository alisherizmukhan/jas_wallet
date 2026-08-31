import 'package:timezone/data/latest.dart' as tzdata;

bool _initialized = false;

/// Loads the IANA timezone database exactly once.
///
/// Required before constructing any `tz.TZDateTime` or calling
/// `zonedSchedule`. Safe to call from multiple entry points — subsequent
/// calls are no-ops.
void ensureTimeZonesInitialized() {
  if (_initialized) return;
  tzdata.initializeTimeZones();
  _initialized = true;
}
