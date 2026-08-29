import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';

const List<({double x, double y, double width, double height})> _clusters =
    <({double x, double y, double width, double height})>[
      (x: 0.83, y: 0.17, width: 0.62, height: 0.28),
      (x: 0.68, y: 0.27, width: 0.54, height: 0.24),
      (x: 0.92, y: 0.36, width: 0.72, height: 0.31),
      (x: 0.6, y: 0.45, width: 0.64, height: 0.27),
      (x: 0.82, y: 0.54, width: 0.76, height: 0.32),
      (x: 0.61, y: 0.65, width: 0.68, height: 0.29),
      (x: 0.91, y: 0.73, width: 0.62, height: 0.26),
    ];

// Pre-cached unit billow paths to eliminate runtime GC allocations per frame
final List<Path> _cachedUnitBillowPaths = List<Path>.generate(
  26,
  (int i) => _generateUnitBillow(i),
  growable: false,
);

Path _generateUnitBillow(int seed) {
  const pointCount = 10;
  final points = <Offset>[];
  for (var index = 0; index < pointCount; index++) {
    final angle = math.pi * 2 * index / pointCount;
    final variation = 0.72 + _unit(seed * 71 + index * 13) * 0.36;
    points.add(
      Offset(math.cos(angle), math.sin(angle)) * variation,
    );
  }

  Offset midpoint(Offset first, Offset second) =>
      Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);

  final path = Path()
    ..moveTo(
      midpoint(points.last, points.first).dx,
      midpoint(points.last, points.first).dy,
    );
  for (var index = 0; index < points.length; index++) {
    final next = points[(index + 1) % points.length];
    final end = midpoint(points[index], next);
    path.quadraticBezierTo(points[index].dx, points[index].dy, end.dx, end.dy);
  }
  return path..close();
}

void drawAtmosphericClouds(
  Canvas canvas,
  Size size, {
  required double progress,
  required double density,
  double windBearing = 180.0,
  double windIntensity = 0.0,
}) {
  _drawStormCore(canvas, size, density);

  // Calculate wind drift based on bearing and intensity
  final windRadians = (windBearing - 180.0) * math.pi / 180.0;
  final windDriftFactor = math.cos(windRadians) * windIntensity * 0.15;

  for (var index = 0; index < _clusters.length; index++) {
    final cluster = _clusters[index];
    final direction = index.isEven ? 1.0 : -1.0;
    final drift = (progress - 0.5) * size.width * 0.035 * direction + windDriftFactor * size.width * 0.08;
    final bounds = Rect.fromCenter(
      center: Offset(size.width * cluster.x + drift, size.height * cluster.y),
      width: size.shortestSide * cluster.width,
      height: size.shortestSide * cluster.height,
    );
    final contour = _cloudContour(bounds, index);
    final alpha = (0.06 + (index % 3) * 0.018) * density;

    canvas.drawPath(
      contour.shift(Offset(0, bounds.height * 0.2)),
      Paint()
        ..color = WeatherPalette.canvasDeep.withValues(
          alpha: (alpha * 3).clamp(0, 0.72),
        ),
    );
    canvas.drawPath(
      contour,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            WeatherPalette.mistBlue.withValues(alpha: alpha * 0.9),
            WeatherPalette.lensLift.withValues(alpha: alpha * 1.35),
            WeatherPalette.canvasDeep.withValues(
              alpha: (alpha * 3.4).clamp(0, 0.82),
            ),
          ],
        ).createShader(bounds),
    );
    canvas.drawPath(
      _cloudContour(
        Rect.fromCenter(
          center: bounds.center.translate(
            -bounds.width * 0.04,
            -bounds.height * 0.12,
          ),
          width: bounds.width * 0.78,
          height: bounds.height * 0.68,
        ),
        index + 2,
      ),
      Paint()..color = WeatherPalette.lensRim.withValues(alpha: alpha * 0.68),
    );
    canvas.drawPath(
      contour,
      Paint()
        ..color = WeatherPalette.mistBlue.withValues(alpha: alpha * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  _drawBillows(canvas, size, density, progress, windBearing, windIntensity);
  _drawLowerStrata(canvas, size, density);
}

void _drawBillows(Canvas canvas, Size size, double density, double progress, double windBearing, double windIntensity) {
  final windRadians = (windBearing - 180.0) * math.pi / 180.0;
  final windDriftFactor = math.cos(windRadians) * windIntensity * 0.1;

  for (var index = 0; index < _cachedUnitBillowPaths.length; index++) {
    final yUnit = _unit(index * 17 + 5);
    final xUnit = _unit(index * 29 + 11);
    final radiusUnit = _unit(index * 43 + 19);
    final driftDirection = index.isEven ? 1.0 : -1.0;
    final center = Offset(
      size.width * (0.52 + xUnit * 0.54) +
          (progress - 0.5) * size.width * 0.025 * driftDirection + windDriftFactor * size.width * 0.06,
      size.height * (0.08 + yUnit * 0.86),
    );
    final radius = size.shortestSide * (0.045 + radiusUnit * 0.085);
    final alpha = (0.13 + radiusUnit * 0.09) * density;
    final rotation = (_unit(index * 59 + 23) - 0.5) * 0.9;
    final stretchX = (0.76 + _unit(index * 67 + 31) * 0.72) * radius;
    final stretchY = (0.82 + _unit(index * 73 + 37) * 0.34) * radius;

    final unitPath = _cachedUnitBillowPaths[index];

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(stretchX, stretchY);

    canvas.drawPath(
      unitPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.46, -0.58),
          radius: 1.15,
          colors: <Color>[
            WeatherPalette.mistBlue.withValues(alpha: alpha * 1.35),
            WeatherPalette.lensLift.withValues(alpha: alpha * 1.1),
            WeatherPalette.canvasDeep.withValues(
              alpha: (alpha * 2.6).clamp(0, 0.78),
            ),
          ],
          stops: const <double>[0, 0.38, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1.35)),
    );
    canvas.restore();
  }
}

void _drawStormCore(Canvas canvas, Size size, double density) {
  final center = Offset(size.width * 0.76, size.height * 0.42);
  final radius = size.longestSide * 0.44;
  final bounds = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          WeatherPalette.textPrimary.withValues(alpha: 0.17 * density),
          WeatherPalette.mistBlue.withValues(alpha: 0.2 * density),
          WeatherPalette.stormViolet.withValues(alpha: 0.08 * density),
          WeatherPalette.clear,
        ],
        stops: const <double>[0, 0.14, 0.42, 1],
      ).createShader(bounds),
  );
}

void _drawLowerStrata(Canvas canvas, Size size, double density) {
  final hazeBounds = Rect.fromLTWH(
    0,
    size.height * 0.54,
    size.width,
    size.height * 0.46,
  );
  canvas.drawRect(
    hazeBounds,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          WeatherPalette.clear,
          WeatherPalette.lensLift.withValues(alpha: 0.15 * density),
          WeatherPalette.canvasNavy.withValues(alpha: 0.12 * density),
        ],
      ).createShader(hazeBounds),
  );
}

double _unit(int seed) {
  final value = math.sin(seed * 12.9898) * 43758.5453;
  return value - value.floorToDouble();
}

Path _cloudContour(Rect bounds, int seed) {
  final left = bounds.left;
  final top = bounds.top;
  final width = bounds.width;
  final height = bounds.height;
  final crest = 0.05 + (seed % 4) * 0.025;

  return Path()
    ..moveTo(left, top + height * 0.78)
    ..cubicTo(
      left + width * 0.04,
      top + height * 0.32,
      left + width * 0.15,
      top + height * 0.5,
      left + width * 0.23,
      top + height * 0.3,
    )
    ..cubicTo(
      left + width * 0.32,
      top - height * crest,
      left + width * 0.43,
      top + height * 0.18,
      left + width * 0.5,
      top + height * 0.31,
    )
    ..cubicTo(
      left + width * 0.58,
      top + height * 0.03,
      left + width * 0.7,
      top + height * 0.1,
      left + width * 0.75,
      top + height * 0.43,
    )
    ..cubicTo(
      left + width * 0.87,
      top + height * 0.24,
      left + width * 0.97,
      top + height * 0.53,
      left + width,
      top + height * 0.74,
    )
    ..cubicTo(
      left + width * 0.96,
      top + height * 0.98,
      left + width * 0.83,
      top + height * 0.72,
      left + width * 0.73,
      top + height * 0.88,
    )
    ..cubicTo(
      left + width * 0.62,
      top + height * 1.05,
      left + width * 0.51,
      top + height * 0.78,
      left + width * 0.41,
      top + height * 0.91,
    )
    ..cubicTo(
      left + width * 0.28,
      top + height * 1.03,
      left + width * 0.14,
      top + height * 0.84,
      left,
      top + height * 0.78,
    )
    ..close();
}
