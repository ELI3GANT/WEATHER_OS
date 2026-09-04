import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../models/weather_model.dart';

class WeatherImpactMeterCard extends StatelessWidget {
  const WeatherImpactMeterCard({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFFFF5252);
    if (score >= 35) return const Color(0xFFFFB300);
    return WeatherPalette.success;
  }

  IconData _impactIcon(String activity) {
    return switch (activity.toLowerCase()) {
      'driving' => Icons.directions_car_outlined,
      'outdoor plans' => Icons.park_outlined,
      'construction' => Icons.domain_outlined,
      'running' => Icons.directions_run_outlined,
      'flying drones' => Icons.flight_takeoff_outlined,
      'photography' => Icons.camera_alt_outlined,
      _ => Icons.check_circle_outline,
    };
  }

  IconData _adviceIcon(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('umbrella')) return Icons.beach_access_outlined;
    if (lower.contains('road') || lower.contains('slick')) return Icons.directions_car;
    if (lower.contains('thunder') || lower.contains('storm')) return Icons.flash_on;
    if (lower.contains('rain')) return Icons.water_drop_outlined;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 500;

        final expectCard = WeatherPlatformCard(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('WHAT TO EXPECT', style: WeatherType.overline),
              const SizedBox(height: WeatherSpacing.space3),
              ...weather.whatToExpect.map((String tip) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: WeatherSpacing.space2),
                  child: Row(
                    children: <Widget>[
                      Icon(_adviceIcon(tip), size: 16, color: WeatherPalette.mistBlue),
                      const SizedBox(width: WeatherSpacing.space2),
                      Expanded(
                        child: Text(
                          tip,
                          style: WeatherType.label.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );

        final impactCard = WeatherPlatformCard(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('IMPACT METER', style: WeatherType.overline),
              const SizedBox(height: WeatherSpacing.space3),
              ...weather.impactScores.entries.map((MapEntry<String, int> entry) {
                final color = _scoreColor(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: WeatherSpacing.space2),
                  child: Row(
                    children: <Widget>[
                      Icon(_impactIcon(entry.key), size: 17, color: WeatherPalette.textSecondary),
                      const SizedBox(width: WeatherSpacing.space2),
                      SizedBox(
                        width: 85,
                        child: Text(
                          entry.key,
                          style: WeatherType.label.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(WeatherRadii.pill),
                          child: Container(
                            height: 6,
                            color: WeatherPalette.lensLift.withValues(alpha: 0.4),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (entry.value / 100.0).clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space2),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${entry.value}%',
                          textAlign: TextAlign.right,
                          style: WeatherType.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: WeatherPalette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 10, child: expectCard),
              const SizedBox(width: WeatherSpacing.space3),
              Expanded(flex: 11, child: impactCard),
            ],
          );
        }

        return Column(
          children: <Widget>[
            expectCard,
            const SizedBox(height: WeatherSpacing.space3),
            impactCard,
          ],
        );
      },
    );
  }
}
