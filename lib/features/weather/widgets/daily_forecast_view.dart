import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import 'glass_lens.dart';
import 'weather_glyph.dart';

class DailyForecastView extends StatelessWidget {
  const DailyForecastView({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  static List<String> _generateDayLabels() {
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final list = <String>['Today', 'Tomorrow'];
    for (var i = 2; i < 7; i++) {
      final date = now.add(Duration(days: i));
      list.add(weekdayNames[date.weekday - 1]);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = _generateDayLabels();
    final days = <_DailyItem>[
      _DailyItem(day: dayLabels[0], condition: weather.condition, precip: weather.precipChance, low: weather.low, high: weather.high),
      _DailyItem(day: dayLabels[1], condition: WeatherCondition.storm, precip: 80, low: 64, high: 73),
      _DailyItem(day: dayLabels[2], condition: WeatherCondition.rain, precip: 60, low: 62, high: 70),
      _DailyItem(day: dayLabels[3], condition: WeatherCondition.cloudy, precip: 20, low: 58, high: 75),
      _DailyItem(day: dayLabels[4], condition: WeatherCondition.sunny, precip: 0, low: 60, high: 78),
      _DailyItem(day: dayLabels[5], condition: WeatherCondition.sunny, precip: 5, low: 62, high: 80),
      _DailyItem(day: dayLabels[6], condition: WeatherCondition.cloudy, precip: 15, low: 61, high: 76),
    ];

    final minOverall = days.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final maxOverall = days.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final range = (maxOverall - minOverall).clamp(1.0, 100.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('7-DAY OUTLOOK', style: WeatherType.overline),
          const SizedBox(height: WeatherSpacing.space3),
          GlassLens(
            padding: const EdgeInsets.symmetric(
              vertical: WeatherSpacing.space3,
              horizontal: WeatherSpacing.space4,
            ),
            child: Column(
              children: days.map((_DailyItem d) {
                final startNorm = ((d.low - minOverall) / range).clamp(0.0, 1.0);
                final endNorm = ((d.high - minOverall) / range).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: WeatherSpacing.space2),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 80,
                        child: Text(
                          d.day,
                          style: WeatherType.label.copyWith(
                            fontSize: 14,
                            fontWeight: d.day == 'Today' ? FontWeight.w700 : FontWeight.w500,
                            color: d.day == 'Today' ? WeatherPalette.textPrimary : WeatherPalette.textSecondary,
                          ),
                        ),
                      ),
                      WeatherGlyph(condition: d.condition, size: 22),
                      const SizedBox(width: WeatherSpacing.space2),
                      SizedBox(
                        width: 40,
                        child: Text(
                          d.precip > 0 ? '${d.precip}%' : '',
                          style: WeatherType.label.copyWith(
                            fontSize: 11,
                            color: WeatherPalette.mistBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${d.low.round()}°',
                        style: WeatherType.label.copyWith(
                          fontSize: 13,
                          color: WeatherPalette.textTertiary,
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space2),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final barWidth = constraints.maxWidth;
                            final left = startNorm * barWidth;
                            final width = ((endNorm - startNorm) * barWidth).clamp(8.0, barWidth);

                            return Stack(
                              children: <Widget>[
                                Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: WeatherPalette.lensLift.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(WeatherRadii.pill),
                                  ),
                                ),
                                Positioned(
                                  left: left,
                                  child: Container(
                                    width: width,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: <Color>[
                                          WeatherPalette.mistBlue,
                                          WeatherPalette.horizonAmber,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(WeatherRadii.pill),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space2),
                      Text(
                        '${d.high.round()}°',
                        style: WeatherType.metricValue.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyItem {
  const _DailyItem({
    required this.day,
    required this.condition,
    required this.precip,
    required this.low,
    required this.high,
  });

  final String day;
  final WeatherCondition condition;
  final int precip;
  final double low;
  final double high;
}
