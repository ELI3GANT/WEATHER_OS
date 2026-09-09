import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:weather_os/features/weather/models/weather_condition.dart';
import 'package:weather_os/features/weather/models/hourly_forecast.dart';
import 'package:weather_os/features/weather/models/weather_atmosphere_state.dart';
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
      final sampleJson = _validPayload(
        current: <String, dynamic>{
          'time': '2026-08-20T09:15',
          'temperature_2m': 72.4,
          'apparent_temperature': 70.1,
          'relative_humidity_2m': 58,
          'weather_code': 61,
          'surface_pressure': 1018.5,
          'wind_speed_10m': 14.2,
          'wind_direction_10m': 112,
          'visibility': 16093.44,
        },
        daily: <String, dynamic>{
          'time': <String>['2026-08-20'],
          'temperature_2m_max': <num>[76.0],
          'temperature_2m_min': <num>[63.0],
          'uv_index_max': <num>[6.4],
          'precipitation_sum': <num>[0.8],
          'precipitation_probability_max': <num>[60],
          'weather_code': <num>[61],
          'sunrise': <String>['2026-08-20T06:15'],
          'sunset': <String>['2026-08-20T19:55'],
        },
        hourly: <String, dynamic>{
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
          'precipitation_probability': <num>[0, 0, 0, 50, 60, 80, 10],
        },
      );

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
      expect(model.totalRainInches, 0.8);
      expect(model.dailyForecasts.first.totalRainInches, 0.8);
      expect(model.visibilityMiles, closeTo(10, 0.001));
      expect(model.hourly, isNotEmpty);
      expect(model.hourly.first.isNow, isTrue);
      expect(model.hourly.first.timeLabel, 'NOW');
    });

    test('rejects incomplete payloads instead of inventing weather data', () {
      expect(
        () => WeatherModel.fromOpenMeteoJson(<String, dynamic>{}),
        throwsFormatException,
      );
      expect(
        () => WeatherModel.fromOpenMeteoJson(<String, dynamic>{
          'current': <String, dynamic>{'temperature_2m': 70},
          'daily': <String, dynamic>{
            'temperature_2m_max': <num>[75],
            'temperature_2m_min': <num>[60],
          },
        }),
        throwsFormatException,
      );
    });

    test('rejects mismatched forecast arrays instead of filling them', () {
      expect(
        () => WeatherModel.fromOpenMeteoJson(
          _validPayload(
            hourly: <String, dynamic>{
              'time': <String>['2026-08-20T12:00', '2026-08-20T13:00'],
              'temperature_2m': <num>[70],
              'weather_code': <num>[0, 0],
              'precipitation_probability': <num>[0, 0],
            },
          ),
        ),
        throwsFormatException,
      );
    });

    test('uses the forecast location offset for location-local time', () {
      const weather = WeatherModel(
        location: 'Tokyo',
        temperature: 70,
        condition: WeatherCondition.sunny,
        feelsLike: 70,
        high: 75,
        low: 60,
        humidity: 50,
        windSpeedMph: 5,
        uvIndex: 5,
        pressureInHg: 30,
        hourly: <HourlyForecast>[],
        utcOffsetSeconds: 32400,
      );

      expect(
        weather.locationTimeFromUtc(DateTime.utc(2026, 8, 20)),
        DateTime.utc(2026, 8, 20, 9),
      );
    });

    test('selects hourly forecast using the response location clock', () {
      final model = WeatherModel.fromOpenMeteoJson(
        _validPayload(
          current: <String, dynamic>{
            'time': '2026-08-20T09:15',
            'temperature_2m': 70,
            'weather_code': 0,
          },
          hourly: <String, dynamic>{
            'time': <String>[
              '2026-08-20T08:00',
              '2026-08-20T09:00',
              '2026-08-20T10:00',
            ],
            'temperature_2m': <num>[68, 70, 72],
            'weather_code': <num>[0, 0, 1],
            'precipitation_probability': <num>[0, 0, 0],
          },
        ),
      );

      expect(model.hourly.first.timeLabel, 'NOW');
      expect(model.hourly.first.temperature, 70);
      expect(model.hourly[1].timeLabel, '10 AM');
    });

    test('converts visibility using the response unit metadata', () {
      final basePayload = _validPayload(
        current: <String, dynamic>{
          'temperature_2m': 70,
          'weather_code': 0,
          'visibility': 65944.884,
        },
      );

      final feet = WeatherModel.fromOpenMeteoJson(<String, dynamic>{
        ...basePayload,
        'current_units': <String, dynamic>{'visibility': 'ft'},
      });
      final metres = WeatherModel.fromOpenMeteoJson(<String, dynamic>{
        ...basePayload,
        'current': <String, dynamic>{
          ...(basePayload['current'] as Map<String, dynamic>),
          'visibility': 20100,
        },
        'current_units': <String, dynamic>{'visibility': 'm'},
      });

      expect(feet.visibilityMiles, closeTo(12.49, 0.01));
      expect(metres.visibilityMiles, closeTo(12.49, 0.01));
    });

    test('normalizes a metric response at the parser boundary', () {
      final payload =
          _validPayload(
              current: <String, dynamic>{
                'temperature_2m': 20,
                'apparent_temperature': 19,
                'surface_pressure': 1013.25,
                'wind_speed_10m': 10,
                'visibility': 16093.44,
              },
              daily: <String, dynamic>{
                'temperature_2m_max': <num>[25],
                'temperature_2m_min': <num>[10],
                'precipitation_sum': <num>[25.4],
              },
              hourly: <String, dynamic>{
                'temperature_2m': <num>[20],
              },
            )
            ..['current_units'] = <String, dynamic>{
              'temperature_2m': '°C',
              'apparent_temperature': '°C',
              'surface_pressure': 'hPa',
              'wind_speed_10m': 'km/h',
              'visibility': 'm',
            }
            ..['daily_units'] = <String, dynamic>{
              'temperature_2m_max': '°C',
              'temperature_2m_min': '°C',
              'precipitation_sum': 'mm',
            }
            ..['hourly_units'] = <String, dynamic>{'temperature_2m': '°C'};

      final model = WeatherModel.fromOpenMeteoJson(payload);

      expect(model.temperature, 68);
      expect(model.feelsLike, closeTo(66.2, 0.01));
      expect(model.high, 77);
      expect(model.low, 50);
      expect(model.windSpeedMph, closeTo(6.21, 0.01));
      expect(model.pressureInHg, closeTo(29.92, 0.01));
      expect(model.totalRainInches, 1);
      expect(model.hourly.first.temperature, 68);
      expect(model.visibilityMiles, closeTo(10, 0.001));
    });

    test('preserves cloud-cover WMO detail for the atmosphere', () {
      final partlyCloudy = WeatherModel.fromOpenMeteoJson(
        _validPayload(
          current: <String, dynamic>{'weather_code': 2},
          daily: <String, dynamic>{
            'weather_code': <num>[2],
          },
          hourly: <String, dynamic>{
            'weather_code': <num>[2],
          },
        ),
      );
      final overcast = WeatherModel.fromOpenMeteoJson(
        _validPayload(
          current: <String, dynamic>{'weather_code': 3},
          daily: <String, dynamic>{
            'weather_code': <num>[3],
          },
          hourly: <String, dynamic>{
            'weather_code': <num>[3],
          },
        ),
      );

      expect(partlyCloudy.wmoCode, 2);
      expect(overcast.wmoCode, 3);
      expect(partlyCloudy.dailySummary, contains('Partly cloudy'));
      expect(overcast.dailySummary, contains('Overcast'));
      expect(
        WeatherAtmosphereState.fromWeather(partlyCloudy).isOvercast,
        isFalse,
      );
      expect(WeatherAtmosphereState.fromWeather(overcast).isOvercast, isTrue);
    });

    test(
      'uses condition copy that does not invent a time-specific forecast',
      () {
        final storm = WeatherModel.fromOpenMeteoJson(
          _validPayload(
            current: <String, dynamic>{'weather_code': 95},
            daily: <String, dynamic>{
              'weather_code': <num>[95],
            },
            hourly: <String, dynamic>{
              'weather_code': <num>[95],
            },
          ),
        );

        expect(storm.dailySummary.toLowerCase(), isNot(contains('afternoon')));
        expect(
          storm.whatToExpect.join(' ').toLowerCase(),
          isNot(contains('afternoon')),
        );
      },
    );
  });

  group('OpenMeteoWeatherService', () {
    test('fetches and returns parsed weather on HTTP 200', () async {
      final mockClient = _MockHttpClient((http.Request request) async {
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.path, '/v1/forecast');
        expect(request.url.queryParameters['latitude'], '37.7749');
        expect(request.url.queryParameters['longitude'], '-122.4194');
        expect(request.url.queryParameters['temperature_unit'], 'fahrenheit');
        expect(request.url.queryParameters['current'], contains('visibility'));

        final payload = _validPayload(
          current: <String, dynamic>{
            'time': '2026-08-20T12:00',
            'temperature_2m': 65.0,
            'apparent_temperature': 63.0,
            'relative_humidity_2m': 75,
            'weather_code': 0,
            'surface_pressure': 1015.0,
            'wind_speed_10m': 8.5,
            'wind_direction_10m': 112,
            'visibility': 52800,
          },
          daily: <String, dynamic>{
            'time': <String>['2026-08-20'],
            'temperature_2m_max': <num>[68.0],
            'temperature_2m_min': <num>[55.0],
            'uv_index_max': <num>[7.0],
            'precipitation_sum': <num>[0],
            'precipitation_probability_max': <num>[0],
            'weather_code': <num>[0],
            'sunrise': <String>['2026-08-20T06:00'],
            'sunset': <String>['2026-08-20T20:00'],
          },
          hourly: <String, dynamic>{
            'time': <String>['2026-08-20T12:00'],
            'temperature_2m': <num>[65.0],
            'weather_code': <num>[0],
            'precipitation_probability': <num>[0],
          },
        );

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
        final payload = _validPayload(
          current: <String, dynamic>{
            'time': '2026-08-20T12:00',
            'temperature_2m': 70.0 + callCount,
            'apparent_temperature': 68.0,
            'relative_humidity_2m': 50,
            'weather_code': 0,
            'surface_pressure': 1013.0,
            'wind_speed_10m': 5.0,
            'wind_direction_10m': 112,
            'visibility': 52800,
          },
          daily: <String, dynamic>{
            'time': <String>['2026-08-20'],
            'temperature_2m_max': <num>[75.0],
            'temperature_2m_min': <num>[60.0],
            'uv_index_max': <num>[5.0],
            'precipitation_sum': <num>[0],
            'precipitation_probability_max': <num>[0],
            'weather_code': <num>[0],
            'sunrise': <String>['2026-08-20T06:00'],
            'sunset': <String>['2026-08-20T20:00'],
          },
          hourly: <String, dynamic>{
            'time': <String>['2026-08-20T12:00'],
            'temperature_2m': <num>[70.0],
            'weather_code': <num>[0],
            'precipitation_probability': <num>[0],
          },
        );
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

Map<String, dynamic> _validPayload({
  Map<String, dynamic>? current,
  Map<String, dynamic>? daily,
  Map<String, dynamic>? hourly,
}) => <String, dynamic>{
  'utc_offset_seconds': -14400,
  'current': <String, dynamic>{
    'time': '2026-08-20T12:00',
    'temperature_2m': 70,
    'apparent_temperature': 70,
    'relative_humidity_2m': 50,
    'weather_code': 0,
    'surface_pressure': 1013,
    'wind_speed_10m': 5,
    'wind_direction_10m': 90,
    'visibility': 52800,
    ...?current,
  },
  'daily': <String, dynamic>{
    'time': <String>['2026-08-20'],
    'temperature_2m_max': <num>[75],
    'temperature_2m_min': <num>[60],
    'weather_code': <num>[0],
    'precipitation_probability_max': <num>[0],
    'precipitation_sum': <num>[0],
    'uv_index_max': <num>[5],
    'sunrise': <String>['2026-08-20T06:00'],
    'sunset': <String>['2026-08-20T20:00'],
    ...?daily,
  },
  'hourly': <String, dynamic>{
    'time': <String>['2026-08-20T12:00'],
    'temperature_2m': <num>[70],
    'weather_code': <num>[0],
    'precipitation_probability': <num>[0],
    ...?hourly,
  },
};

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
