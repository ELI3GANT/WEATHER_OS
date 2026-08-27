import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';

enum WeatherMetricKind { humidity, wind, uv, pressure }

class MetricGlyph extends StatelessWidget {
  const MetricGlyph({
    required this.kind,
    super.key,
    this.size = WeatherLayout.metricGlyphSize,
    this.color = WeatherPalette.mistBlue,
  });

  final WeatherMetricKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MetricGlyphPainter(kind: kind, color: color),
      ),
    );
  }
}

class _MetricGlyphPainter extends CustomPainter {
  const _MetricGlyphPainter({required this.kind, required this.color});

  final WeatherMetricKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.2, size.width * 0.055);

    switch (kind) {
      case WeatherMetricKind.humidity:
        final drop = Path()
          ..moveTo(size.width * 0.5, size.height * 0.08)
          ..cubicTo(
            size.width * 0.22,
            size.height * 0.43,
            size.width * 0.16,
            size.height * 0.61,
            size.width * 0.18,
            size.height * 0.7,
          )
          ..cubicTo(
            size.width * 0.24,
            size.height * 0.99,
            size.width * 0.76,
            size.height * 0.99,
            size.width * 0.82,
            size.height * 0.7,
          )
          ..cubicTo(
            size.width * 0.84,
            size.height * 0.57,
            size.width * 0.72,
            size.height * 0.38,
            size.width * 0.5,
            size.height * 0.08,
          );
        canvas.drawPath(drop, paint);
      case WeatherMetricKind.wind:
        for (var index = 0; index < 3; index++) {
          final y = size.height * (0.3 + index * 0.2);
          canvas.drawLine(
            Offset(size.width * 0.08, y),
            Offset(size.width * (0.58 + index * 0.09), y),
            paint,
          );
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(size.width * (0.66 + index * 0.08), y - 2),
              radius: size.width * 0.13,
            ),
            -math.pi / 2,
            math.pi * 1.25,
            false,
            paint,
          );
        }
      case WeatherMetricKind.uv:
        final center = Offset(size.width * 0.5, size.height * 0.5);
        final radius = size.width * 0.16;
        canvas.drawCircle(center, radius, paint);
        for (var index = 0; index < 8; index++) {
          final angle = index * math.pi / 4;
          canvas.drawLine(
            center + Offset.fromDirection(angle, radius * 1.55),
            center + Offset.fromDirection(angle, radius * 2.15),
            paint,
          );
        }
      case WeatherMetricKind.pressure:
        final center = Offset(size.width * 0.5, size.height * 0.52);
        canvas.drawCircle(center, size.width * 0.38, paint);
        canvas.drawLine(
          center,
          center + Offset.fromDirection(-math.pi / 4, size.width * 0.24),
          paint,
        );
        canvas.drawCircle(center, size.width * 0.035, paint);
    }
  }

  @override
  bool shouldRepaint(_MetricGlyphPainter oldDelegate) {
    return kind != oldDelegate.kind || color != oldDelegate.color;
  }
}
