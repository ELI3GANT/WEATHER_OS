import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_model.dart';

class WeatherCacheService {
  const WeatherCacheService();

  static const String _keyCachedWeatherPrefix =
      'weatheros_cached_weather_payload_';
  static const String _keyCachedTimestampPrefix = 'weatheros_cached_timestamp_';

  // Open-Meteo accepts coordinates with much more precision than is useful for
  // a weather cache. Keeping four decimal places distinguishes nearby cities
  // while allowing the same place to be recognised after a GPS refresh.
  static String locationKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

  static String _weatherKey(double latitude, double longitude) =>
      '$_keyCachedWeatherPrefix${locationKey(latitude, longitude)}';

  static String _timestampKey(double latitude, double longitude) =>
      '$_keyCachedTimestampPrefix${locationKey(latitude, longitude)}';

  Future<WeatherModel?> getCachedWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_weatherKey(latitude, longitude));
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic> &&
          WeatherModel.isCompleteCachePayload(decoded)) {
        return WeatherModel.fromJson(decoded);
      }
    } on Object {
      // In-memory or uninitialized channel fallback
    }
    return null;
  }

  Future<void> saveWeather(
    WeatherModel weather, {
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final jsonMap = weather.toJson()..['timestamp'] = now;
      final encoded = jsonEncode(jsonMap);
      await prefs.setString(_weatherKey(latitude, longitude), encoded);
      await prefs.setInt(_timestampKey(latitude, longitude), now);
    } on Object {
      // Graceful fallback
    }
  }

  Future<bool> isCacheFresh({
    required double latitude,
    required double longitude,
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey(latitude, longitude));
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
