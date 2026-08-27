import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_condition.dart';

class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    required this.condition,
    super.key,
    this.size = WeatherLayout.weatherGlyphSize,
    this.color = WeatherPalette.textPrimary,
  });

  final WeatherCondition condition;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _WeatherGlyphPainter(condition: condition, color: color),
      ),
    );
  }
}

class _WeatherGlyphPainter extends CustomPainter {
  const _WeatherGlyphPainter({required this.condition, required this.color});

  final WeatherCondition condition;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.4, size.width * 0.045);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke;

    switch (condition) {
      case WeatherCondition.rain:
        _drawCloud(canvas, size, paint);
        for (var index = 0; index < 3; index++) {
          final x = size.width * (0.34 + index * 0.17);
          canvas.drawLine(
            Offset(x, size.height * 0.72),
            Offset(x - size.width * 0.04, size.height * 0.86),
            paint,
          );
        }
      case WeatherCondition.sunny:
        final center = Offset(size.width * 0.5, size.height * 0.48);
        final radius = size.width * 0.18;
        canvas.drawCircle(center, radius, paint);
        for (var index = 0; index < 8; index++) {
          final angle = index * math.pi / 4;
          canvas.drawLine(
            center + Offset.fromDirection(angle, radius * 1.45),
            center + Offset.fromDirection(angle, radius * 1.9),
            paint,
          );
        }
      case WeatherCondition.storm:
        _drawCloud(canvas, size, paint);
        final bolt = Path()
          ..moveTo(size.width * 0.54, size.height * 0.68)
          ..lineTo(size.width * 0.43, size.height * 0.83)
          ..lineTo(size.width * 0.54, size.height * 0.81)
          ..lineTo(size.width * 0.46, size.height * 0.94);
        final boltPaint = Paint()
          ..color = WeatherPalette.horizonAmber
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = stroke;
        canvas.drawPath(bolt, boltPaint);
      case WeatherCondition.cloudy:
        _drawCloud(canvas, size, paint);
      case WeatherCondition.snow:
        _drawCloud(canvas, size, paint);
        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        for (var index = 0; index < 3; index++) {
          final x = size.width * (0.34 + index * 0.17);
          final y = size.height * (0.76 + (index % 2) * 0.08);
          canvas.drawCircle(Offset(x, y), stroke * 0.85, dotPaint);
        }
      case WeatherCondition.fog:
        for (var index = 0; index < 3; index++) {
          final y = size.height * (0.42 + index * 0.18);
          final path = Path()
            ..moveTo(size.width * 0.2, y)
            ..quadraticBezierTo(
              size.width * 0.5,
              y - size.height * 0.04,
              size.width * 0.8,
              y,
            );
          canvas.drawPath(path, paint);
        }
    }
  }

  void _drawCloud(Canvas canvas, Size size, Paint paint) {
    final cloud = Path()
      ..moveTo(size.width * 0.23, size.height * 0.65)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.64,
        size.width * 0.1,
        size.height * 0.46,
        size.width * 0.25,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.21,
        size.width * 0.62,
        size.height * 0.2,
        size.width * 0.69,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.43,
        size.width * 0.91,
        size.height * 0.65,
        size.width * 0.75,
        size.height * 0.67,
      )
      ..close();
    canvas.drawPath(cloud, paint);
  }

  @override
  bool shouldRepaint(_WeatherGlyphPainter oldDelegate) {
    return condition != oldDelegate.condition || color != oldDelegate.color;
  }
}
