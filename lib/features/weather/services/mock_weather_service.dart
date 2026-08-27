import '../../../core/constants/app_constants.dart';
import '../models/mock_weather.dart';
import '../models/weather_model.dart';
import 'weather_service.dart';

class MockWeatherService implements WeatherService {
  const MockWeatherService();

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async {
    await Future<void>.delayed(AppConstants.mockWeatherLatency);
    return MockWeather.newYorkRain;
  }
}
