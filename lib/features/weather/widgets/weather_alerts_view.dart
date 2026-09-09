import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/platform_ui/weather_platform_icons.dart';
import '../models/weather_model.dart';

class WeatherAlertsView extends StatelessWidget {
  const WeatherAlertsView({
    this.weather,
    super.key,
  });

  final WeatherModel? weather;

  @override
  Widget build(BuildContext context) {
    // WeatherOS currently receives conditions from Open-Meteo only. It does
    // not subscribe to an official warning feed, so it must not invent NWS
    // notices, expiry times, or an "all clear" assertion from conditions.
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('ACTIVE WEATHER ALERTS', style: WeatherType.overline),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: WeatherPalette.textTertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: WeatherPalette.textTertiary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: WeatherPalette.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NOT CONNECTED',
                      style: WeatherType.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: WeatherPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // This card intentionally reports alert-feed availability, rather
          // than inferring official warnings from Open-Meteo conditions.
          WeatherPlatformCard(
              padding: const EdgeInsets.all(WeatherSpacing.space6),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: WeatherPalette.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: WeatherPalette.success.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        WeatherPlatformIcons.shield(context),
                        color: WeatherPalette.success,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: WeatherSpacing.space3),
                  Text(
                    'Official alerts unavailable',
                    style: WeatherType.title.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WeatherSpacing.space1),
                  Text(
                    'WeatherOS does not currently retrieve official weather warnings, watches, or advisories for ${weather?.location ?? 'this location'}. Current conditions below are not an alert feed.',
                    textAlign: TextAlign.center,
                    style: WeatherType.body.copyWith(
                      fontSize: 13,
                      color: WeatherPalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: WeatherSpacing.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildMetricSummary(
                        'PRECIP',
                        '${weather?.precipChance ?? 0}%',
                        WeatherPalette.mistBlue,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: WeatherPalette.lensRim.withValues(alpha: 0.2),
                      ),
                      _buildMetricSummary(
                        'WIND',
                        '${weather?.windSpeedMph.round() ?? 0} mph',
                        WeatherPalette.textPrimary,
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: WeatherPalette.lensRim.withValues(alpha: 0.2),
                      ),
                      _buildMetricSummary(
                        'UV INDEX',
                        '${weather?.uvIndex ?? 0}',
                        WeatherPalette.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricSummary(String label, String value, Color color) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: WeatherType.overline.copyWith(
            fontSize: 9,
            color: WeatherPalette.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WeatherType.metricValue.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
