import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/hourly_forecast.dart';

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
      if (probability >= 70) return const Color(0xFFFF5252);
      if (probability >= 40) return const Color(0xFFFFB300);
      return switch (forecast.condition.name) {
        'clear' => const Color(0xFFFFC857),
        'snow' => const Color(0xFFB8D9FF),
        'storm' => const Color(0xFFE040FB),
        'rain' => const Color(0xFF38BDF8),
        _ => const Color(0xFF69F0AE),
      };
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Row(
              children: forecasts.map((forecast) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: forecastColor(forecast),
                      borderRadius: BorderRadius.circular(2),
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
            'PRECIPITATION / CONDITION INTENSITY',
            style: WeatherType.overline.copyWith(fontSize: 9, color: WeatherPalette.textTertiary),
          ),
        ),
      ],
    );
  }
}
