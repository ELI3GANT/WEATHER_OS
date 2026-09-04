import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/hourly_forecast.dart';
import '../models/weather_condition.dart';

class WeatherThreatBar extends StatelessWidget {
  const WeatherThreatBar({
    required this.forecasts,
    super.key,
  });

  final List<HourlyForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    Color forecastColor(HourlyForecast forecast) {
      final probability = forecast.precipChance;
      if (forecast.condition == WeatherCondition.storm) {
        return const Color(0xFFE040FB);
      }
      if (forecast.condition == WeatherCondition.snow) {
        return const Color(0xFFB8D9FF);
      }
      if (probability >= 70) {
        return const Color(0xFFFF5252);
      }
      if (probability >= 40) {
        return const Color(0xFFFFB300);
      }
      if (probability >= 15 || forecast.condition == WeatherCondition.rain) {
        return const Color(0xFF38BDF8);
      }
      // Calm, dry, clear or cloudy hours: sleek obsidian glass track
      return WeatherPalette.textTertiary.withValues(alpha: 0.22);
    }

    final hasPrecipActivity = forecasts.any(
      (HourlyForecast f) =>
          f.precipChance >= 15 ||
          f.condition == WeatherCondition.rain ||
          f.condition == WeatherCondition.snow ||
          f.condition == WeatherCondition.storm,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 5,
            child: Row(
              children: forecasts.map((forecast) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: forecastColor(forecast),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
        const SizedBox(height: WeatherSpacing.space2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            hasPrecipActivity
                ? 'PRECIPITATION / INTENSITY • ACTIVE CELLS'
                : 'PRECIPITATION / INTENSITY • CALM / DRY',
            style: WeatherType.overline.copyWith(
              fontSize: 9,
              color: WeatherPalette.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
