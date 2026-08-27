import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weather_os/features/weather/models/weather_condition.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/providers/weather_provider.dart';
import 'package:weather_os/features/weather/services/open_meteo_weather_service.dart';
import 'package:weather_os/features/weather/services/weather_repository.dart';

void main() {
  group('WeatherCondition.fromWmoCode', () {
    test('maps WMO codes correctly to WeatherCondition', () {
      expect(WeatherCondition.fromWmoCode(0), WeatherCondition.sunny);
      expect(WeatherCondition.fromWmoCode(1), WeatherCondition.cloudy);
      expect(WeatherCondition.fromWmoCode(2), WeatherCondition.cloudy);
      expect(WeatherCondition.fromWmoCode(3), WeatherCondition.cloudy);
      expect(WeatherCondition.fromWmoCode(45), WeatherCondition.fog);
      expect(WeatherCondition.fromWmoCode(51), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(61), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(80), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(95), WeatherCondition.storm);
      expect(WeatherCondition.fromWmoCode(96), WeatherCondition.storm);
      expect(WeatherCondition.fromWmoCode(99), WeatherCondition.storm);
      expect(WeatherCondition.fromWmoCode(null), WeatherCondition.cloudy);
      expect(WeatherCondition.fromWmoCode(999), WeatherCondition.cloudy);
    });
  });

  group('WeatherModel.fromOpenMeteoJson', () {
    test('parses complete Open-Meteo payload into WeatherModel', () {
      final sampleJson = <String, dynamic>{
        'current': <String, dynamic>{
          'temperature_2m': 72.4,
          'apparent_temperature': 70.1,
          'relative_humidity_2m': 58,
          'weather_code': 61,
          'surface_pressure': 1018.5,
          'wind_speed_10m': 14.2,
        },
        'daily': <String, dynamic>{
          'temperature_2m_max': <num>[76.0],
          'temperature_2m_min': <num>[63.0],
          'uv_index_max': <num>[6.4],
        },
        'hourly': <String, dynamic>{
          'time': <String>[
            '2026-08-20T00:00',
            '2026-08-20T03:00',
            '2026-08-20T06:00',
            '2026-08-20T09:00',
            '2026-08-20T12:00',
            '2026-08-20T15:00',
            '2026-08-20T18:00',
          ],
          'temperature_2m': <num>[68.0, 66.0, 65.0, 70.0, 74.0, 75.0, 71.0],
          'weather_code': <num>[0, 1, 2, 61, 61, 95, 3],
        },
      };

      final model = WeatherModel.fromOpenMeteoJson(
        sampleJson,
        location: 'San Francisco',
      );

      expect(model.location, 'San Francisco');
      expect(model.temperature, 72.4);
      expect(model.feelsLike, 70.1);
      expect(model.condition, WeatherCondition.rain);
      expect(model.high, 76.0);
      expect(model.low, 63.0);
      expect(model.humidity, 58);
      expect(model.windSpeedMph, 14.2);
      expect(model.uvIndex, 6);
      expect(model.pressureInHg, closeTo(30.08, 0.05));
      expect(model.hourly, isNotEmpty);
      expect(model.hourly.first.isNow, isTrue);
      expect(model.hourly.first.timeLabel, 'NOW');
    });
  });

  group('OpenMeteoWeatherService', () {
    test('fetches and returns parsed weather on HTTP 200', () async {
      final mockClient = _MockHttpClient((http.Request request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.path, '/v1/forecast');
        expect(request.url.queryParameters['latitude'], '37.7749');
        expect(request.url.queryParameters['longitude'], '-122.4194');
        expect(request.url.queryParameters['temperature_unit'], 'fahrenheit');

        final payload = <String, dynamic>{
          'current': <String, dynamic>{
            'temperature_2m': 65.0,
            'apparent_temperature': 63.0,
            'relative_humidity_2m': 75,
            'weather_code': 0,
            'surface_pressure': 1015.0,
            'wind_speed_10m': 8.5,
          },
          'daily': <String, dynamic>{
            'temperature_2m_max': <num>[68.0],
            'temperature_2m_min': <num>[55.0],
            'uv_index_max': <num>[7.0],
          },
          'hourly': <String, dynamic>{
            'time': <String>['2026-08-20T12:00'],
            'temperature_2m': <num>[65.0],
            'weather_code': <num>[0],
          },
        };

        return http.Response(
          jsonEncode(payload),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = OpenMeteoWeatherService(client: mockClient);
      final result = await service.fetchCurrentWeather(
        latitude: 37.7749,
        longitude: -122.4194,
        locationName: 'San Francisco',
      );

      expect(result.location, 'San Francisco');
      expect(result.temperature, 65.0);
      expect(result.condition, WeatherCondition.sunny);
      expect(result.humidity, 75);
    });

    test('throws HttpException on non-200 server response', () async {
      final mockClient = _MockHttpClient((http.Request request) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = OpenMeteoWeatherService(client: mockClient);

      expect(
        () => service.fetchCurrentWeather(),
        throwsA(isA<HttpException>()),
      );
    });

    test('throws FormatException on malformed response body', () async {
      final mockClient = _MockHttpClient((http.Request request) async {
        return http.Response('["not a map"]', 200);
      });

      final service = OpenMeteoWeatherService(client: mockClient);

      expect(
        () => service.fetchCurrentWeather(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('WeatherProvider refresh & coordinate handling', () {
    test('refresh invokes repository with configured coordinates', () async {
      var callCount = 0;
      final mockClient = _MockHttpClient((http.Request request) async {
        callCount++;
        final payload = <String, dynamic>{
          'current': <String, dynamic>{
            'temperature_2m': 70.0 + callCount,
            'apparent_temperature': 68.0,
            'relative_humidity_2m': 50,
            'weather_code': 0,
            'surface_pressure': 1013.0,
            'wind_speed_10m': 5.0,
          },
          'daily': <String, dynamic>{
            'temperature_2m_max': <num>[75.0],
            'temperature_2m_min': <num>[60.0],
            'uv_index_max': <num>[5.0],
          },
          'hourly': <String, dynamic>{
            'time': <String>['2026-08-20T12:00'],
            'temperature_2m': <num>[70.0],
            'weather_code': <num>[0],
          },
        };
        return http.Response(jsonEncode(payload), 200);
      });

      final provider = WeatherProvider(
        repository: WeatherRepository(
          service: OpenMeteoWeatherService(client: mockClient),
        ),
      );
      addTearDown(provider.dispose);

      await provider.load(
        latitude: 34.0522,
        longitude: -118.2437,
        locationName: 'Los Angeles',
      );
      expect(provider.weather?.location, 'Los Angeles');
      expect(provider.weather?.temperature, 71.0);
      expect(callCount, 1);

      await provider.refresh();
      expect(provider.weather?.location, 'Los Angeles');
      expect(provider.weather?.temperature, 72.0);
      expect(callCount, 2);
    });
  });
}

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);

  final Future<http.Response> Function(http.Request request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.Request) {
      throw UnimplementedError('Only http.Request is supported in mock');
    }
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
