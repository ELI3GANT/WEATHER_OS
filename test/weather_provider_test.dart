import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/providers/weather_provider.dart';
import 'package:weather_os/features/weather/services/weather_repository.dart';
import 'package:weather_os/features/weather/services/weather_service.dart';

void main() {
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
}

class _ResultWeatherService implements WeatherService {
  const _ResultWeatherService(this.result);

  final WeatherModel result;

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async =>
      result;
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
