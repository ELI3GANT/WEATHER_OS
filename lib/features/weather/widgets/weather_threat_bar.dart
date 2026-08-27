import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/hourly_forecast.dart';

class WeatherThreatBar extends StatelessWidget {
  const WeatherThreatBar({
    required this.forecasts,
    super.key,
  });

  final List<HourlyForecast> forecasts;

  Color _threatColor(String threat) {
    return switch (threat.toLowerCase()) {
      'high' => const Color(0xFFFF5252),
      'moderate' => const Color(0xFFFFB300),
      _ => const Color(0xFF69F0AE),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Segment forecasts into threat zones
    final segments = <_ThreatSegment>[];
    for (final f in forecasts) {
      final color = _threatColor(f.threatLevel);
      final label = f.threatLevel.toUpperCase();
      if (segments.isNotEmpty && segments.last.threat == label) {
        segments.last.count++;
      } else {
        segments.add(_ThreatSegment(threat: label, color: color, count: 1));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Row(
              children: segments.map((_ThreatSegment s) {
                return Expanded(
                  flex: s.count,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
        const SizedBox(height: WeatherSpacing.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: segments.map((_ThreatSegment s) {
            return Text(
              s.threat,
              style: WeatherType.overline.copyWith(
                color: s.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ThreatSegment {
  _ThreatSegment({
    required this.threat,
    required this.color,
    required this.count,
  });

  final String threat;
  final Color color;
  int count;
}
