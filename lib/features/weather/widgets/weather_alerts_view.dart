import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/platform_ui/weather_platform_icons.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';

class WeatherAlertsView extends StatelessWidget {
  const WeatherAlertsView({
    this.weather,
    super.key,
  });

  final WeatherModel? weather;

  @override
  Widget build(BuildContext context) {
    final hasSevereRisk =
        weather != null && weather!.riskLevel == 'HIGH RISK';
    final hasModerateRisk =
        weather != null && weather!.riskLevel == 'MODERATE RISK';
    final isStorm = weather?.condition == WeatherCondition.storm;
    final isSnow = weather?.condition == WeatherCondition.snow;
    final isFog = weather?.condition == WeatherCondition.fog;

    final hasAlerts = hasSevereRisk || hasModerateRisk || isStorm || isSnow || isFog;

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
                  color: hasAlerts
                      ? const Color(0xFFFF5252).withValues(alpha: 0.15)
                      : const Color(0xFF69F0AE).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: hasAlerts
                        ? const Color(0xFFFF5252).withValues(alpha: 0.4)
                        : const Color(0xFF69F0AE).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      hasAlerts
                          ? WeatherPlatformIcons.warning(context)
                          : Icons.check_circle_outline_rounded,
                      size: 12,
                      color: hasAlerts
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF69F0AE),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasAlerts
                          ? (hasSevereRisk ? '2 WARNINGS' : '1 ADVISORY')
                          : 'ALL CLEAR',
                      style: WeatherType.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: hasAlerts
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF69F0AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),

          if (!hasAlerts) ...<Widget>[
            // ALL CLEAR Platform Card
            WeatherPlatformCard(
              padding: const EdgeInsets.all(WeatherSpacing.space6),
              child: Column(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        WeatherPlatformIcons.shield(context),
                        color: const Color(0xFF69F0AE),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: WeatherSpacing.space3),
                  Text(
                    'No Active Hazards',
                    style: WeatherType.title.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: WeatherSpacing.space1),
                  Text(
                    'Atmospheric telemetry is normal. There are no hazardous weather warnings, watches, or advisories currently in effect for ${weather?.location ?? 'your area'}.',
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
                        const Color(0xFF69F0AE),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (isStorm || hasSevereRisk) ...<Widget>[
            _AlertCard(
              title: 'Flash Flood Warning',
              severity: 'CRITICAL',
              severityColor: const Color(0xFFFF5252),
              timeRange: 'Until 6:00 PM EDT',
              source: 'National Weather Service',
              description:
                  'Torrential rainfall occurring across low-lying areas and roadways. Rapid runoff may cause localized ponding and flash flooding in poor drainage areas. Avoid driving through flooded waters.',
              actions: const <String>[
                'Avoid driving on flooded roads',
                'Move to higher ground if in flood-prone area',
              ],
            ),
            const SizedBox(height: WeatherSpacing.space3),
            _AlertCard(
              title: 'Severe Thunderstorm Watch',
              severity: 'MODERATE',
              severityColor: const Color(0xFFFFB300),
              timeRange: 'Until 9:00 PM EDT',
              source: 'National Weather Service',
              description:
                  'Conditions are favorable for the development of severe thunderstorms capable of producing gusty winds in excess of 45 mph and frequent cloud-to-ground lightning.',
              actions: const <String>[
                'Secure loose outdoor objects',
                'Stay indoors away from windows during lightning',
              ],
            ),
          ] else if (isSnow) ...<Widget>[
            _AlertCard(
              title: 'Winter Weather Advisory',
              severity: 'MODERATE',
              severityColor: WeatherPalette.mistBlue,
              timeRange: 'Until 11:00 AM EST',
              source: 'National Weather Service',
              description:
                  'Snowfall accumulations and slick road conditions expected. Plan on slippery road conditions that could impact morning and evening commutes.',
              actions: const <String>[
                'Slow down and use caution while traveling',
                'Keep an extra flashlight, food, and water in your vehicle',
              ],
            ),
          ] else if (isFog) ...<Widget>[
            _AlertCard(
              title: 'Dense Fog Advisory',
              severity: 'CAUTION',
              severityColor: WeatherPalette.horizonAmber,
              timeRange: 'Until 9:00 AM EDT',
              source: 'National Weather Service',
              description:
                  'Visibility down to one quarter mile or less in dense fog. Hazardous driving conditions due to low visibility.',
              actions: const <String>[
                'Use low-beam headlights',
                'Leave plenty of distance ahead of you',
              ],
            ),
          ] else ...<Widget>[
            _AlertCard(
              title: 'Precipitation & Wind Advisory',
              severity: 'MODERATE',
              severityColor: const Color(0xFFFFB300),
              timeRange: 'Throughout Today',
              source: 'National Weather Service',
              description:
                  'Elevated chances of localized showers and gusty winds up to ${weather?.windSpeedMph.round() ?? 25} mph.',
              actions: const <String>[
                'Keep an umbrella on hand',
                'Exercise caution on wet roadways',
              ],
            ),
          ],
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.severity,
    required this.severityColor,
    required this.timeRange,
    required this.source,
    required this.description,
    required this.actions,
  });

  final String title;
  final String severity;
  final Color severityColor;
  final String timeRange;
  final String source;
  final String description;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return WeatherPlatformCard(
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(WeatherPlatformIcons.warning(context), size: 22, color: severityColor),
              const SizedBox(width: WeatherSpacing.space2),
              Expanded(
                child: Text(
                  title,
                  style: WeatherType.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WeatherPalette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space2),
          Text(
            '$source • $timeRange',
            style: WeatherType.label.copyWith(
              fontSize: 11,
              color: WeatherPalette.textSecondary,
            ),
          ),
          const SizedBox(height: WeatherSpacing.space2),
          Text(
            description,
            style: WeatherType.body.copyWith(
              fontSize: 13,
              color: WeatherPalette.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: WeatherSpacing.space3),
          Container(
            padding: const EdgeInsets.all(WeatherSpacing.space3),
            decoration: BoxDecoration(
              color: WeatherPalette.lensLift.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(WeatherRadii.control),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'RECOMMENDED ACTIONS',
                  style: WeatherType.overline.copyWith(fontSize: 10),
                ),
                const SizedBox(height: WeatherSpacing.space1),
                ...actions.map((String action) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('• ', style: TextStyle(color: WeatherPalette.mistBlue)),
                        Expanded(
                          child: Text(
                            action,
                            style: WeatherType.label.copyWith(
                              fontSize: 12,
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
          ),
        ],
      ),
    );
  }
}
