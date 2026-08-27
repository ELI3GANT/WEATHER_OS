import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_model.dart';
import 'glass_lens.dart';
import 'weather_weekly_outlook_card.dart';

class DailyForecastView extends StatelessWidget {
  const DailyForecastView({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: WeatherSpacing.space4,
        vertical: WeatherSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header summary badge
          GlassLens(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WeatherPalette.mistBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(WeatherRadii.control),
                    border: Border.all(
                      color: WeatherPalette.mistBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_graph_rounded,
                    color: WeatherPalette.mistBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: WeatherSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'WEEKLY ATMOSPHERIC SYNOPSIS',
                        style: WeatherType.overline.copyWith(
                          letterSpacing: 1.2,
                          color: WeatherPalette.mistBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.dailySummary,
                        style: WeatherType.body.copyWith(
                          fontSize: 13,
                          height: 1.35,
                          color: WeatherPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // 7-Day Forecast Card
          WeatherWeeklyOutlookCard(
            weather: weather,
            isStandalone: true,
          ),
          const SizedBox(height: WeatherSpacing.space4),
        ],
      ),
    );
  }
}
