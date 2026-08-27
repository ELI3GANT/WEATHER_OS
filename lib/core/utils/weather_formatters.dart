abstract final class WeatherFormatters {
  static String degrees(double value) => '${value.round()}°';

  static String pressure(double value) => value.toStringAsFixed(2);
}
