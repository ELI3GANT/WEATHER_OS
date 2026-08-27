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
    duration: WeatherMotion.weatherCycle,
  );

  WeatherCondition? _prevCondition;
  DayPeriod? _prevPeriod;
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
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
            final fadeValue = _fadeController.value;
            final isFading = fadeValue < 1.0 && _prevCondition != null && _prevPeriod != null;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (isFading)
                  Opacity(
                    opacity: 1.0 - fadeValue,
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
                  opacity: isFading ? fadeValue : 1.0,
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
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1);
        _drawRain(canvas, size, intensity: 0.78);
      case WeatherCondition.sunny:
        if (period != DayPeriod.night) {
          _drawSun(canvas, size);
        }
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.28);
      case WeatherCondition.storm:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1.24);
        _drawRain(canvas, size, intensity: 1.1);
        _drawLightning(canvas, size);
      case WeatherCondition.cloudy:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.86);
      case WeatherCondition.snow:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 0.75);
        _drawSnow(canvas, size);
      case WeatherCondition.fog:
        drawAtmosphericClouds(canvas, size, progress: progress, density: 1.1);
        _drawFog(canvas, size);
    }
  }

  Shader _background(Rect bounds) {
    if (period == DayPeriod.night) {
      final nightColors = switch (condition) {
        WeatherCondition.storm => <Color>[
            const Color(0xFF010408),
            WeatherPalette.stormViolet.withValues(alpha: 0.4),
            const Color(0xFF080D1A),
            WeatherPalette.canvasDeep,
          ],
        WeatherCondition.rain => <Color>[
            const Color(0xFF01050A),
            const Color(0xFF071322),
            const Color(0xFF0A1C30),
            WeatherPalette.canvasDeep,
          ],
        WeatherCondition.snow => <Color>[
            const Color(0xFF020712),
            const Color(0xFF0B1728),
            const Color(0xFF14243B),
            WeatherPalette.canvasDeep,
          ],
        _ => <Color>[
            const Color(0xFF02050A),
            const Color(0xFF06101D),
            const Color(0xFF09172A),
            WeatherPalette.canvasDeep,
          ],
      };
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const <double>[0, 0.4, 0.75, 1],
        colors: nightColors,
      ).createShader(bounds);
    }

    final colors = switch (condition) {
      WeatherCondition.rain => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.canvasNavy,
          WeatherPalette.lensLift,
          WeatherPalette.canvasNavy,
        ],
      WeatherCondition.sunny => <Color>[
          WeatherPalette.canvasNavy,
          WeatherPalette.mistBlue.withValues(alpha: 0.72),
          WeatherPalette.horizonAmber,
          WeatherPalette.canvasDeep,
        ],
      WeatherCondition.storm => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.stormViolet.withValues(alpha: 0.55),
          WeatherPalette.lensLift,
          WeatherPalette.canvasNavy,
        ],
      WeatherCondition.cloudy => <Color>[
          WeatherPalette.canvasDeep,
          WeatherPalette.lensCore,
          WeatherPalette.lensLift.withValues(alpha: 0.82),
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
      stops: const <double>[0, 0.38, 0.7, 1],
      colors: colors,
    ).createShader(bounds);
  }

  void _drawStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    const starCount = 48;
    for (var i = 0; i < starCount; i++) {
      final seedX = ((i * 37.17) % 1.0);
      final seedY = ((i * 59.41) % 0.65);
      final x = size.width * seedX;
      final y = size.height * seedY;
      final twinkle = 0.3 + 0.7 * math.sin((progress * 4 * math.pi) + (i * 1.5)).abs();
      final radius = (i % 3 == 0) ? 1.4 : 0.9;

      starPaint.color = Colors.white.withValues(alpha: twinkle * 0.75);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.78, size.height * 0.2);
    final radius = size.shortestSide * 0.12;

    final glow = RadialGradient(
      colors: <Color>[
        WeatherPalette.mistBlue.withValues(alpha: 0.22),
        WeatherPalette.mistBlue.withValues(alpha: 0.04),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius * 2.2);
    canvas.drawCircle(center, radius * 2.2, Paint()..shader = glow.createShader(bounds));

    final moonPaint = Paint()..color = const Color(0xFFE2EAF8).withValues(alpha: 0.9);
    canvas.drawCircle(center, radius * 0.5, moonPaint);
  }

  void _drawGoldenHorizon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.65, size.height * 0.72);
    final radius = size.longestSide * 0.55;
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.55),
        const Color(0xFFD95B43).withValues(alpha: 0.22),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));
  }

  void _drawHorizon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.72, size.height * 0.76);
    final radius = size.longestSide * 0.52;
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.3),
        WeatherPalette.horizonAmber.withValues(alpha: 0.06),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));
  }

  void _drawRain(Canvas canvas, Size size, {required double intensity}) {
    final rainPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.16 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1;
    for (var index = 0; index < 72; index++) {
      final seed = (index * 0.61803398875) % 1;
      final drift = progress * (0.12 + index % 5 * 0.01);
      final x = size.width * ((seed + drift) % 1);
      final y = size.height * ((index * 0.127 + progress * 1.9) % 1);
      final length = size.height * (0.018 + (index % 4) * 0.004);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.18, y + length),
        rainPaint,
      );
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final snowPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 50; index++) {
      final seed = (index * 0.723) % 1;
      final drift = math.sin(progress * 2 * math.pi + index) * 12;
      final x = (size.width * ((seed + progress * 0.05) % 1)) + drift;
      final y = size.height * ((index * 0.15 + progress * 0.7) % 1);
      final radius = 1.0 + (index % 3) * 0.75;
      final alpha = 0.3 + (index % 4) * 0.15;

      snowPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, snowPaint);
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    for (var i = 0; i < 3; i++) {
      final drift = math.sin((progress + i * 0.33) * 2 * math.pi) * (size.width * 0.08);
      final y = size.height * (0.45 + i * 0.16);
      fogPaint.color = WeatherPalette.lensLift.withValues(alpha: 0.25);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5 + drift, y),
          width: size.width * 1.2,
          height: size.height * 0.15,
        ),
        fogPaint,
      );
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final pulse = 0.92 + math.sin(progress * math.pi * 2) * 0.08;
    final center = Offset(size.width * 0.72, size.height * 0.24);
    final radius = size.shortestSide * 0.48 * pulse;
    final gradient = RadialGradient(
      colors: <Color>[
        WeatherPalette.horizonAmber.withValues(alpha: 0.62),
        WeatherPalette.mistBlue.withValues(alpha: 0.16),
        WeatherPalette.clear,
      ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center, radius, Paint()..shader = gradient.createShader(bounds));
  }

  void _drawLightning(Canvas canvas, Size size) {
    final flash = math.max(0.0, math.sin((progress * 11 - 8.2) * math.pi));
    if (flash == 0) {
      return;
    }
    final paint = Paint()
      ..color = WeatherPalette.textPrimary.withValues(alpha: flash * 0.72)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final bolt = Path()
      ..moveTo(size.width * 0.68, size.height * 0.18)
      ..lineTo(size.width * 0.61, size.height * 0.36)
      ..lineTo(size.width * 0.69, size.height * 0.34)
      ..lineTo(size.width * 0.58, size.height * 0.57);
    canvas.drawPath(bolt, paint);
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) {
    return condition != oldDelegate.condition ||
        period != oldDelegate.period ||
        progress != oldDelegate.progress;
  }
}
