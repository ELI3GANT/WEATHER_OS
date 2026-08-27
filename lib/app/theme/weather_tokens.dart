import 'package:flutter/material.dart';

abstract final class WeatherPalette {
  static const Color canvasDeep = Color(0xFF02070C);
  static const Color canvasNavy = Color(0xFF06111B);
  static const Color lensCore = Color(0xFF0C1B29);
  static const Color lensLift = Color(0xFF173047);
  static const Color lensRim = Color(0xFF9DDBFF);
  static const Color textPrimary = Color(0xFFF6FAFF);
  static const Color textSecondary = Color(0xFFB7C5D3);
  static const Color textTertiary = Color(0xFF7C91A4);
  static const Color mistBlue = Color(0xFF67C9FF);
  static const Color horizonAmber = Color(0xFFE49A5D);
  static const Color stormViolet = Color(0xFF6D5DAA);
  static const Color error = Color(0xFFFF7979);
  static const Color success = Color(0xFF64DDAE);
  static const Color clear = Color(0x00000000);
}

abstract final class WeatherSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
}

abstract final class WeatherRadii {
  static const double control = 16;
  static const double lens = 28;
  static const double scene = 40;
  static const double pill = 999;
}

abstract final class WeatherLayout {
  static const double narrowMetricsBreakpoint = 350;
  static const double expandedBreakpoint = 900;
  static const double stackedContentWidth = 920;
  static const double expandedContentWidth = 1080;
  static const double forecastFitWidth = 82;
  static const double forecastCellWidth = 74;
  static const double forecastRailHeight = 128;
  static const double forecastAccessibilityLift = 40;
  static const double forecastAccessibilityFactor = 2;
  static const double weatherGlyphSize = 44;
  static const double heroWeatherGlyphSize = 40;
  static const double specimenGlyphSize = 28;
  static const double metricGlyphSize = 28;
  static const double forecastGlyphSize = 32;
  static const double forecastTemperatureSize = 20;
  static const double currentMarkerWidth = 22;
  static const double currentMarkerHeight = 2;
  static const double opticalBorderWidth = 1;
  static const double metricDividerWidth = 1;
  static const double metricDividerHeight = 72;
  static const double compactTemperatureCap = 128;
  static const double expandedTemperatureCap = 148;
}

abstract final class WeatherOptics {
  static const double quietRimOpacity = 0.16;
  static const double lensRimOpacity = 0.34;
  static const double quietLiftOpacity = 0.38;
  static const double lensLiftOpacity = 0.62;
  static const double highlightOpacity = 0.06;
  static const double trailingRimOpacity = 0.1;
  static const double coreOpacity = 0.86;
  static const double baseOpacity = 0.94;
  static const double quietShadowOpacity = 0.08;
  static const double lensShadowOpacity = 0.14;
  static const double dividerOpacity = 0.16;
  static const double shadowBlur = 20;
  static const Offset shadowOffset = Offset(0, 10);
}

abstract final class WeatherMotion {
  static const Duration micro = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasis = Duration(milliseconds: 720);
  static const Duration weatherCycle = Duration(seconds: 18);
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve pressCurve = Curves.easeOutBack;
}

abstract final class WeatherType {
  static const String family = 'Barlow';

  static const TextStyle temperature = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textPrimary,
    fontSize: WeatherLayout.compactTemperatureCap,
    height: 0.82,
    letterSpacing: -3.2,
    fontWeight: FontWeight.w300,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textPrimary,
    fontSize: 28,
    height: 1.15,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle condition = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textPrimary,
    fontSize: 24,
    height: 1.2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metricValue = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textPrimary,
    fontSize: 24,
    height: 1.1,
    letterSpacing: -0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textSecondary,
    fontSize: 16,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textSecondary,
    fontSize: 13,
    height: 1.25,
    letterSpacing: 0.6,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: family,
    color: WeatherPalette.textTertiary,
    fontSize: 11,
    height: 1.25,
    letterSpacing: 2.2,
    fontWeight: FontWeight.w600,
  );
}
