import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import 'glass_lens.dart';

class RadarView extends StatefulWidget {
  const RadarView({super.key});

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sweepController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  int _selectedRangeIndex = 1; // 0: 50mi, 1: 100mi, 2: 250mi
  bool _isPlaying = true;

  static const List<String> _ranges = <String>['50 mi', '100 mi', '250 mi'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _sweepController.stop();
    } else if (state == AppLifecycleState.resumed && _isPlaying) {
      if (!_sweepController.isAnimating) {
        _sweepController.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweepController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _sweepController.repeat();
      } else {
        _sweepController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('DOPPLER RADAR TELEMETRY', style: WeatherType.overline),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: const Color(0xFF69F0AE).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE HD',
                      style: WeatherType.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF69F0AE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // Radar Canvas
          GlassLens(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.1,
                  child: AnimatedBuilder(
                    animation: _sweepController,
                    builder: (BuildContext context, Widget? child) {
                      return CustomPaint(
                        painter: _RadarCanvasPainter(
                          sweepAngle: _sweepController.value * math.pi * 2,
                          zoomLevel: _selectedRangeIndex == 0
                              ? 1.3
                              : (_selectedRangeIndex == 1 ? 1.0 : 0.75),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: WeatherSpacing.space3),

                // Interactive Controls (Range Chips + Play/Pause)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    // Range chips
                    Row(
                      children: List<Widget>.generate(_ranges.length, (int index) {
                        final isSelected = _selectedRangeIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRangeIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(WeatherRadii.pill),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? WeatherPalette.mistBlue.withValues(alpha: 0.22)
                                    : WeatherPalette.lensLift.withValues(alpha: 0.3),
                                borderRadius:
                                    BorderRadius.circular(WeatherRadii.pill),
                                border: Border.all(
                                  color: isSelected
                                      ? WeatherPalette.mistBlue
                                      : WeatherPalette.lensRim.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                _ranges[index],
                                style: WeatherType.label.copyWith(
                                  fontSize: 11,
                                  fontWeight:
                                      isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? WeatherPalette.mistBlue
                                      : WeatherPalette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: WeatherPalette.mistBlue,
                        size: 26,
                      ),
                      onPressed: _togglePlay,
                      tooltip: _isPlaying ? 'Pause Radar Sweep' : 'Resume Radar Sweep',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // Intensity Legend
          GlassLens(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const <Widget>[
                _RadarLegendItem(color: Color(0xFF69F0AE), label: 'Light'),
                _RadarLegendItem(color: Color(0xFFFFB300), label: 'Moderate'),
                _RadarLegendItem(color: Color(0xFFFF5252), label: 'Heavy'),
                _RadarLegendItem(color: Color(0xFFE040FB), label: 'Extreme / Hail'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarLegendItem extends StatelessWidget {
  const _RadarLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: WeatherType.label.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _RadarCanvasPainter extends CustomPainter {
  const _RadarCanvasPainter({
    required this.sweepAngle,
    this.zoomLevel = 1.0,
  });

  final double sweepAngle;
  final double zoomLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;

    // Concentric Radar Rings
    final ringPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4.0), ringPaint);
    }

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ringPaint,
    );

    // Synthetic Rain Cell Blobs scaled by zoom
    final blob1Offset = Offset(30 * zoomLevel, -40 * zoomLevel);
    final blob1Radius = 55 * zoomLevel;
    final cellPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFF5252).withValues(alpha: 0.8),
          const Color(0xFFFFB300).withValues(alpha: 0.6),
          const Color(0xFF69F0AE).withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.35, 0.7, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: center + blob1Offset,
          radius: blob1Radius,
        ),
      );
    canvas.drawCircle(center + blob1Offset, blob1Radius, cellPaint);

    final blob2Offset = Offset(-45 * zoomLevel, 25 * zoomLevel);
    final blob2Radius = 40 * zoomLevel;
    final cellPaint2 = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFB300).withValues(alpha: 0.7),
          const Color(0xFF69F0AE).withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: center + blob2Offset,
          radius: blob2Radius,
        ),
      );
    canvas.drawCircle(center + blob2Offset, blob2Radius, cellPaint2);

    // Rotating Radar Sweep Line with Gradient Trail
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: <Color>[
          WeatherPalette.mistBlue.withValues(alpha: 0.45),
          WeatherPalette.mistBlue.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.25],
        transform: GradientRotation(sweepAngle - 0.5),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    final sweepLineEnd =
        center + Offset(math.cos(sweepAngle), math.sin(sweepAngle)) * radius;
    canvas.drawLine(
      center,
      sweepLineEnd,
      Paint()
        ..color = WeatherPalette.mistBlue
        ..strokeWidth = 2.0,
    );

    // Center Home Station Marker
    canvas.drawCircle(center, 4.0, Paint()..color = Colors.white);
    canvas.drawCircle(center, 2.0, Paint()..color = WeatherPalette.canvasDeep);
  }

  @override
  bool shouldRepaint(covariant _RadarCanvasPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle || oldDelegate.zoomLevel != zoomLevel;
}
