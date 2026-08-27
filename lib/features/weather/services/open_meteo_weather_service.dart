import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';
import 'weather_service.dart';

/// Live weather transport service backed by Open-Meteo's open meteorological API.
///
/// Requires no API key and provides hourly/current/daily forecasts with WMO weather codes.
class OpenMeteoWeatherService implements WeatherService {
  const OpenMeteoWeatherService({
    this.client,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client? client;
  final Duration timeout;

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m',
        'hourly': 'temperature_2m,weather_code,precipitation_probability',
        'daily': 'temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_sum,sunrise,sunset',
        'temperature_unit': 'fahrenheit',
        'wind_speed_unit': 'mph',
        'precipitation_unit': 'inch',
        'timeformat': 'iso8601',
        'timezone': 'auto',
      },
    );

    try {
      final response = await httpClient
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to load weather: HTTP ${response.statusCode}',
          uri: uri,
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response format from weather service.');
      }

      return WeatherModel.fromOpenMeteoJson(decoded, location: locationName);
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}
