import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/weather_model.dart';
import '../services/location_service.dart';
import '../services/watch_export_service.dart';
import '../services/weather_cache_service.dart';
import '../services/weather_repository.dart';

enum WeatherLoadState { initial, loading, loaded, error }

typedef WeatherTelemetryExporter = Future<void> Function(WeatherModel weather);

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({
    required this.repository,
    this.locationService,
    this.cacheService = const WeatherCacheService(),
    this.telemetryExporter = WatchExportService.exportTelemetry,
  });

  final WeatherRepository repository;
  final LocationService? locationService;
  final WeatherCacheService? cacheService;
  final WeatherTelemetryExporter telemetryExporter;

  WeatherLoadState _state = WeatherLoadState.initial;
  WeatherModel? _weather;
  String? _errorMessage;
  bool _isOffline = false;
  bool _isDisposed = false;

  double _latitude = 40.7128;
  double _longitude = -74.0060;
  String _locationName = 'New York';

  WeatherLoadState get state => _state;
  WeatherModel? get weather => _weather;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  double get latitude => _latitude;
  double get longitude => _longitude;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> load({
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    if (_state == WeatherLoadState.loading) {
      return;
    }

    _state = _weather != null
        ? WeatherLoadState.loaded
        : WeatherLoadState.loading;
    _errorMessage = null;

    // Hydrate from offline cache immediately on cold start
    if (_weather == null && cacheService != null) {
      final cached = await cacheService!.getCachedWeather();
      if (cached != null && !_isDisposed) {
        _weather = cached;
        _state = WeatherLoadState.loaded;
        _isOffline = true;
        notifyListeners();
      }
    }

    var targetLat = latitude ?? _latitude;
    var targetLong = longitude ?? _longitude;
    var targetName = locationName ?? _locationName;

    if (latitude == null && locationService != null) {
      final loc = await locationService!.getCurrentLocation();
      if (loc != null) {
        targetLat = loc.latitude;
        targetLong = loc.longitude;
        targetName = loc.locationName;
      }
    }

    _latitude = targetLat;
    _longitude = targetLong;
    _locationName = targetName;

    try {
      final fresh = await repository.getCurrentWeather(
        latitude: targetLat,
        longitude: targetLong,
        locationName: targetName,
      );
      if (!_isDisposed) {
        _weather = fresh;
        _state = WeatherLoadState.loaded;
        _isOffline = false;
        _errorMessage = null;
        if (cacheService != null) {
          await cacheService!.saveWeather(fresh);
        }
        unawaited(telemetryExporter(fresh));
      }
    } on Exception {
      if (!_isDisposed) {
        if (_weather == null) {
          _errorMessage = 'Weather data is temporarily unavailable.';
          _state = WeatherLoadState.error;
        } else {
          _isOffline = true;
        }
      }
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> refresh() => load(
    latitude: _latitude,
    longitude: _longitude,
    locationName: _locationName,
  );

  Future<void> setLocation(LocationResult location) => load(
    latitude: location.latitude,
    longitude: location.longitude,
    locationName: location.locationName,
  );
}
