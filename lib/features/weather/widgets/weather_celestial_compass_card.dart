import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_model.dart';
import 'glass_lens.dart';

class WeatherCelestialCompassCard extends StatelessWidget {
  const WeatherCelestialCompassCard({
    required this.weather,
    super.key,
  });

  final WeatherModel weather;

  double _calculateSolarProgress() {
    final now = DateTime.now();
    // Default daytime curve calculation (approx 6 AM to 8 PM)
    final currentHourDec = now.hour + (now.minute / 60.0);
    const sunriseDec = 5.6; // 5:36 AM
    const sunsetDec = 20.13; // 8:08 PM
    if (currentHourDec <= sunriseDec) return 0.05;
    if (currentHourDec >= sunsetDec) return 0.95;
    return ((currentHourDec - sunriseDec) / (sunsetDec - sunriseDec)).clamp(0.05, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    final solarProgress = _calculateSolarProgress();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 500;

        final sunCard = GlassLens(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('SUN & DAYLIGHT', style: WeatherType.overline),
              const SizedBox(height: WeatherSpacing.space3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Celestial Dynamic Timeline
                  SizedBox(
                    height: 110,
                    width: 28,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        const Positioned(
                          top: 0,
                          child: Icon(Icons.wb_sunny_rounded, size: 20, color: WeatherPalette.horizonAmber),
                        ),
                        Positioned(
                          top: 24,
                          bottom: 24,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  WeatherPalette.horizonAmber.withValues(alpha: 0.6),
                                  WeatherPalette.mistBlue.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 24 + (solarProgress * (110 - 48 - 12)),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: WeatherPalette.horizonAmber,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: WeatherPalette.horizonAmber.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          bottom: 0,
                          child: Icon(Icons.nightlight_round, size: 18, color: WeatherPalette.mistBlue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: WeatherSpacing.space3),
                  // Labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          weather.sunriseTime,
                          style: WeatherType.metricValue.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text('Sunrise', style: WeatherType.label.copyWith(fontSize: 11)),
                        const SizedBox(height: WeatherSpacing.space2),
                        Text(
                          weather.daylightDuration,
                          style: WeatherType.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: WeatherPalette.horizonAmber,
                          ),
                        ),
                        Text('Daylight', style: WeatherType.label.copyWith(fontSize: 10, color: WeatherPalette.textTertiary)),
                        const SizedBox(height: WeatherSpacing.space2),
                        Text(
                          weather.sunsetTime,
                          style: WeatherType.metricValue.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text('Sunset', style: WeatherType.label.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final compassCard = GlassLens(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('WIND', style: WeatherType.overline),
              ),
              const SizedBox(height: WeatherSpacing.space2),
              Text(
                weather.windDirectionCompass,
                style: WeatherType.metricValue.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text('Direction', style: WeatherType.label.copyWith(fontSize: 11)),
              const SizedBox(height: WeatherSpacing.space2),
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _CompassDialPainter(bearingDegrees: weather.windBearingDegrees),
                ),
              ),
              const SizedBox(height: WeatherSpacing.space2),
              Text(
                '${weather.windSpeedMph.round()} mph',
                style: WeatherType.metricValue.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text('Speed', style: WeatherType.label.copyWith(fontSize: 11)),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 11, child: sunCard),
              const SizedBox(width: WeatherSpacing.space3),
              Expanded(flex: 9, child: compassCard),
            ],
          );
        }

        return Column(
          children: <Widget>[
            sunCard,
            const SizedBox(height: WeatherSpacing.space3),
            compassCard,
          ],
        );
      },
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  const _CompassDialPainter({required this.bearingDegrees});

  final double bearingDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Circle Ring
    final ringPaint = Paint()
      ..color = WeatherPalette.lensLift.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 2, ringPaint);

    // Cardinal Direction Labels
    final cardinals = ['N', 'E', 'S', 'W'];
    final labelStyle = WeatherType.label.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: WeatherPalette.textSecondary,
    );

    for (var i = 0; i < 4; i++) {
      final angle = (i * 90) * math.pi / 180;
      final textPainter = TextPainter(
        text: TextSpan(text: cardinals[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 12);
      textPainter.paint(canvas, Offset(pos.dx - (textPainter.width / 2), pos.dy - (textPainter.height / 2)));
    }

    // Rotating Wind Needle Arrow
    final rad = bearingDegrees * math.pi / 180;
    final needleLen = radius - 16;
    final target = center + Offset(math.sin(rad), -math.cos(rad)) * needleLen;
    final tail = center - Offset(math.sin(rad), -math.cos(rad)) * (needleLen * 0.45);

    final needlePaint = Paint()
      ..color = WeatherPalette.mistBlue
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, target, needlePaint);

    // Center pivot dot
    canvas.drawCircle(center, 4, Paint()..color = WeatherPalette.textPrimary);
    canvas.drawCircle(center, 2, Paint()..color = WeatherPalette.canvasDeep);
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.bearingDegrees != bearingDegrees;
}
