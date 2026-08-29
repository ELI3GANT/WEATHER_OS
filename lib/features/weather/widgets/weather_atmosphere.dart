import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../models/hourly_forecast.dart';
import '../models/weather_atmosphere_state.dart';
import '../models/weather_condition.dart';
import '../models/weather_model.dart';
import 'atmospheric_clouds.dart';

enum DayPeriod { night, dawn, day, sunset }

class WeatherAtmosphere extends StatefulWidget {
  const WeatherAtmosphere({
    required this.condition,
    this.customHour,
    this.animationProgress,
    this.atmosphereState,
    super.key,
  }) : assert(
         animationProgress == null ||
             (animationProgress >= 0.0 && animationProgress <= 1.0),
       );

  final WeatherCondition condition;
  final int? customHour;
  final double? animationProgress;
  final WeatherAtmosphereState? atmosphereState;

  @override
  State<WeatherAtmosphere> createState() => _WeatherAtmosphereState();
}

class _WeatherAtmosphereState extends State<WeatherAtmosphere>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

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
    if (oldWidget.animationProgress != widget.animationProgress) {
      _syncMotion();
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
      if (widget.animationProgress == null &&
          !reduceMotion &&
          !_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.animationProgress != null) {
      _controller.stop();
    } else if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.32;
    } else if (!_controller.isAnimating) {
      final isResumed =
          WidgetsBinding.instance.lifecycleState == null ||
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
    final progress = widget.animationProgress ?? _controller.value;

    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey<String>('weather-atmosphere-boundary'),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _controller,
            _fadeController,
          ]),
          builder: (BuildContext context, Widget? child) {
            final rawFade = _fadeController.value;
            final fadeValue = Curves.easeInOutCubic.transform(rawFade);
            final isFading =
                rawFade < 1.0 && _prevCondition != null && _prevPeriod != null;

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
                        progress: progress,
                        atmosphereState: widget.atmosphereState,
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
                      progress: progress,
                      atmosphereState: widget.atmosphereState,
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
    this.atmosphereState,
  });

  final WeatherCondition condition;
  final DayPeriod period;
  final double progress;
  final WeatherAtmosphereState? atmosphereState;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final effectiveState = atmosphereState ??
        WeatherAtmosphereState.fromWeather(
          WeatherModel(
            location: 'Current Location',
            temperature: 70,
            condition: condition,
            feelsLike: 70,
            high: 75,
            low: 60,
            humidity: 50,
            windSpeedMph: 10,
            uvIndex: 1,
            pressureInHg: 30,
            precipChance: 20,
            totalRainInches: 0,
            visibilityMiles: 10,
            windDirectionCompass: 'ESE',
            windBearingDegrees: 112,
            sunriseTime: '6:00 AM',
            sunsetTime: '8:00 PM',
            daylightDuration: '14h',
            dailySummary: 'Weather environment',
            riskLevel: 'LOW RISK',
            severeRisks: const <String, double>{},
            whatToExpect: const <String>['Good conditions'],
            impactScores: const <String, int>{'Weather': 0},
            hourly: const <HourlyForecast>[],
          ),
        );

    final motionBoost = effectiveState.windIntensity;
    final modulatedProgress = progress + motionBoost * 0.2;
    canvas.drawRect(bounds, Paint()..shader = _background(bounds, effectiveState));

    final isNight = period == DayPeriod.night ||
        effectiveState.daylightPhase == DaylightPhase.night;
    final isDawn = period == DayPeriod.dawn ||
        effectiveState.daylightPhase == DaylightPhase.dawn;
    final isSunset = period == DayPeriod.sunset ||
        effectiveState.daylightPhase == DaylightPhase.sunset;

    if (isNight) {
      _drawStars(canvas, size, modulatedProgress, effectiveState);
      _drawMoon(canvas, size, modulatedProgress);
    } else if (isDawn || isSunset) {
      _drawGoldenHorizon(canvas, size, modulatedProgress, isDawn: isDawn);
    } else {
      _drawHorizon(canvas, size, modulatedProgress);
    }

    switch (effectiveState.conditionFamily) {
      case WeatherConditionFamily.rain:
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 0.85 + (effectiveState.cloudIntensity * 0.55),
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
        _drawMultiLayerRain(
          canvas,
          size,
          intensity: effectiveState.precipitationIntensity > 0
              ? effectiveState.precipitationIntensity
              : (effectiveState.isHeavyPrecipitation ? 1.0 : 0.65),
          effectiveState: effectiveState,
          drawProgress: modulatedProgress,
        );
      case WeatherConditionFamily.clear:
        if (!isNight) {
          _drawSunWithRays(canvas, size, modulatedProgress);
        }
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 0.15 + effectiveState.cloudIntensity * 0.2,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
      case WeatherConditionFamily.storm:
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 1.1 + effectiveState.cloudIntensity * 0.5,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
        _drawMultiLayerRain(
          canvas,
          size,
          intensity: 1.1 + motionBoost * 0.5,
          effectiveState: effectiveState,
          drawProgress: modulatedProgress,
        );
        _drawThunderFlash(canvas, size, modulatedProgress);
        _drawLightning(canvas, size, modulatedProgress);
      case WeatherConditionFamily.cloudy:
        if (!isNight && !effectiveState.isOvercast) {
          _drawSunWithRays(canvas, size, modulatedProgress, isDiffused: true);
        }
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: effectiveState.isOvercast ? 1.0 : 0.65,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
      case WeatherConditionFamily.snow:
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 0.75 + effectiveState.cloudIntensity * 0.35,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
        _drawSnowTurbulence(
          canvas,
          size,
          modulatedProgress,
          effectiveState: effectiveState,
        );
      case WeatherConditionFamily.fog:
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 0.95 + effectiveState.cloudIntensity * 0.35,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
        _drawFogLayers(
          canvas,
          size,
          modulatedProgress,
          effectiveState: effectiveState,
        );
      case WeatherConditionFamily.wind:
        if (!isNight) {
          _drawSunWithRays(canvas, size, modulatedProgress);
        }
        drawAtmosphericClouds(
          canvas,
          size,
          progress: modulatedProgress,
          density: 0.45 + effectiveState.cloudIntensity * 0.3,
          windBearing: effectiveState.windDirection,
          windIntensity: effectiveState.windIntensity,
        );
        _drawWindStreaks(
          canvas,
          size,
          modulatedProgress,
          effectiveState: effectiveState,
        );
    }
  }

  Shader _background(Rect bounds, WeatherAtmosphereState state) {
    final isNight = period == DayPeriod.night ||
        state.daylightPhase == DaylightPhase.night;
    final isDawn = period == DayPeriod.dawn ||
        state.daylightPhase == DaylightPhase.dawn;
    final isSunset = period == DayPeriod.sunset ||
        state.daylightPhase == DaylightPhase.sunset;

    if (isNight) {
      final nightColors = switch (state.conditionFamily) {
        WeatherConditionFamily.storm => <Color>[
          const Color(0xFF02040A),
          WeatherPalette.stormViolet.withValues(alpha: 0.45),
          const Color(0xFF060B18),
          WeatherPalette.canvasDeep,
        ],
        WeatherConditionFamily.rain => <Color>[
          const Color(0xFF01060D),
          const Color(0xFF081526),
          const Color(0xFF0C2038),
          WeatherPalette.canvasDeep,
        ],
        WeatherConditionFamily.snow => <Color>[
          const Color(0xFF020814),
          const Color(0xFF0D1B30),
          const Color(0xFF162A45),
          WeatherPalette.canvasDeep,
        ],
        WeatherConditionFamily.fog => <Color>[
          const Color(0xFF03070E),
          const Color(0xFF091322),
          const Color(0xFF0E1B2D),
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

    if (isDawn) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const <double>[0, 0.4, 0.75, 1],
        colors: <Color>[
          const Color(0xFF12233B),
          const Color(0xFF2B4769),
          const Color(0xFFD47C59).withValues(alpha: 0.85),
          WeatherPalette.canvasDeep,
        ],
      ).createShader(bounds);
    }

    if (isSunset) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const <double>[0, 0.35, 0.7, 1],
        colors: <Color>[
          const Color(0xFF1A1A36),
          const Color(0xFF4A2B4D),
          WeatherPalette.horizonAmber.withValues(alpha: 0.9),
          WeatherPalette.canvasDeep,
        ],
      ).createShader(bounds);
    }

    // Daytime gradients
    final colors = switch (state.conditionFamily) {
      WeatherConditionFamily.rain => state.isHeavyPrecipitation
          ? <Color>[
              const Color(0xFF0C1622),
              const Color(0xFF162638),
              WeatherPalette.lensLift.withValues(alpha: 0.8),
              WeatherPalette.canvasNavy,
            ]
          : <Color>[
              WeatherPalette.canvasDeep,
              WeatherPalette.canvasNavy,
              WeatherPalette.lensLift.withValues(alpha: 0.9),
              WeatherPalette.canvasNavy,
            ],
      WeatherConditionFamily.clear => <Color>[
        WeatherPalette.canvasNavy,
        WeatherPalette.mistBlue.withValues(alpha: 0.75),
        WeatherPalette.horizonAmber.withValues(alpha: 0.65),
        WeatherPalette.canvasDeep,
      ],
      WeatherConditionFamily.storm => <Color>[
        WeatherPalette.canvasDeep,
        WeatherPalette.stormViolet.withValues(alpha: 0.65),
        WeatherPalette.lensLift,
        WeatherPalette.canvasNavy,
      ],
      WeatherConditionFamily.cloudy => state.isOvercast
          ? <Color>[
              const Color(0xFF141D29),
              const Color(0xFF223042),
              WeatherPalette.lensCore.withValues(alpha: 0.9),
              WeatherPalette.canvasDeep,
            ]
          : <Color>[
              WeatherPalette.canvasDeep,
              WeatherPalette.lensCore,
              WeatherPalette.lensLift.withValues(alpha: 0.85),
              WeatherPalette.canvasDeep,
            ],
      WeatherConditionFamily.snow => <Color>[
        WeatherPalette.canvasNavy,
        const Color(0xFF1E3A56),
        WeatherPalette.lensLift,
        WeatherPalette.canvasDeep,
      ],
      WeatherConditionFamily.fog => <Color>[
        WeatherPalette.canvasDeep,
        WeatherPalette.lensCore,
        WeatherPalette.canvasNavy,
        WeatherPalette.canvasDeep,
      ],
      WeatherConditionFamily.wind => <Color>[
        const Color(0xFF102844),
        const Color(0xFF1C4472),
        WeatherPalette.mistBlue.withValues(alpha: 0.85),
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

  void _drawStars(
    Canvas canvas,
    Size size,
    double drawProgress,
    WeatherAtmosphereState state,
  ) {
    if (state.isOvercast || state.conditionFamily == WeatherConditionFamily.fog) {
      return;
    }
    final starPaint = Paint()..style = PaintingStyle.fill;
    final baseCount = state.conditionFamily == WeatherConditionFamily.clear ? 56 : 28;
    for (var i = 0; i < baseCount; i++) {
      final seedX = ((i * 37.17) % 1.0);
      final seedY = ((i * 59.41) % 0.65);
      final x = size.width * seedX;
      final y = size.height * seedY;
      final twinkle =
          0.35 + 0.65 * math.sin((drawProgress * 6 * math.pi) + (i * 1.8)).abs();
      final radius = (i % 4 == 0) ? 1.5 : 0.9;

      starPaint.color = Colors.white.withValues(alpha: twinkle * 0.8);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawMoon(Canvas canvas, Size size, double drawProgress) {
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
    canvas.drawCircle(
      center,
      radius * 2.4,
      Paint()..shader = glow.createShader(bounds),
    );

    final moonPaint = Paint()
      ..color = const Color(0xFFE6EEF8).withValues(alpha: 0.92);
    canvas.drawCircle(center, radius * 0.48, moonPaint);
  }

  void _drawGoldenHorizon(
    Canvas canvas,
    Size size,
    double drawProgress, {
    bool isDawn = false,
  }) {
    final center = Offset(size.width * 0.65, size.height * 0.72);
    final radius = size.longestSide * 0.58;
    final gradient = RadialGradient(
      colors: isDawn
          ? <Color>[
              const Color(0xFFFFB38A).withValues(alpha: 0.65),
              const Color(0xFFE87556).withValues(alpha: 0.3),
              WeatherPalette.clear,
            ]
          : <Color>[
              WeatherPalette.horizonAmber.withValues(alpha: 0.6),
              const Color(0xFFD95B43).withValues(alpha: 0.25),
              WeatherPalette.clear,
            ],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(bounds),
    );
  }

  void _drawHorizon(Canvas canvas, Size size, double drawProgress) {
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
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(bounds),
    );
  }

  void _drawSunWithRays(
    Canvas canvas,
    Size size,
    double drawProgress, {
    bool isDiffused = false,
  }) {
    final pulse = 0.94 + math.sin(drawProgress * math.pi * 2) * 0.06;
    final center = Offset(size.width * 0.74, size.height * 0.22);
    final radius = size.shortestSide * 0.46 * pulse;

    // Ambient Sun Halo
    final gradient = RadialGradient(
      colors: isDiffused
          ? <Color>[
              WeatherPalette.horizonAmber.withValues(alpha: 0.35),
              WeatherPalette.mistBlue.withValues(alpha: 0.1),
              WeatherPalette.clear,
            ]
          : <Color>[
              WeatherPalette.horizonAmber.withValues(alpha: 0.68),
              WeatherPalette.mistBlue.withValues(alpha: 0.2),
              WeatherPalette.clear,
            ],
      stops: const <double>[0.0, 0.45, 1.0],
    );
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(bounds),
    );

    // Sun Core
    if (!isDiffused) {
      canvas.drawCircle(
        center,
        radius * 0.16,
        Paint()..color = const Color(0xFFFFF7ED).withValues(alpha: 0.95),
      );
    }
  }

  void _drawMultiLayerRain(
    Canvas canvas,
    Size size, {
    required double intensity,
    required WeatherAtmosphereState effectiveState,
    required double drawProgress,
  }) {
    // Wind-driven rain angle (intensity and direction affect the slant)
    final windFactor = effectiveState.windDirection;
    final angleRadians = (windFactor - 180.0) * math.pi / 180.0;
    final driftX = math.cos(angleRadians) * effectiveState.windIntensity;

    // Layer 1: Distant Light Rain (Slower)
    final bgRainPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.12 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;

    final bgRainCount = (45 * intensity).round().clamp(5, 65);
    for (var index = 0; index < bgRainCount; index++) {
      final seed = (index * 0.61803398875) % 1;
      final x = size.width * ((seed + drawProgress * 0.08 + driftX * 0.05) % 1);
      final y = size.height * ((index * 0.11 + drawProgress * 1.4) % 1);
      final length = size.height * (0.014 + (index % 3) * 0.003);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.15 + driftX * 2, y + length),
        bgRainPaint,
      );
    }

    // Layer 2: Foreground Rain (Faster, Brighter) — increases with intensity
    final fgRainPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.22 * intensity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    final fgRainCount = (45 * intensity.clamp(0.4, 1.0)).round().clamp(10, 90);
    for (var index = 0; index < fgRainCount; index++) {
      final seed = (index * 0.81912) % 1;
      final x = size.width * ((seed + drawProgress * 0.14 + driftX * 0.08) % 1);
      final y = size.height * ((index * 0.17 + drawProgress * 2.2) % 1);
      final length = size.height * (0.022 + (index % 4) * 0.004);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length * 0.18 + driftX * 3, y + length),
        fgRainPaint,
      );
    }
  }

  void _drawSnowTurbulence(
    Canvas canvas,
    Size size,
    double drawProgress, {
    required WeatherAtmosphereState effectiveState,
  }) {
    final snowPaint = Paint()..style = PaintingStyle.fill;
    final windFactor = effectiveState.windDirection;
    final windDrift = math.cos((windFactor - 180.0) * math.pi / 180.0) *
        effectiveState.windIntensity *
        24;

    final snowCount =
        (60 * (effectiveState.precipitationIntensity > 0 ? effectiveState.precipitationIntensity : 0.5))
            .round()
            .clamp(20, 90);
    for (var index = 0; index < snowCount; index++) {
      final seed = (index * 0.723) % 1;
      final drift =
          math.sin(drawProgress * 2.5 * math.pi + index) * 16 + windDrift;
      final x = (size.width * ((seed + drawProgress * 0.06) % 1)) + drift;
      final y = size.height * ((index * 0.14 + drawProgress * 0.75) % 1);
      final radius = 1.1 + (index % 4) * 0.7;
      final alpha = 0.35 + (index % 3) * 0.18;

      snowPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, snowPaint);
    }
  }

  void _drawFogLayers(
    Canvas canvas,
    Size size,
    double drawProgress, {
    required WeatherAtmosphereState effectiveState,
  }) {
    // Fog intensity inversely tracks visibility: low visibility = high fog
    final fogIntensity = 1.0 - effectiveState.visibilityFactor;
    final baseAlpha = 0.28 * fogIntensity.clamp(0.3, 1.0);

    final fogPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);

    // More layers for thicker fog
    final layerCount = (4 + (fogIntensity * 3)).round().clamp(4, 8);
    for (var i = 0; i < layerCount; i++) {
      final drift = math.sin((drawProgress + i * 0.25) * 2 * math.pi) *
          (size.width * (0.05 + fogIntensity * 0.08));
      final y = size.height * (0.42 + i * 0.14);
      fogPaint.color = WeatherPalette.lensLift.withValues(alpha: baseAlpha);
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

  void _drawWindStreaks(
    Canvas canvas,
    Size size,
    double drawProgress, {
    required WeatherAtmosphereState effectiveState,
  }) {
    final windSpeedFactor = effectiveState.windIntensity;
    final windBearing = effectiveState.windDirection;
    final angleRadians = (windBearing - 180.0) * math.pi / 180.0;
    final dirX = math.cos(angleRadians);

    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    const streakCount = 14;
    for (var i = 0; i < streakCount; i++) {
      final seed = (i * 0.718) % 1.0;
      final y = size.height * (0.15 + (i * 0.05) % 0.7);
      final speed = 0.4 + (i % 3) * 0.25;
      final xOffset = (drawProgress * speed * (dirX >= 0 ? 1.0 : -1.0) + seed) % 1.0;
      final startX = size.width * xOffset;
      final length = size.width * (0.12 + (i % 4) * 0.04) * (0.8 + windSpeedFactor * 0.5);
      final alpha = (0.12 + (i % 3) * 0.06) * windSpeedFactor;

      streakPaint.color = WeatherPalette.mistBlue.withValues(alpha: alpha.clamp(0.0, 0.45));
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + (dirX >= 0 ? length : -length), y + (i.isEven ? 4 : -4)),
        streakPaint,
      );
    }
  }

  void _drawThunderFlash(Canvas canvas, Size size, double drawProgress) {
    final flash = math.max(0.0, math.sin((drawProgress * 9.5 - 7.0) * math.pi));
    if (flash > 0.3) {
      final ambientPaint = Paint()
        ..color = WeatherPalette.stormViolet.withValues(alpha: flash * 0.25);
      canvas.drawRect(Offset.zero & size, ambientPaint);
    }
  }

  void _drawLightning(Canvas canvas, Size size, double drawProgress) {
    final flash = math.max(0.0, math.sin((drawProgress * 11 - 8.2) * math.pi));
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
        progress != oldDelegate.progress ||
        atmosphereState != oldDelegate.atmosphereState;
  }
}
