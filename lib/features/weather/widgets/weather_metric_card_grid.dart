import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_model.dart';
import 'glass_lens.dart';

class WeatherMetricCardGrid extends StatelessWidget {
  const WeatherMetricCardGrid({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final cards = <_CardData>[
      _CardData(
        label: 'PRECIP CHANCE',
        value: '${weather.precipChance}%',
        subValue: weather.precipChance > 60 ? 'High' : (weather.precipChance > 30 ? 'Moderate' : 'Low'),
        subColor: weather.precipChance > 60 ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
        icon: Icons.water_drop_outlined,
      ),
      _CardData(
        label: 'TOTAL RAIN',
        value: '${weather.totalRainInches.toStringAsFixed(2)} in',
        subValue: 'Today',
        subColor: WeatherPalette.mistBlue,
        icon: Icons.grain_outlined,
      ),
      _CardData(
        label: 'HUMIDITY',
        value: '${weather.humidity}%',
        subValue: weather.humidity > 80 ? 'Very High' : 'Normal',
        subColor: weather.humidity > 80 ? const Color(0xFFFF5252) : WeatherPalette.textSecondary,
        icon: Icons.opacity,
      ),
      _CardData(
        label: 'WIND',
        value: '${weather.windSpeedMph.round()} mph',
        subValue: weather.windDirectionCompass,
        subColor: WeatherPalette.mistBlue,
        icon: Icons.air,
      ),
      _CardData(
        label: 'VISIBILITY',
        value: '${weather.visibilityMiles.round()} mi',
        subValue: weather.visibilityMiles >= 6 ? 'Good' : 'Reduced',
        subColor: const Color(0xFF69F0AE),
        icon: Icons.visibility_outlined,
      ),
      _CardData(
        label: 'UV INDEX',
        value: '${weather.uvIndex}',
        subValue: weather.uvIndex <= 2 ? 'Low' : (weather.uvIndex <= 5 ? 'Moderate' : 'High'),
        subColor: const Color(0xFF69F0AE),
        icon: Icons.wb_sunny_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            children: cards.map((_CardData c) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildCard(c),
                ),
              );
            }).toList(growable: false),
          );
        }

        // 2 rows of 3
        final row1 = cards.sublist(0, 3);
        final row2 = cards.sublist(3, 6);

        return Column(
          children: <Widget>[
            Row(
              children: row1.map((_CardData c) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildCard(c),
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: WeatherSpacing.space2),
            Row(
              children: row2.map((_CardData c) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildCard(c),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(_CardData c) {
    return GlassLens(
      padding: const EdgeInsets.symmetric(
        vertical: WeatherSpacing.space3,
        horizontal: WeatherSpacing.space2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(c.icon, size: 20, color: WeatherPalette.mistBlue),
          const SizedBox(height: WeatherSpacing.space1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              c.label,
              style: WeatherType.overline.copyWith(
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: WeatherSpacing.space1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              c.value,
              style: WeatherType.metricValue.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              c.subValue,
              style: WeatherType.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.subColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardData {
  const _CardData({
    required this.label,
    required this.value,
    required this.subValue,
    required this.subColor,
    required this.icon,
  });

  final String label;
  final String value;
  final String subValue;
  final Color subColor;
  final IconData icon;
}
