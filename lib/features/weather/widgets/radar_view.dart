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
import '../models/hourly_forecast.dart';
import '../services/rainviewer_radar_service.dart';

class RadarView extends StatefulWidget {
  const RadarView({
    required this.hourly,
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final List<HourlyForecast> hourly;
  final double latitude;
  final double longitude;

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sweepController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  int _selectedRangeIndex = 1; // 0: 50mi (zoom 7), 1: 100mi (zoom 6), 2: 250mi (zoom 5)
  bool _isPlaying = true;
  late Future<RadarTileData?> _radarTiles;
  StreamSubscription<int>? _rangeSub;
  StreamSubscription<void>? _playSub;

  static const List<String> _ranges = <String>['50 mi', '100 mi', '250 mi'];

  int _zoomForRangeIndex(int index) => switch (index) {
    0 => 7,
    2 => 5,
    _ => 6,
  };

  void _loadTiles() {
    _radarTiles = const RainViewerRadarService().fetchRadarTiles(
      latitude: widget.latitude,
      longitude: widget.longitude,
      zoom: _zoomForRangeIndex(_selectedRangeIndex),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTiles();
    _rangeSub = WeatherNativeUIBridge.instance.onRadarRangeChanged.listen((
      int index,
    ) {
      if (mounted && index >= 0 && index < _ranges.length) {
        setState(() {
          _selectedRangeIndex = index;
          _loadTiles();
        });
        _syncBridgeState();
      }
    });
    _playSub = WeatherNativeUIBridge.instance.onRadarTogglePlay.listen((_) {
      if (mounted) _togglePlay();
    });
    _syncBridgeState();
  }

  @override
  void didUpdateWidget(covariant RadarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      // A location switch reuses the tab state because the tab key is stable.
      // Refresh the radar request so the map follows the newly selected ZIP.
      _loadTiles();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion && _isPlaying && !_sweepController.isAnimating) {
      _sweepController.repeat();
    } else if (reduceMotion) {
      _sweepController.stop();
      _sweepController.value = 0.0;
    }
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
    } else if (state == AppLifecycleState.resumed &&
        _isPlaying &&
        !_reduceMotion) {
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
    if (!mounted) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && !_reduceMotion) {
        _sweepController.repeat();
      } else {
        _sweepController.stop();
      }
    });
    _syncBridgeState();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  Widget build(BuildContext context) {
    final isIOS = WeatherPlatform.isIOS(context);
    final isNativeActive =
        isIOS && WeatherNativeUIBridge.instance.isNativeBridgeAvailable;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(WeatherSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  'DOPPLER RADAR TELEMETRY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WeatherType.overline,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: WeatherPalette.mistBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(WeatherRadii.pill),
                  border: Border.all(
                    color: WeatherPalette.mistBlue.withValues(alpha: 0.35),
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
                        color: WeatherPalette.mistBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE SWEEP',
                      style: WeatherType.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: WeatherPalette.mistBlue,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(WeatherRadii.control),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        FutureBuilder<RadarTileData?>(
                          future: _radarTiles,
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            if (data == null) {
                              return Container(
                                color: WeatherPalette.canvasDeep,
                                child: const Center(
                                  child: Text(
                                    'Acquiring Radar Sweep...',
                                    style: TextStyle(
                                      color: WeatherPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                // 1. Dark Cartographic Basemap (Coastlines, roads, borders, cities)
                                Image.network(
                                  data.baseMapUrl,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: WeatherPalette.canvasDeep),
                                ),
                                // 2. Real-time RainViewer Radar Reflectivity Overlay
                                Image.network(
                                  data.radarOverlayUrl,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                              ],
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _sweepController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _RadarCanvasPainter(
                                sweepAngle: _sweepController.value * math.pi * 2,
                                rangeLabel: _ranges[_selectedRangeIndex],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isNativeActive) ...<Widget>[
                  const SizedBox(height: WeatherSpacing.space3),

                  // Platform-Adaptive Interactive Controls (Only in Flutter when not native-bridged)
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final compact = constraints.maxWidth < 300;
                          final controls = <Widget>[
                            // Range Selector
                            WeatherPlatformSegmentedControl<int>(
                              groupValue: _selectedRangeIndex,
                              onValueChanged: (int val) {
                                setState(() {
                                  _selectedRangeIndex = val;
                                  _loadTiles();
                                });
                                _syncBridgeState();
                              },
                              children: const <int, Widget>{
                                0: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '50 mi',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                1: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '100 mi',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                2: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '250 mi',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
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
                              tooltip: _isPlaying
                                  ? 'Pause Radar Sweep'
                                  : 'Resume Radar Sweep',
                            ),
                          ];
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Align(
                                  alignment: Alignment.center,
                                  child: controls[0],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: controls[1],
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              Expanded(child: controls[0]),
                              controls[1],
                            ],
                          );
                        },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: WeatherSpacing.space3),

          // Intensity Legend
          WeatherPlatformCard(
            padding: const EdgeInsets.all(WeatherSpacing.space4),
            child: const Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                _RadarLegendItem(color: WeatherPalette.success, label: 'Light'),
                _RadarLegendItem(color: Color(0xFFFFB300), label: 'Moderate'),
                _RadarLegendItem(color: Color(0xFFFF5252), label: 'Heavy'),
                _RadarLegendItem(
                  color: Color(0xFFE040FB),
                  label: 'Extreme / Hail',
                ),
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
    required this.rangeLabel,
  });

  final double sweepAngle;
  final String rangeLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;

    // Concentric Radar Rings
    final ringPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4.0), ringPaint);
    }

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = WeatherPalette.mistBlue.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crosshairPaint,
    );

    // Rotating Radar Sweep Line with Gradient Trail
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: <Color>[
          WeatherPalette.mistBlue.withValues(alpha: 0.35),
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
        ..color = WeatherPalette.mistBlue.withValues(alpha: 0.85)
        ..strokeWidth = 1.75,
    );

    // Center station marker pulses as a new scan comes through.
    final phase = sweepAngle;
    final markerRadius = 3.5 + math.sin(phase * 2.0) * 0.7;
    canvas.drawCircle(
      center,
      markerRadius + 4,
      Paint()..color = WeatherPalette.mistBlue.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, markerRadius, Paint()..color = Colors.white);
    canvas.drawCircle(center, 1.8, Paint()..color = WeatherPalette.canvasDeep);
  }

  @override
  bool shouldRepaint(covariant _RadarCanvasPainter oldDelegate) =>
      oldDelegate.sweepAngle != sweepAngle || oldDelegate.rangeLabel != rangeLabel;
}
