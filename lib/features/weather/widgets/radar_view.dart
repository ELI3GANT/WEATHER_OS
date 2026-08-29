import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_native_contracts.dart';
import '../../../core/platform_ui/weather_native_ui_bridge.dart';
import '../../../core/platform_ui/weather_platform.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../../../core/platform_ui/weather_platform_feedback.dart';
import '../../../core/platform_ui/weather_platform_icons.dart';
import '../../../core/platform_ui/weather_platform_segmented_control.dart';

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
  StreamSubscription<int>? _rangeSub;
  StreamSubscription<void>? _playSub;

  static const List<String> _ranges = <String>['50 mi', '100 mi', '250 mi'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rangeSub = WeatherNativeUIBridge.instance.onRadarRangeChanged.listen((int index) {
      if (index >= 0 && index < _ranges.length) {
        setState(() {
          _selectedRangeIndex = index;
        });
        _syncBridgeState();
      }
    });
    _playSub = WeatherNativeUIBridge.instance.onRadarTogglePlay.listen((_) {
      _togglePlay();
    });
    _syncBridgeState();
  }

  void _syncBridgeState() {
    WeatherNativeUIBridge.instance.updateRadarControls(
      RadarControlState(
        isPlaying: _isPlaying,
        selectedRangeIndex: _selectedRangeIndex,
        ranges: _ranges,
      ),
    );
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
    _rangeSub?.cancel();
    _playSub?.cancel();
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
    _syncBridgeState();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);
    final isNativeActive = isIOS && WeatherNativeUIBridge.instance.isNativeBridgeAvailable;

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
          WeatherPlatformCard(
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
                if (!isNativeActive) ...<Widget>[
                  const SizedBox(height: WeatherSpacing.space3),

                  // Platform-Adaptive Interactive Controls (Only in Flutter when not native-bridged)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // Range Selector
                      WeatherPlatformSegmentedControl<int>(
                        groupValue: _selectedRangeIndex,
                        onValueChanged: (int val) {
                          setState(() {
                            _selectedRangeIndex = val;
                          });
                          _syncBridgeState();
                        },
                        children: const <int, Widget>{
                          0: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('50 mi', style: TextStyle(fontSize: 11)),
                          ),
                          1: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('100 mi', style: TextStyle(fontSize: 11)),
                          ),
                          2: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text('250 mi', style: TextStyle(fontSize: 11)),
                          ),
                        },
                      ),

                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? WeatherPlatformIcons.pause(context)
                              : WeatherPlatformIcons.play(context),
                          color: WeatherPalette.mistBlue,
                          size: 26,
                        ),
                        onPressed: () {
                          WeatherPlatformFeedback.light(context);
                          _togglePlay();
                        },
                        tooltip: _isPlaying ? 'Pause Radar Sweep' : 'Resume Radar Sweep',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // Intensity Legend
          WeatherPlatformCard(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
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
