import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import 'glass_lens.dart';

class WeatherAlertsView extends StatelessWidget {
  const WeatherAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '2 WARNINGS',
                  style: WeatherType.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF5252),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),
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
        ],
      ),
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
    return GlassLens(
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 22, color: severityColor),
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
