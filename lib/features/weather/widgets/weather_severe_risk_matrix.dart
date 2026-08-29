import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../models/weather_model.dart';

class WeatherSevereRiskMatrix extends StatelessWidget {
  const WeatherSevereRiskMatrix({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  Color _levelColor(double val) {
    if (val >= 0.7) return const Color(0xFFFF5252);
    if (val >= 0.35) return const Color(0xFFFFB300);
    if (val >= 0.1) return const Color(0xFF69F0AE);
    return WeatherPalette.textTertiary;
  }

  String _levelLabel(double val) {
    if (val >= 0.7) return 'High';
    if (val >= 0.35) return 'Moderate';
    if (val >= 0.1) return 'Low';
    return 'None';
  }

  IconData _riskIcon(String key) {
    return switch (key) {
      'rain' => Icons.water_drop,
      'thunderstorms' => Icons.flash_on,
      'flooding' => Icons.waves,
      'wind' => Icons.air,
      'hail' => Icons.ac_unit,
      'tornado' => Icons.cyclone,
      _ => Icons.warning_amber_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final risks = [
      'rain',
      'thunderstorms',
      'flooding',
      'wind',
      'hail',
      'tornado',
    ];

    return WeatherPlatformCard(
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'SEVERE WEATHER RISK',
                  style: WeatherType.overline,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (weather.riskLevel.toUpperCase() == 'HIGH RISK'
                          ? const Color(0xFFFF5252)
                          : (weather.riskLevel.toUpperCase() == 'MODERATE RISK'
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF69F0AE)))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: (weather.riskLevel.toUpperCase() == 'HIGH RISK'
                            ? const Color(0xFFFF5252)
                            : (weather.riskLevel.toUpperCase() == 'MODERATE RISK'
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF69F0AE)))
                        .withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  weather.riskLevel,
                  style: WeatherType.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: (weather.riskLevel.toUpperCase() == 'HIGH RISK'
                        ? const Color(0xFFFF5252)
                        : (weather.riskLevel.toUpperCase() == 'MODERATE RISK'
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF69F0AE))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),
          Row(
            children: risks.map((String key) {
              final val = weather.severeRisks[key] ?? 0.1;
              final color = _levelColor(val);
              final label = _levelLabel(val);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(_riskIcon(key), size: 18, color: WeatherPalette.textSecondary),
                      const SizedBox(height: WeatherSpacing.space1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          key.toUpperCase(),
                          style: WeatherType.overline.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: WeatherSpacing.space1),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(WeatherRadii.pill),
                        child: Container(
                          height: 4,
                          color: WeatherPalette.lensLift.withValues(alpha: 0.5),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(WeatherRadii.pill),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: WeatherSpacing.space1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: WeatherType.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}
