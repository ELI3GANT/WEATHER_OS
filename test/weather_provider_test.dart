import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/providers/weather_provider.dart';
import 'package:weather_os/features/weather/services/weather_cache_service.dart';
import 'package:weather_os/features/weather/services/weather_repository.dart';
import 'package:weather_os/features/weather/services/weather_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('provider exposes loading then loaded weather', () async {
    final provider = WeatherProvider(
      repository: WeatherRepository(
        service: _ResultWeatherService(MockWeather.newYorkRain),
      ),
    );
    addTearDown(provider.dispose);

    final load = provider.load();
    expect(provider.state, WeatherLoadState.loading);
    await load;

    expect(provider.state, WeatherLoadState.loaded);
    expect(provider.weather, same(MockWeather.newYorkRain));
    expect(provider.errorMessage, isNull);
  });

  test('provider exposes a presentation-safe error state', () async {
    final provider = WeatherProvider(
      repository: const WeatherRepository(service: _FailingWeatherService()),
    );
    addTearDown(provider.dispose);

    await provider.load();

    expect(provider.state, WeatherLoadState.error);
    expect(provider.weather, isNull);
    expect(provider.errorMessage, isNotEmpty);
  });

  test('latest location request wins when requests overlap', () async {
    final service = _DelayedWeatherService();
    final provider = WeatherProvider(
      repository: WeatherRepository(service: service),
      cacheService: null,
    );
    addTearDown(provider.dispose);

    final firstLoad = provider.load(
      latitude: 40.7128,
      longitude: -74.0060,
      locationName: 'New York',
    );
    final secondLoad = provider.setLocation((
      latitude: 34.0522,
      longitude: -118.2437,
      locationName: 'Los Angeles, California',
    ));

    service.complete('Los Angeles, California', MockWeather.newYorkRain);
    await secondLoad;
    service.complete('New York', MockWeather.newYorkRain);
    await firstLoad;

    expect(provider.weather?.location, 'Los Angeles, California');
    expect(provider.latitude, 34.0522);
    expect(provider.longitude, -118.2437);
  });

  test('uses a fresh cache when offline at cold start', () async {
    const cache = WeatherCacheService();
    await cache.saveWeather(MockWeather.newYorkRain);
    final provider = WeatherProvider(
      repository: const WeatherRepository(service: _FailingWeatherService()),
      cacheService: cache,
      telemetryExporter: _discardTelemetry,
    );
    addTearDown(provider.dispose);

    await provider.load();

    expect(provider.state, WeatherLoadState.loaded);
    expect(provider.weather?.location, MockWeather.newYorkRain.location);
    expect(provider.isOffline, isTrue);
  });

  test('rejects an expired cache when offline at cold start', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'weatheros_cached_weather_payload': jsonEncode(
        MockWeather.newYorkRain.toJson(),
      ),
      'weatheros_cached_timestamp': DateTime.now()
          .subtract(const Duration(minutes: 16))
          .millisecondsSinceEpoch,
    });
    final provider = WeatherProvider(
      repository: const WeatherRepository(service: _FailingWeatherService()),
      cacheService: const WeatherCacheService(),
      telemetryExporter: _discardTelemetry,
    );
    addTearDown(provider.dispose);

    await provider.load();

    expect(provider.state, WeatherLoadState.error);
    expect(provider.weather, isNull);
  });
}

Future<void> _discardTelemetry(WeatherModel _) async {}

class _DelayedWeatherService implements WeatherService {
  final Map<String, Completer<WeatherModel>> _requests = {};

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) => (_requests[locationName] ??= Completer<WeatherModel>()).future;

  void complete(String locationName, WeatherModel weather) {
    _requests[locationName]?.complete(
      WeatherModel(
        location: locationName,
        temperature: weather.temperature,
        condition: weather.condition,
        feelsLike: weather.feelsLike,
        high: weather.high,
        low: weather.low,
        humidity: weather.humidity,
        windSpeedMph: weather.windSpeedMph,
        uvIndex: weather.uvIndex,
        pressureInHg: weather.pressureInHg,
        precipChance: weather.precipChance,
        totalRainInches: weather.totalRainInches,
        visibilityMiles: weather.visibilityMiles,
        windDirectionCompass: weather.windDirectionCompass,
        windBearingDegrees: weather.windBearingDegrees,
        sunriseTime: weather.sunriseTime,
        sunsetTime: weather.sunsetTime,
        daylightDuration: weather.daylightDuration,
        dailySummary: weather.dailySummary,
        riskLevel: weather.riskLevel,
        severeRisks: weather.severeRisks,
        whatToExpect: weather.whatToExpect,
        impactScores: weather.impactScores,
        hourly: weather.hourly,
        dailyForecasts: weather.dailyForecasts,
      ),
    );
  }
}

class _ResultWeatherService implements WeatherService {
  const _ResultWeatherService(this.result);

  final WeatherModel result;

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async => result;
}

class _FailingWeatherService implements WeatherService {
  const _FailingWeatherService();

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async {
    throw Exception('Synthetic transport failure');
  }
}
