import 'weather_condition.dart';

class HourlyForecast {
  const HourlyForecast({
    required this.timeLabel,
    required this.temperature,
    required this.condition,
    this.precipChance = 20,
    this.threatLevel = 'low',
    this.isNow = false,
  });

  final String timeLabel;
  final double temperature;
  final WeatherCondition condition;
  final int precipChance;
  final String threatLevel;
  final bool isNow;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timeLabel': timeLabel,
        'temperature': temperature,
        'condition': condition.name,
        'precipChance': precipChance,
        'threatLevel': threatLevel,
        'isNow': isNow,
      };

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        timeLabel: json['timeLabel'] as String? ?? 'NOW',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 70.0,
        condition: WeatherCondition.values.firstWhere(
          (WeatherCondition c) => c.name == json['condition'],
          orElse: () => WeatherCondition.cloudy,
        ),
        precipChance: (json['precipChance'] as num?)?.round() ?? 20,
        threatLevel: json['threatLevel'] as String? ?? 'low',
        isNow: json['isNow'] as bool? ?? false,
      );
}
