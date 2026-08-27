import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/weather_condition.dart';
import 'atmospheric_clouds.dart';

enum DayPeriod {
  night,
  dawn,
  day,
  sunset,
}

class WeatherAtmosphere extends StatefulWidget {
  const WeatherAtmosphere({
    required this.condition,
    this.customHour,
    super.key,
  });

  final WeatherCondition condition;
  final int? customHour;

  @override
  State<WeatherAtmosphere> createState() => _WeatherAtmosphereState();
}

class _WeatherAtmosphereState extends State<WeatherAtmosphere>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  WeatherCondition? _prevCondition;
  DayPeriod? _prevPeriod;
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  DayPeriod _resolvePeriodFor(int? customH) {
    final hour = customH ?? DateTime.now().hour;
    if (hour >= 5 && hour < 7) {
      return DayPeriod.dawn;
    } else if (hour >= 7 && hour < 18) {
      return DayPeriod.day;
    } else if (hour >= 18 && hour < 21) {
      return DayPeriod.sunset;
    } else {
      return DayPeriod.night;
    }
  }

  DayPeriod _resolvePeriod() => _resolvePeriodFor(widget.customHour);

  @override
  void didUpdateWidget(WeatherAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPeriod = _resolvePeriodFor(oldWidget.customHour);
    final newPeriod = _resolvePeriod();
    if (oldWidget.condition != widget.condition || oldPeriod != newPeriod) {
      _prevCondition = oldWidget.condition;
      _prevPeriod = oldPeriod;
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion && !_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.32;
    } else if (!_controller.isAnimating) {
      final isResumed = WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (isResumed) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = _resolvePeriod();

    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey<String>('weather-atmosphere-boundary'),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_controller, _fadeController]),
          builder: (BuildContext context, Widget? child) {
            final rawFade = _fadeController.value;
            final fadeValue = Curves.easeInOutCubic.transform(rawFade);
            final isFading = rawFade < 1.0 && _prevCondition != null && _prevPeriod != null;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (isFading)
                  Opacity(
                    opacity: (1.0 - fadeValue).clamp(0.0, 1.0),
                    child: CustomPaint(
                      painter: _AtmospherePainter(
                        condition: _prevCondition!,
                        period: _prevPeriod!,
                        progress: _controller.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                Opacity(
                  opacity: (isFading ? fadeValue : 1.0).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _AtmospherePainter(
                      condition: widget.condition,
                      period: period,
                      progress: _controller.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({
    required this.condition,
    required this.period,
    required this.progress,
  });

  final WeatherCondition condition;
  final DayPeriod period;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..shader = _background(bounds));

    if (period == DayPeriod.night) {
      _drawStars(canvas, size);
      _drawMoon(canvas, size);
    } else if (period == DayPeriod.sunset || period == DayPeriod.dawn) {
      _drawGoldenHorizon(canvas, size);
    } else {
      _drawHorizon(canvas, size);
    }

    switch (condition) {
      case WeatherCondition.rain:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1.05);
        _drawMultiLayerRain(canvas, size, intensity: 0.85);
      case WeatherCondition.sunny:
        if (period != DayPeriod.night) {
          _drawSunWithRays(canvas, size);
        }
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.25);
      case WeatherCondition.storm:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1.35);
        _drawMultiLayerRain(canvas, size, intensity: 1.25);
        _drawThunderFlash(canvas, size);
        _drawLightning(canvas, size);
      case WeatherCondition.cloudy:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.95);
      case WeatherCondition.snow:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.8);
        _drawSnowTurbulence(canvas, size);
      case WeatherCondition.fog:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1.2);
        _drawFogLayers(canvas, size);
    }
  }

  Shader _background(Rect bounds) {
    if (period == DayPeriod.night) {
      final nightColors = switch (condition) {
        WeatherCondition.storm => <Color>[
            const Color(0xFF02040A),
            WeatherPalette.stormViolet.withValues(alpha: 0.45),
            const Color(0xFF060B18),
            WeatherPalette.canvasDeep,
          ],
        WeatherCondition.rain => <Color>[
            const Color(0xFF01060D),
            const Color(0xFF081526),
            const Color(0xFF0C2038),
            WeatherPalette.canvasDeep,
          ],
        WeatherCondition.snow => <Color>[
            const Color(0xFF020814),
            const Color(0xFF0D1B30),
            const Color(0xFF162A45),
            WeatherPalette.canvasDeep,
          ],
        _ => <Color>[
            const Color(0xFF02060C),
            const Color(0xFF061322),
            const Color(0xFF091C33),
            WeatherPalette.canvasDeep,
          ],
      };
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const <double>[0, 0.35, 0.72, 1],
        colors: nightColors,
      ).createShader(bounds);
    }

    final colors = switch (condition) {
      WeatherCondition.rain => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.canvasNavy,
          WeatherPalette.lensLift.withValues(alpha: 0.9),
          WeatherPalette.canvasNavy,
        ],
      WeatherCondition.sunny => <Color>[
          WeatherPalette.canvasNavy,
          WeatherPalette.mistBlue.withValues(alpha: 0.75),
          WeatherPalette.horizonAmber,
          WeatherPalette.canvasDeep,
        ],
      WeatherCondition.storm => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.stormViolet.withValues(alpha: 0.6),
          WeatherPalette.lensLift,
          WeatherPalette.canvasNavy,
        ],
      WeatherCondition.cloudy => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.lensCore,
          WeatherPalette.lensLift.withValues(alpha: 0.85),
          WeatherPalette.canvasDeep,
        ],
      WeatherCondition.snow => <Color>[
          WeatherPalette.canvasNavy,
          const Color(0xFF1E3A56),
          WeatherPalette.lensLift,
          WeatherPalette.canvasDeep,
        ],
      WeatherCondition.fog => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.lensCore,
          WeatherPalette.canvasNavy,
          WeatherPalette.canvasDeep,
        ],
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const <double>[0, 0.35, 0.7, 1],
      colors: colors,
    ).createShader(bounds);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    const starCount = 56;
    for (var i = 0; i < starCount; i++) {
      final seedX = ((i * 37.17) % 1.0);
      final seedY = ((i * 59.41) % 0.65);
      final x = size.width * seedX;
      final y = size.height * seedY;
      final twinkle = 0.35 + 0.65 * math.sin((progress * 6 * math.pi) + (i * 1.8)).abs();
      final radius = (i % 4 == 0) ? 1.5 : 0.9;

      starPaint.color = Colors.white.withValues(alpha: twinkle * 0.8);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.8, size.height * 0.18);
    final radius = size.shortestSide * 0.11;

    final glow = RadialGradient(
      colors: <Color>[
        WeatherPalette.mistBlue.withValues(alpha: 0.25),
        WeatherPalette.mistBlue.withValues(alpha: 0.05),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius * 2.4);
    canvas.drawCircle(center, radius * 2.4, Paint()..shader = glow.createShader(bounds));

    final moonPaint = Paint()..color = const Color(0xFFE6EEF8).withValues(alpha: 0.92);
    canvas.drawCircle(center, radius * 0.48, moonPaint);
  }

  void _drawGoldenHorizon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.65, size.height * 0.72);
    final radius = size.longestSide * 0.58;
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.6),
        const Color(0xFFD95B43).withValues(alpha: 0.25),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));
  }

  void _drawHorizon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.72, size.height * 0.76);
    final radius = size.longestSide * 0.54;
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.32),
        WeatherPalette.horizonAmber.withValues(alpha: 0.07),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));
  }

  void _drawSunWithRays(Canvas canvas, Size size) {
    final pulse = 0.94 + math.sin(progress * math.pi * 2) * 0.06;
    final center = Offset(size.width * 0.74, size.height * 0.22);
    final radius = size.shortestSide * 0.46 * pulse;

    // Ambient Sun Halo
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.68),
        WeatherPalette.mistBlue.withValues(alpha: 0.2),
        WeatherPalette.clear,
      ],
      stops: const <double>[0.0, 0.45, 1.0],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));

    // Sun Core
    canvas.drawCircle(
      center,
      radius * 0.16,
      Paint()..color = const Color(0xFFFFF7ED).withValues(alpha: 0.95),
    );
  }

  void _drawMultiLayerRain(Canvas canvas, Size size, {required double intensity}) {
    // Layer 1: Distant Light Rain (Slower)
    final bgRainPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.12 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;

    for (var index = 0; index < 45; index++) {
      final seed = (index * 0.61803398875) % 1;
      final x = size.width * ((seed + progress * 0.08) % 1);
      final y = size.height * ((index * 0.11 + progress * 1.4) % 1);
      final length = size.height * (0.014 + (index % 3) * 0.003);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.15, y + length),
        bgRainPaint,
      );
    }

    // Layer 2: Foreground Rain (Faster, Brighter)
    final fgRainPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.22 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    for (var index = 0; index < 45; index++) {
      final seed = (index * 0.81912) % 1;
      final x = size.width * ((seed + progress * 0.14) % 1);
      final y = size.height * ((index * 0.17 + progress * 2.2) % 1);
      final length = size.height * (0.022 + (index % 4) * 0.004);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.18, y + length),
        fgRainPaint,
      );
    }
  }

  void _drawSnowTurbulence(Canvas canvas, Size size) {
    final snowPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 60; index++) {
      final seed = (index * 0.723) % 1;
      final drift = math.sin(progress * 2.5 * math.pi + index) * 16;
      final x = (size.width * ((seed + progress * 0.06) % 1)) + drift;
      final y = size.height * ((index * 0.14 + progress * 0.75) % 1);
      final radius = 1.1 + (index % 4) * 0.7;
      final alpha = 0.35 + (index % 3) * 0.18;

      snowPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, snowPaint);
    }
  }

  void _drawFogLayers(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    for (var i = 0; i < 4; i++) {
      final drift = math.sin((progress + i * 0.25) * 2 * math.pi) * (size.width * 0.09);
      final y = size.height * (0.42 + i * 0.14);
      fogPaint.color = WeatherPalette.lensLift.withValues(alpha: 0.28);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5 + drift, y),
          width: size.width * 1.3,
          height: size.height * 0.16,
        ),
        fogPaint,
      );
    }
  }

  void _drawThunderFlash(Canvas canvas, Size size) {
    final flash = math.max(0.0, math.sin((progress * 9.5 - 7.0) * math.pi));
    if (flash > 0.3) {
      final ambientPaint = Paint()
        ..color = WeatherPalette.stormViolet.withValues(alpha: flash * 0.25);
      canvas.drawRect(Offset.zero & size, ambientPaint);
    }
  }

  void _drawLightning(Canvas canvas, Size size) {
    final flash = math.max(0.0, math.sin((progress * 11 - 8.2) * math.pi));
    if (flash == 0) {
      return;
    }
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: flash * 0.9)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bolt = Path()
      ..moveTo(size.width * 0.68, size.height * 0.16)
      ..lineTo(size.width * 0.62, size.height * 0.34)
      ..lineTo(size.width * 0.69, size.height * 0.32)
      ..lineTo(size.width * 0.57, size.height * 0.55)
      ..lineTo(size.width * 0.63, size.height * 0.53)
      ..lineTo(size.width * 0.55, size.height * 0.72);
    canvas.drawPath(bolt, paint);
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) {
    return condition != oldDelegate.condition ||
        period != oldDelegate.period ||
        progress != oldDelegate.progress;
  }
}
