import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_model.dart';

class WeatherCacheService {
  const WeatherCacheService();

  static const String _keyCachedWeather = 'weatheros_cached_weather_payload';
  static const String _keyCachedTimestamp = 'weatheros_cached_timestamp';

  Future<WeatherModel?> getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyCachedWeather);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return WeatherModel.fromJson(decoded);
      }
    } on Object {
      // In-memory or uninitialized channel fallback
    }
    return null;
  }

  Future<void> saveWeather(WeatherModel weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final jsonMap = weather.toJson()..['timestamp'] = now;
      final encoded = jsonEncode(jsonMap);
      await prefs.setString(_keyCachedWeather, encoded);
      await prefs.setInt(_keyCachedTimestamp, now);
    } on Object {
      // Graceful fallback
    }
  }

  Future<bool> isCacheFresh({Duration maxAge = const Duration(minutes: 15)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyCachedTimestamp);
      if (timestamp == null) {
        return false;
      }
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return age < maxAge.inMilliseconds;
    } on Object {
      return false;
    }
  }
}
