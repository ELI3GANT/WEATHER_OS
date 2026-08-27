import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/utils/weather_formatters.dart';
import '../models/weather_model.dart';
import 'metric_glyph.dart';

class WeatherMetricsStrip extends StatelessWidget {
  const WeatherMetricsStrip({required this.weather, super.key});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricData>[
      _MetricData(
        kind: WeatherMetricKind.humidity,
        label: 'HUMIDITY',
        value: '${weather.humidity}%',
        semanticValue: '${weather.humidity} percent',
      ),
      _MetricData(
        kind: WeatherMetricKind.wind,
        label: 'WIND',
        value: '${weather.windSpeedMph.round()} MPH',
        semanticValue: '${weather.windSpeedMph.round()} miles per hour',
      ),
      _MetricData(
        kind: WeatherMetricKind.uv,
        label: 'UV',
        value: '${weather.uvIndex}',
        semanticValue: 'index ${weather.uvIndex}',
      ),
      _MetricData(
        kind: WeatherMetricKind.pressure,
        label: 'PRESSURE',
        value: WeatherFormatters.pressure(weather.pressureInHg),
        semanticValue:
            '${WeatherFormatters.pressure(weather.pressureInHg)} '
            'inches of mercury',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < WeatherLayout.narrowMetricsBreakpoint) {
          return Wrap(
            runSpacing: WeatherSpacing.space8,
            children: metrics
                .map(
                  (_MetricData metric) => SizedBox(
                    width: constraints.maxWidth / 2,
                    child: _MetricItem(metric: metric),
                  ),
                )
                .toList(growable: false),
          );
        }
        return Row(
          children: <Widget>[
            for (var index = 0; index < metrics.length; index++) ...<Widget>[
              Expanded(child: _MetricItem(metric: metrics[index])),
              if (index < metrics.length - 1)
                Container(
                  width: WeatherLayout.metricDividerWidth,
                  height: WeatherLayout.metricDividerHeight,
                  color: WeatherPalette.lensRim.withValues(
                    alpha: WeatherOptics.dividerOpacity,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.label}, ${metric.semanticValue}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MetricGlyph(kind: metric.kind),
            const SizedBox(height: WeatherSpacing.space2),
            Text(metric.label, style: WeatherType.overline),
            const SizedBox(height: WeatherSpacing.space2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(metric.value, style: WeatherType.metricValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.kind,
    required this.label,
    required this.value,
    required this.semanticValue,
  });

  final WeatherMetricKind kind;
  final String label;
  final String value;
  final String semanticValue;
}
