import '../models/weather_model.dart';
import 'weather_service.dart';

class WeatherRepository {
  const WeatherRepository({required this.service});

  final WeatherService service;

  Future<WeatherModel> getCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) =>
      service.fetchCurrentWeather(
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );
}
