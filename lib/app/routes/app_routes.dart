import 'package:flutter/material.dart';

import '../../features/weather/screens/weather_home_screen.dart';
import '../../features/weather/screens/weather_showcase_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String showcase = '/showcase';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = switch (settings.name) {
      home => const WeatherHomeScreen(),
      showcase => const WeatherShowcaseScreen(),
      _ => const WeatherHomeScreen(),
    };
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => screen,
    );
  }
}
