import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/mock_weather.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import '../widgets/current_conditions_hero.dart';
import '../widgets/hourly_forecast_rail.dart';
import '../widgets/weather_atmosphere.dart';
import '../widgets/weather_glyph.dart';
import '../widgets/weather_metrics_strip.dart';

class WeatherShowcaseScreen extends StatelessWidget {
  const WeatherShowcaseScreen({
    super.key,
    this.weather = MockWeather.newYorkRain,
    this.atmosphereHour,
  });

  final WeatherModel weather;
  final int? atmosphereHour;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey<String>('showcase-boundary'),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: WeatherAtmosphere(
                condition: weather.condition,
                customHour: atmosphereHour,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final expanded =
                      constraints.maxWidth >= WeatherLayout.expandedBreakpoint;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(WeatherSpacing.space6),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: expanded
                              ? WeatherLayout.expandedContentWidth
                              : WeatherLayout.stackedContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (expanded)
                              _ExpandedShowcase(weather: weather)
                            else
                              _StackedShowcase(weather: weather),
                            const SizedBox(height: WeatherSpacing.space16),
                            const _CatalogueHeader(),
                            const SizedBox(height: WeatherSpacing.space8),
                            const _ConditionSpecimens(),
                            const SizedBox(height: WeatherSpacing.space8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedShowcase extends StatelessWidget {
  const _StackedShowcase({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: WeatherSpacing.space8),
          child: CurrentConditionsHero(weather: weather),
        ),
        const SizedBox(height: WeatherSpacing.space8),
        HourlyForecastRail(forecasts: weather.hourly),
        const SizedBox(height: WeatherSpacing.space10),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WeatherSpacing.space2,
          ),
          child: WeatherMetricsStrip(weather: weather),
        ),
      ],
    );
  }
}

class _ExpandedShowcase extends StatelessWidget {
  const _ExpandedShowcase({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.only(right: WeatherSpacing.space12),
            child: CurrentConditionsHero(weather: weather, expanded: true),
          ),
        ),
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              HourlyForecastRail(forecasts: weather.hourly),
              const SizedBox(height: WeatherSpacing.space12),
              WeatherMetricsStrip(weather: weather),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogueHeader extends StatelessWidget {
  const _CatalogueHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('PRIMITIVE SHOWCASE', style: WeatherType.overline),
        const SizedBox(height: WeatherSpacing.space3),
        Text('WeatherOS optical system', style: WeatherType.title),
      ],
    );
  }
}

class _ConditionSpecimens extends StatelessWidget {
  const _ConditionSpecimens();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Weather glyph variants: rain, sunny, storm, and cloudy.',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('WEATHER GLYPH VARIANTS', style: WeatherType.overline),
            const SizedBox(height: WeatherSpacing.space4),
            Wrap(
              spacing: WeatherSpacing.space8,
              runSpacing: WeatherSpacing.space4,
              children: WeatherCondition.values
                  .map(
                    (WeatherCondition condition) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        WeatherGlyph(
                          condition: condition,
                          size: WeatherLayout.specimenGlyphSize,
                        ),
                        const SizedBox(width: WeatherSpacing.space2),
                        Text(condition.label, style: WeatherType.label),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
