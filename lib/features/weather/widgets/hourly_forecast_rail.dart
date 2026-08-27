import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/utils/weather_formatters.dart';
import '../models/hourly_forecast.dart';
import 'glass_lens.dart';
import 'weather_glyph.dart';
import 'weather_threat_bar.dart';

class HourlyForecastRail extends StatelessWidget {
  const HourlyForecastRail({
    required this.forecasts,
    super.key,
    this.selectedIndex,
    this.onForecastSelected,
  });

  final List<HourlyForecast> forecasts;
  final int? selectedIndex;
  final ValueChanged<int>? onForecastSelected;

  @override
  Widget build(BuildContext context) {
    return GlassLens(
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  'HOURLY FORECAST',
                  style: WeatherType.overline,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'LIVE RADAR SYNC',
                  style: WeatherType.overline.copyWith(
                    color: WeatherPalette.mistBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),
          SizedBox(
            height: 140,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final fits =
                    constraints.maxWidth >=
                    forecasts.length * WeatherLayout.forecastFitWidth;
                if (fits) {
                  return Row(
                    children: List<Widget>.generate(
                      forecasts.length,
                      (int index) => Expanded(
                        child: _ForecastCell(
                          forecast: forecasts[index],
                          isSelected: index == selectedIndex,
                          onTap: onForecastSelected != null
                              ? () => onForecastSelected!(index)
                              : null,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: forecasts.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: WeatherSpacing.space2),
                  itemBuilder: (BuildContext context, int index) => SizedBox(
                    width: WeatherLayout.forecastCellWidth,
                    child: _ForecastCell(
                      forecast: forecasts[index],
                      isSelected: index == selectedIndex,
                      onTap: onForecastSelected != null
                          ? () => onForecastSelected!(index)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: WeatherSpacing.space2),
          WeatherThreatBar(forecasts: forecasts),
        ],
      ),
    );
  }
}

class _ForecastCell extends StatelessWidget {
  const _ForecastCell({
    required this.forecast,
    required this.isSelected,
    this.onTap,
  });

  final HourlyForecast forecast;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = isSelected;
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label:
          '${forecast.timeLabel}, ${forecast.temperature.round()} degrees, '
          '${forecast.condition.label}, ${forecast.precipChance} percent chance of rain',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WeatherRadii.control),
        child: AnimatedScale(
          scale: active ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: active
                  ? WeatherPalette.mistBlue.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(WeatherRadii.control),
              border: active
                  ? Border.all(
                      color: WeatherPalette.mistBlue.withValues(alpha: 0.5),
                      width: 1.2,
                    )
                  : null,
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: WeatherPalette.mistBlue.withValues(alpha: 0.18),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    forecast.timeLabel,
                    maxLines: 1,
                    style: WeatherType.label.copyWith(
                      color: active
                          ? WeatherPalette.textPrimary
                          : WeatherPalette.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                WeatherGlyph(
                  condition: forecast.condition,
                  size: WeatherLayout.forecastGlyphSize,
                  color: active
                      ? WeatherPalette.textPrimary
                      : WeatherPalette.textSecondary,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    WeatherFormatters.degrees(forecast.temperature),
                    style: WeatherType.metricValue.copyWith(
                      fontSize: WeatherLayout.forecastTemperatureSize,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? WeatherPalette.textPrimary
                          : WeatherPalette.textSecondary,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${forecast.precipChance}%',
                    style: WeatherType.label.copyWith(
                      fontSize: 11,
                      color: forecast.precipChance > 50
                          ? WeatherPalette.mistBlue
                          : WeatherPalette.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
