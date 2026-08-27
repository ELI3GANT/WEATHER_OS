abstract final class AppConstants {
  static const String appName = 'WeatherOS';
  static const Duration mockWeatherLatency = Duration(
    milliseconds: int.fromEnvironment(
      'WEATHEROS_MOCK_LATENCY_MS',
      defaultValue: 220,
    ),
  );
}
