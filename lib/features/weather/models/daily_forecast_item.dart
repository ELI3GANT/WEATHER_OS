import 'weather_condition.dart';

/// Represents a single day's forecast in the 7-day outlook.
class DailyForecastItem {
  const DailyForecastItem({
    required this.dayLabel,
    required this.condition,
    required this.high,
    required this.low,
    required this.precipChance,
    this.date,
    this.uvIndex = 3,
    this.totalRainInches = 0.0,
    this.sunrise,
    this.sunset,
    this.summary,
  });

  final String dayLabel;
  final DateTime? date;
  final WeatherCondition condition;
  final double high;
  final double low;
  final int precipChance;
  final int uvIndex;
  final double totalRainInches;
  final String? sunrise;
  final String? sunset;
  final String? summary;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dayLabel': dayLabel,
        'date': date?.toIso8601String(),
        'condition': condition.name,
        'high': high,
        'low': low,
        'precipChance': precipChance,
        'uvIndex': uvIndex,
        'totalRainInches': totalRainInches,
        'sunrise': sunrise,
        'sunset': sunset,
        'summary': summary,
      };

  factory DailyForecastItem.fromJson(Map<String, dynamic> json) =>
      DailyForecastItem(
        dayLabel: json['dayLabel'] as String? ?? 'Day',
        date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
        condition: WeatherCondition.values.firstWhere(
          (WeatherCondition c) => c.name == json['condition'],
          orElse: () => WeatherCondition.cloudy,
        ),
        high: (json['high'] as num?)?.toDouble() ?? 75.0,
        low: (json['low'] as num?)?.toDouble() ?? 60.0,
        precipChance: (json['precipChance'] as num?)?.round() ?? 0,
        uvIndex: (json['uvIndex'] as num?)?.round() ?? 3,
        totalRainInches: (json['totalRainInches'] as num?)?.toDouble() ?? 0.0,
        sunrise: json['sunrise'] as String?,
        sunset: json['sunset'] as String?,
        summary: json['summary'] as String?,
      );
}
