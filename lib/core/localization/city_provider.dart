// ignore_for_file: empty_catches
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for persisting city in SharedPreferences.
const String _cityKey = 'user_city';

/// Default city.
const String _defaultCity = 'Астана';
const Set<String> _allowedCities = {'Astana', 'Астана'};

/// Riverpod provider for city management.
/// Provides the current city state.
final cityProvider = StateNotifierProvider<CityNotifier, String>((ref) {
  return CityNotifier();
});

/// StateNotifier for managing city state.
/// Handles city selection and persistence.
class CityNotifier extends StateNotifier<String> {
  CityNotifier() : super(_defaultCity) {
    _loadCity();
  }

  /// Loads the persisted city from SharedPreferences.
  Future<void> _loadCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString(_cityKey);
      if (city != null && city.isNotEmpty && _allowedCities.contains(city)) {
        state = city;
      } else {
        state = _defaultCity;
        await _saveCity(_defaultCity);
      }
    } catch (e) {
    }
  }

  /// Saves the current city to SharedPreferences.
  Future<void> _saveCity(String city) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cityKey, city);
    } catch (e) {
    }
  }

  /// Sets the city.
  void setCity(String city) {
    final normalized = _allowedCities.contains(city) ? city : _defaultCity;
    state = normalized;
    _saveCity(normalized);
  }

  /// Returns the current city.
  String get currentCity => state;
}
