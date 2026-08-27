import 'package:flutter/material.dart';

import 'app/theme/weather_theme.dart';
import 'app/weather_os_app.dart';
import 'core/services/system_ui_service.dart';
import 'features/weather/screens/weather_showcase_screen.dart';
import 'features/weather/services/geolocator_location_service.dart';
import 'features/weather/services/open_meteo_weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemUiService.configure();
  runApp(
    const WeatherOsApp(
      weatherService: OpenMeteoWeatherService(),
      locationService: GeolocatorLocationService(),
    ),
  );
}

class WeatherOsShowcaseApp extends StatelessWidget {
  const WeatherOsShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherOS Primitive Showcase',
      theme: WeatherTheme.dark,
      home: const WeatherShowcaseScreen(),
    );
  }
}
