import 'package:flutter/material.dart';

import 'weather_tokens.dart';

abstract final class WeatherTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: WeatherPalette.mistBlue,
      onPrimary: WeatherPalette.canvasDeep,
      secondary: WeatherPalette.horizonAmber,
      onSecondary: WeatherPalette.canvasDeep,
      error: WeatherPalette.error,
      onError: WeatherPalette.canvasDeep,
      surface: WeatherPalette.lensCore,
      onSurface: WeatherPalette.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WeatherPalette.canvasDeep,
      fontFamily: WeatherType.family,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        headlineMedium: WeatherType.title,
        titleLarge: WeatherType.condition,
        bodyLarge: WeatherType.body,
        labelLarge: WeatherType.label,
      ),
    );
  }
}
