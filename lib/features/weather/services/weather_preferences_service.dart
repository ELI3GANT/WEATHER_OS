import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherPreferencesService extends ChangeNotifier {
  WeatherPreferencesService._();
  static final WeatherPreferencesService instance = WeatherPreferencesService._();

  static const String _keyShowRadarTab = 'weatheros_pref_show_radar_tab';

  bool _showRadarTab = true;
  bool _initialized = false;

  bool get showRadarTab => _showRadarTab;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _showRadarTab = prefs.getBool(_keyShowRadarTab) ?? true;
      _initialized = true;
      notifyListeners();
    } on Object {
      _initialized = true;
    }
  }

  Future<void> setShowRadarTab(bool value) async {
    if (_showRadarTab == value) return;
    _showRadarTab = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowRadarTab, value);
    } on Object {
      // Graceful fallback
    }
  }
}
