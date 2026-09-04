import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';
import '../../../core/platform_ui/weather_platform_card.dart';
import '../models/hourly_forecast.dart';
import '../models/weather_model.dart';

class WeatherChartsCard extends StatelessWidget {
  const WeatherChartsCard({
    required this.weather,
    this.selectedIndex = 0,
    super.key,
  });

  final WeatherModel weather;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 850;

        final tempCard = WeatherPlatformCard(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'TEMPERATURE',
                      style: WeatherType.overline,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'High ${weather.high.round()}° • Low ${weather.low.round()}°',
                      style: WeatherType.label.copyWith(
                        fontSize: 11,
                        color: WeatherPalette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WeatherSpacing.space3),
              SizedBox(
                height: 130,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _TemperatureSplinePainter(
                    forecasts: weather.hourly,
                    currentTemp: weather.temperature,
                    high: weather.high,
                    low: weather.low,
                    selectedIndex: selectedIndex,
                  ),
                ),
              ),
            ],
          ),
        );

        final precipCard = WeatherPlatformCard(
          padding: const EdgeInsets.all(WeatherSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'PRECIPITATION',
                      style: WeatherType.overline,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Peak ${weather.precipChance}%',
                      style: WeatherType.label.copyWith(
                        fontSize: 11,
                        color: WeatherPalette.mistBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: WeatherSpacing.space3),
              SizedBox(
                height: 130,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PrecipitationBarPainter(
                    forecasts: weather.hourly,
                    selectedIndex: selectedIndex,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: tempCard),
              const SizedBox(width: WeatherSpacing.space3),
              Expanded(child: precipCard),
            ],
          );
        }

        return Column(
          children: <Widget>[
            tempCard,
            const SizedBox(height: WeatherSpacing.space3),
            precipCard,
          ],
        );
      },
    );
  }
}

class _TemperatureSplinePainter extends CustomPainter {
  const _TemperatureSplinePainter({
    required this.forecasts,
    required this.currentTemp,
    required this.high,
    required this.low,
    required this.selectedIndex,
  });

  final List<HourlyForecast> forecasts;
  final double currentTemp;
  final double high;
  final double low;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (forecasts.isEmpty) return;

    final leftMargin = 32.0;
    final bottomMargin = 22.0;
    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height - bottomMargin;

    // Draw Y-Axis Guide Labels
    final minT = (low - 5).clamp(0, 120).toDouble();
    final maxT = (high + 8).clamp(0, 120).toDouble();
    final tempRange = (maxT - minT).clamp(10, 100).toDouble();

    final textStyle = WeatherType.label.copyWith(
      fontSize: 10,
      color: WeatherPalette.textTertiary,
    );

    final ySteps = [maxT.round(), ((maxT + minT) / 2).round(), minT.round()];
    for (final step in ySteps) {
      final yNorm = 1.0 - ((step - minT) / tempRange);
      final yPos = yNorm * chartHeight;
      final textPainter = TextPainter(
        text: TextSpan(text: '$step°', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, yPos - (textPainter.height / 2)));

      final gridPaint = Paint()
        ..color = WeatherPalette.lensLift.withValues(alpha: 0.3)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(leftMargin, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    // Compute curve points
    final points = <Offset>[];
    final stepX = chartWidth / (forecasts.length - 1).clamp(1, 100);
    for (var i = 0; i < forecasts.length; i++) {
      final t = forecasts[i].temperature;
      final x = leftMargin + (i * stepX);
      final yNorm = (1.0 - ((t - minT) / tempRange)).clamp(0.05, 0.95);
      final y = yNorm * chartHeight;
      points.add(Offset(x, y));
    }

    // Build smooth Cubic Bézier Spline
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          WeatherPalette.horizonAmber.withValues(alpha: 0.35),
          WeatherPalette.horizonAmber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Line Stroke
    final linePaint = Paint()
      ..color = WeatherPalette.horizonAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Active Selected Hour Marker
    final activeIndex = selectedIndex.clamp(0, points.length - 1);
    final activePt = points[activeIndex];

    // Pulsing halo
    canvas.drawCircle(
      activePt,
      8.0,
      Paint()..color = WeatherPalette.horizonAmber.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      activePt,
      5.0,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      activePt,
      2.5,
      Paint()..color = WeatherPalette.horizonAmber,
    );

    // Active label
    final activeLabelPainter = TextPainter(
      text: TextSpan(
        text: '${forecasts[activeIndex].temperature.round()}°',
        style: WeatherType.label.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: WeatherPalette.horizonAmber,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    activeLabelPainter.paint(
      canvas,
      Offset(activePt.dx - (activeLabelPainter.width / 2), activePt.dy - 18),
    );

    // X-Axis Time Labels
    for (var i = 0; i < forecasts.length; i += (forecasts.length / 4).ceil()) {
      final pt = points[i];
      final timePainter = TextPainter(
        text: TextSpan(text: forecasts[i].timeLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      timePainter.paint(
        canvas,
        Offset(pt.dx - (timePainter.width / 2), size.height - bottomMargin + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureSplinePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.currentTemp != currentTemp;
}

class _PrecipitationBarPainter extends CustomPainter {
  const _PrecipitationBarPainter({
    required this.forecasts,
    required this.selectedIndex,
  });

  final List<HourlyForecast> forecasts;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (forecasts.isEmpty) return;

    final leftMargin = 32.0;
    final bottomMargin = 22.0;
    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height - bottomMargin;

    final textStyle = WeatherType.label.copyWith(
      fontSize: 10,
      color: WeatherPalette.textTertiary,
    );

    // Y-Axis labels (100%, 50%, 0%)
    final yLabels = ['100%', '50%', '0%'];
    final yPosSteps = [0.0, chartHeight / 2, chartHeight];
    for (var i = 0; i < yLabels.length; i++) {
      final yPos = yPosSteps[i];
      final textPainter = TextPainter(
        text: TextSpan(text: yLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, yPos - (textPainter.height / 2)));

      final gridPaint = Paint()
        ..color = WeatherPalette.lensLift.withValues(alpha: 0.3)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(leftMargin, yPos),
        Offset(size.width, yPos),
        gridPaint,
      );
    }

    // Render Rounded Vertical Bars
    final barCount = forecasts.length;
    final totalSpacing = chartWidth * 0.25;
    final barWidth = ((chartWidth - totalSpacing) / barCount).clamp(4.0, 16.0);
    final spacing = (chartWidth - (barWidth * barCount)) / (barCount - 1).clamp(1, 100);

    for (var i = 0; i < barCount; i++) {
      final isSelected = i == selectedIndex;
      final prob = (forecasts[i].precipChance / 100.0).clamp(0.05, 1.0);
      final barHeight = prob * chartHeight;
      final x = leftMargin + (i * (barWidth + spacing));
      final y = chartHeight - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );

      final barColor = isSelected ? const Color(0xFF38BDF8) : WeatherPalette.mistBlue;
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            barColor,
            barColor.withValues(alpha: isSelected ? 0.7 : 0.25),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);

      if (isSelected) {
        // Glowing active cap dot
        canvas.drawCircle(
          Offset(x + (barWidth / 2), y),
          2.5,
          Paint()..color = Colors.white,
        );
      }

      // X-Axis Time Labels
      if (i % (barCount / 4).ceil() == 0 || i == barCount - 1) {
        final timePainter = TextPainter(
          text: TextSpan(text: forecasts[i].timeLabel, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        timePainter.paint(
          canvas,
          Offset(x + (barWidth / 2) - (timePainter.width / 2), size.height - bottomMargin + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PrecipitationBarPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}
