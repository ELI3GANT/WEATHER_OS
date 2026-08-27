import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_model.dart';
import 'glass_lens.dart';
import 'weather_glyph.dart';

/// Premium smoked-glass 7-day weekly outlook card with interactive thermal spectrum bars.
class WeatherWeeklyOutlookCard extends StatefulWidget {
  const WeatherWeeklyOutlookCard({
    required this.weather,
    this.isStandalone = false,
    super.key,
  });

  final WeatherModel weather;
  final bool isStandalone;

  @override
  State<WeatherWeeklyOutlookCard> createState() =>
      _WeatherWeeklyOutlookCardState();
}

class _WeatherWeeklyOutlookCardState extends State<WeatherWeeklyOutlookCard> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final dailyList = widget.weather.dailyForecasts;
    if (dailyList.isEmpty) {
      return const SizedBox.shrink();
    }

    final minOverall =
        dailyList.map((d) => d.low).reduce((a, b) => a < b ? a : b);
    final maxOverall =
        dailyList.map((d) => d.high).reduce((a, b) => a > b ? a : b);
    final range = (maxOverall - minOverall).clamp(1.0, 100.0);
    final currentTemp = widget.weather.temperature;

    return GlassLens(
      padding: const EdgeInsets.symmetric(
        vertical: WeatherSpacing.space3,
        horizontal: WeatherSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Section Header
          Row(
            children: <Widget>[
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: WeatherPalette.mistBlue.withValues(alpha: 0.9),
              ),
              const SizedBox(width: WeatherSpacing.space2),
              Text(
                '7-DAY FORECAST OUTLOOK',
                style: WeatherType.overline.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // Daily rows
          ...List<Widget>.generate(dailyList.length, (int index) {
            final item = dailyList[index];
            final isToday = index == 0 || item.dayLabel == 'Today';
            final isExpanded = _expandedIndex == index;

            final startNorm =
                ((item.low - minOverall) / range).clamp(0.0, 1.0);
            final endNorm =
                ((item.high - minOverall) / range).clamp(0.0, 1.0);
            final currentNorm = isToday
                ? ((currentTemp - minOverall) / range).clamp(0.0, 1.0)
                : null;

            return Column(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(WeatherRadii.control),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: WeatherSpacing.space2,
                      horizontal: WeatherSpacing.space1,
                    ),
                    child: Row(
                      children: <Widget>[
                        // Day Name
                        SizedBox(
                          width: 80,
                          child: Text(
                            item.dayLabel,
                            style: WeatherType.label.copyWith(
                              fontSize: 14,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday
                                  ? WeatherPalette.textPrimary
                                  : WeatherPalette.textSecondary,
                            ),
                          ),
                        ),

                        // Weather Condition Glyph
                        WeatherGlyph(condition: item.condition, size: 22),
                        const SizedBox(width: WeatherSpacing.space2),

                        // Rain probability badge
                        SizedBox(
                          width: 38,
                          child: Text(
                            item.precipChance > 0
                                ? '${item.precipChance}%'
                                : '',
                            style: WeatherType.label.copyWith(
                              fontSize: 11,
                              color: WeatherPalette.mistBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // Low temp
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.low.round()}°',
                            textAlign: TextAlign.right,
                            style: WeatherType.label.copyWith(
                              fontSize: 13,
                              color: WeatherPalette.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: WeatherSpacing.space2),

                        // Thermal Spectrum Bar
                        Expanded(
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              final barWidth = constraints.maxWidth;
                              final left = startNorm * barWidth;
                              final width = ((endNorm - startNorm) * barWidth)
                                  .clamp(10.0, barWidth);

                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: <Widget>[
                                  // Background track
                                  Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: WeatherPalette.lensLift
                                          .withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(
                                          WeatherRadii.pill),
                                    ),
                                  ),
                                  // Range bar
                                  Positioned(
                                    left: left,
                                    child: Container(
                                      width: width,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: <Color>[
                                            WeatherPalette.mistBlue,
                                            WeatherPalette.horizonAmber,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            WeatherRadii.pill),
                                      ),
                                    ),
                                  ),
                                  // Current temperature indicator dot (for Today)
                                  if (currentNorm != null)
                                    Positioned(
                                      left: (currentNorm * barWidth - 4).clamp(
                                          0.0, barWidth - 8.0),
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: WeatherPalette.textPrimary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: WeatherPalette.lensCore,
                                            width: 1.5,
                                          ),
                                          boxShadow: const <BoxShadow>[
                                            BoxShadow(
                                              color: WeatherPalette.mistBlue,
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: WeatherSpacing.space2),

                        // High temp
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${item.high.round()}°',
                            textAlign: TextAlign.right,
                            style: WeatherType.metricValue.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: WeatherPalette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expandable Telemetry Drawer
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    margin: const EdgeInsets.only(
                      top: WeatherSpacing.space1,
                      bottom: WeatherSpacing.space2,
                    ),
                    padding: const EdgeInsets.all(WeatherSpacing.space3),
                    decoration: BoxDecoration(
                      color: WeatherPalette.lensCore.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(WeatherRadii.control),
                      border: Border.all(
                        color: WeatherPalette.mistBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        _buildDetailMetric(
                          icon: Icons.wb_sunny_rounded,
                          label: 'UV INDEX',
                          value: '${item.uvIndex}',
                        ),
                        _buildDetailMetric(
                          icon: Icons.water_drop_rounded,
                          label: 'PRECIP RAIN',
                          value: '${item.totalRainInches.toStringAsFixed(2)}" (${item.precipChance}%)',
                        ),
                        if (item.sunrise != null)
                          _buildDetailMetric(
                            icon: Icons.wb_twilight_rounded,
                            label: 'SUNRISE',
                            value: item.sunrise!,
                          ),
                        if (item.sunset != null)
                          _buildDetailMetric(
                            icon: Icons.nights_stay_rounded,
                            label: 'SUNSET',
                            value: item.sunset!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: WeatherPalette.mistBlue),
        const SizedBox(height: 2),
        Text(
          label,
          style: WeatherType.label.copyWith(
            fontSize: 9,
            letterSpacing: 0.8,
            color: WeatherPalette.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WeatherType.label.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: WeatherPalette.textPrimary,
          ),
        ),
      ],
    );
  }
}
