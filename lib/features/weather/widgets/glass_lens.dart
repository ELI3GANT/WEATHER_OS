import 'package:flutter/material.dart';

import '../../../app/theme/weather_tokens.dart';

class GlassLens extends StatelessWidget {
  const GlassLens({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(WeatherSpacing.space5),
    this.radius = WeatherRadii.lens,
    this.quiet = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final rimOpacity = quiet
        ? WeatherOptics.quietRimOpacity
        : WeatherOptics.lensRimOpacity;
    final liftOpacity = quiet
        ? WeatherOptics.quietLiftOpacity
        : WeatherOptics.lensLiftOpacity;
    final shadowOpacity = quiet
        ? WeatherOptics.quietShadowOpacity
        : WeatherOptics.lensShadowOpacity;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            WeatherPalette.lensRim.withValues(alpha: rimOpacity),
            WeatherPalette.textPrimary.withValues(
              alpha: WeatherOptics.highlightOpacity,
            ),
            WeatherPalette.lensRim.withValues(
              alpha: WeatherOptics.trailingRimOpacity,
            ),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WeatherPalette.canvasDeep.withValues(alpha: shadowOpacity),
            blurRadius: WeatherOptics.shadowBlur,
            offset: WeatherOptics.shadowOffset,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(WeatherLayout.opticalBorderWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              radius - WeatherLayout.opticalBorderWidth,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                WeatherPalette.lensLift.withValues(alpha: liftOpacity),
                WeatherPalette.lensCore.withValues(
                  alpha: WeatherOptics.coreOpacity,
                ),
                WeatherPalette.canvasNavy.withValues(
                  alpha: WeatherOptics.baseOpacity,
                ),
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
