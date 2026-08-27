enum WeatherCondition {
  rain('Rain'),
  sunny('Sunny'),
  storm('Storm'),
  cloudy('Cloudy'),
  snow('Snow'),
  fog('Fog');

  const WeatherCondition(this.label);

  final String label;

  /// Maps standard WMO (World Meteorological Organization) weather interpretation
  /// codes (used by Open-Meteo and national weather services) to WeatherOS conditions.
  static WeatherCondition fromWmoCode(int? code) {
    if (code == null) {
      return WeatherCondition.cloudy;
    }
    return switch (code) {
      0 => WeatherCondition.sunny,
      1 || 2 || 3 => WeatherCondition.cloudy,
      45 || 48 => WeatherCondition.fog,
      51 || 53 || 55 || 56 || 57 => WeatherCondition.rain,
      61 || 63 || 65 || 66 || 67 => WeatherCondition.rain,
      71 || 73 || 75 || 77 => WeatherCondition.snow,
      80 || 81 || 82 => WeatherCondition.rain,
      85 || 86 => WeatherCondition.snow,
      95 || 96 || 99 => WeatherCondition.storm,
      _ => WeatherCondition.cloudy,
    };
  }
}
