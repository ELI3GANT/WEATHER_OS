import '../models/weather_model.dart';

/// Transport boundary for current conditions. A live API implementation can
/// replace the mock without changing repository, provider, or presentation.
abstract interface class WeatherService {
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  });
}
