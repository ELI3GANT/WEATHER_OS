import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_condition.dart';

class WeatherGlyph extends StatefulWidget {
  const WeatherGlyph({
    required this.condition,
    super.key,
    this.size = WeatherLayout.weatherGlyphSize,
    this.color = WeatherPalette.textPrimary,
    this.animate = true,
  });

  final WeatherCondition condition;
  final double size;
  final Color color;
  final bool animate;

  @override
  State<WeatherGlyph> createState() => _WeatherGlyphState();
}

class _WeatherGlyphState extends State<WeatherGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _WeatherGlyphPainter(
            condition: widget.condition,
            color: widget.color,
            progress: 0.0,
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _WeatherGlyphPainter(
              condition: widget.condition,
              color: widget.color,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _WeatherGlyphPainter extends CustomPainter {
  const _WeatherGlyphPainter({
    required this.condition,
    required this.color,
    required this.progress,
  });

  final WeatherCondition condition;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.5, size.width * 0.048);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke;

    final bobOffset = math.sin(progress * math.pi * 2) * (size.height * 0.025);

    switch (condition) {
      case WeatherCondition.rain:
        canvas.save();
        canvas.translate(0, bobOffset);
        _drawCloud(canvas, size, paint);
        canvas.restore();

        // Kinetic falling rain drops
        final rainPaint = Paint()
          ..color = WeatherPalette.mistBlue
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke * 0.95;

        for (var index = 0; index < 3; index++) {
          final phase = (progress * 2.5 + index * 0.33) % 1.0;
          final x = size.width * (0.32 + index * 0.18);
          final startY = size.height * (0.68 + phase * 0.16);
          final endY = startY + size.height * 0.1;
          if (startY < size.height * 0.92) {
            canvas.drawLine(
              Offset(x, startY),
              Offset(x - size.width * 0.03, endY.clamp(0, size.height * 0.94)),
              rainPaint..color = WeatherPalette.mistBlue.withValues(alpha: (1.0 - phase * 0.5).clamp(0.2, 1.0)),
            );
          }
        }

      case WeatherCondition.sunny:
        final center = Offset(size.width * 0.5, size.height * 0.5);
        final radius = size.width * 0.2;
        
        // Sun core
        canvas.drawCircle(center, radius, paint);

        // Rotating sun rays
        final rotAngle = progress * math.pi * 2;
        for (var index = 0; index < 8; index++) {
          final angle = rotAngle + (index * math.pi / 4);
          canvas.drawLine(
            center + Offset.fromDirection(angle, radius * 1.35),
            center + Offset.fromDirection(angle, radius * 1.8),
            paint..color = WeatherPalette.horizonAmber,
          );
        }

      case WeatherCondition.storm:
        canvas.save();
        canvas.translate(0, bobOffset);
        _drawCloud(canvas, size, paint);
        canvas.restore();

        // Flashing kinetic lightning
        final boltFlash = (math.sin(progress * 8 * math.pi) > 0.3);
        final bolt = Path()
          ..moveTo(size.width * 0.54, size.height * 0.66)
          ..lineTo(size.width * 0.43, size.height * 0.81)
          ..lineTo(size.width * 0.54, size.height * 0.79)
          ..lineTo(size.width * 0.45, size.height * 0.95);
        final boltPaint = Paint()
          ..color = boltFlash ? Colors.white : WeatherPalette.horizonAmber
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = stroke * 1.2;
        canvas.drawPath(bolt, boltPaint);

      case WeatherCondition.cloudy:
        canvas.save();
        canvas.translate(0, bobOffset);
        _drawCloud(canvas, size, paint);
        canvas.restore();

      case WeatherCondition.snow:
        canvas.save();
        canvas.translate(0, bobOffset);
        _drawCloud(canvas, size, paint);
        canvas.restore();

        // Oscillating snowflakes
        final dotPaint = Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        for (var index = 0; index < 3; index++) {
          final sway = math.sin((progress * 3 * math.pi) + index) * 3.0;
          final x = size.width * (0.34 + index * 0.17) + sway;
          final y = size.height * (0.75 + (index % 2) * 0.08);
          canvas.drawCircle(Offset(x, y), stroke * 0.9, dotPaint);
        }

      case WeatherCondition.fog:
        for (var index = 0; index < 3; index++) {
          final waveDrift = math.sin((progress * 2 * math.pi) + (index * 0.8)) * (size.width * 0.04);
          final y = size.height * (0.38 + index * 0.18);
          final path = Path()
            ..moveTo(size.width * 0.18 + waveDrift, y)
            ..quadraticBezierTo(
              size.width * 0.5 + waveDrift,
              y - size.height * 0.04,
              size.width * 0.82 + waveDrift,
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
    return condition != oldDelegate.condition ||
        color != oldDelegate.color ||
        progress != oldDelegate.progress;
  }
}
