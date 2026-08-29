import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/utils/weather_formatters.dart';
import '../models/weather_atmosphere_state.dart';
import '../models/weather_model.dart';
import 'weather_glyph.dart';

class CurrentConditionsHero extends StatelessWidget {
  const CurrentConditionsHero({
    required this.weather,
    super.key,
    this.expanded = false,
  });

  final WeatherModel weather;
  final bool expanded;

  Color _riskBadgeColor(String risk) {
    return switch (risk.toUpperCase()) {
      'HIGH RISK' => const Color(0xFFFF5252),
      'MODERATE RISK' => const Color(0xFFFFB300),
      _ => const Color(0xFF69F0AE),
    };
  }

  Widget _buildAnimatedText(String text, TextStyle style, Key key) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: key,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskBadgeColor(weather.riskLevel);
    final atmosphereState = WeatherAtmosphereState.fromWeather(weather);

    return Semantics(
      container: true,
      label:
          '${weather.location}. ${weather.temperature.round()} degrees. '
          '${weather.condition.label}. Feels like ${weather.feelsLike.round()} '
          'degrees. High ${weather.high.round()}, low ${weather.low.round()}.',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isCompact = constraints.maxWidth < 500;

          return WeatherPlatformCard(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (isCompact) ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: WeatherGlyph(
                          key: ValueKey('glyph_${weather.condition.name}'),
                          condition: weather.condition,
                          size: 64,
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: <Widget>[
                                _buildAnimatedText(
                                  WeatherFormatters.degrees(weather.temperature),
                                  WeatherType.temperature.copyWith(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  ValueKey('temp_${weather.temperature.round()}'),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'F',
                                  style: WeatherType.label.copyWith(
                                    fontSize: 18,
                                    color: WeatherPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            _buildAnimatedText(
                              'Feels like ${WeatherFormatters.degrees(weather.feelsLike)}',
                              WeatherType.label.copyWith(
                                color: WeatherPalette.textSecondary,
                                fontSize: 13,
                              ),
                              ValueKey('feels_${weather.feelsLike.round()}'),
                            ),
                            const SizedBox(height: 2),
                            _buildAnimatedText(
                              weather.condition.label,
                              WeatherType.title.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: WeatherPalette.textPrimary,
                              ),
                              ValueKey('label_${weather.condition.name}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WeatherSpacing.space3),
                  Container(
                    padding: const EdgeInsets.all(WeatherSpacing.space3),
                    decoration: BoxDecoration(
                      color: WeatherPalette.lensLift.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(WeatherRadii.control),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('DAY SUMMARY', style: WeatherType.overline.copyWith(fontSize: 9)),
                        const SizedBox(height: 4),
                        Text(
                          atmosphereState.storyLine,
                          style: WeatherType.body.copyWith(
                            fontSize: 12,
                            color: WeatherPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: WeatherSpacing.space2),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: riskColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(WeatherRadii.pill),
                                border: Border.all(
                                  color: riskColor.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.shield_outlined, size: 12, color: riskColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    weather.riskLevel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: riskColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'H ${WeatherFormatters.degrees(weather.high)}  L ${WeatherFormatters.degrees(weather.low)}',
                              style: WeatherType.label.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WeatherPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...<Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: WeatherGlyph(
                          key: ValueKey('glyph_${weather.condition.name}'),
                          condition: weather.condition,
                          size: 80,
                        ),
                      ),
                      const SizedBox(width: WeatherSpacing.space4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              _buildAnimatedText(
                                WeatherFormatters.degrees(weather.temperature),
                                WeatherType.temperature.copyWith(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w700,
                                ),
                                ValueKey('temp_${weather.temperature.round()}'),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'F',
                                style: WeatherType.label.copyWith(
                                  fontSize: 22,
                                  color: WeatherPalette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          _buildAnimatedText(
                            'Feels like ${WeatherFormatters.degrees(weather.feelsLike)}',
                            WeatherType.label.copyWith(
                              color: WeatherPalette.textSecondary,
                              fontSize: 14,
                            ),
                            ValueKey('feels_${weather.feelsLike.round()}'),
                          ),
                          _buildAnimatedText(
                            weather.condition.label,
                            WeatherType.title.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            ValueKey('label_${weather.condition.name}'),
                          ),
                        ],
                      ),
                      const SizedBox(width: WeatherSpacing.space5),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(WeatherSpacing.space3),
                          decoration: BoxDecoration(
                            color: WeatherPalette.lensLift.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(WeatherRadii.control),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('DAY SUMMARY', style: WeatherType.overline),
                              const SizedBox(height: 4),
                              Text(
                                atmosphereState.storyLine,
                                style: WeatherType.body.copyWith(
                                  fontSize: 13,
                                  color: WeatherPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: WeatherSpacing.space2),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: WeatherSpacing.space2,
                                runSpacing: WeatherSpacing.space1,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: riskColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                        WeatherRadii.pill,
                                      ),
                                      border: Border.all(
                                        color: riskColor.withValues(alpha: 0.45),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.shield_outlined,
                                          size: 13,
                                          color: riskColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          weather.riskLevel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: riskColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'H ${WeatherFormatters.degrees(weather.high)}  L ${WeatherFormatters.degrees(weather.low)}',
                                    style: WeatherType.label.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: WeatherPalette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
