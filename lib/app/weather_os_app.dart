import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../features/weather/providers/weather_provider.dart';
import '../features/weather/providers/weather_scope.dart';
import '../features/weather/services/location_service.dart';
import '../features/weather/services/mock_weather_service.dart';
import '../features/weather/services/weather_cache_service.dart';
import '../features/weather/services/weather_repository.dart';
import '../features/weather/services/weather_service.dart';
import 'routes/app_routes.dart';
import 'theme/weather_theme.dart';

class WeatherOsAppScrollBehavior extends MaterialScrollBehavior {
  const WeatherOsAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class WeatherOsApp extends StatefulWidget {
  const WeatherOsApp({
    super.key,
    this.weatherService = const MockWeatherService(),
    this.locationService,
    this.cacheService = const WeatherCacheService(),
  });

  final WeatherService weatherService;
  final LocationService? locationService;
  final WeatherCacheService? cacheService;

  @override
  State<WeatherOsApp> createState() => _WeatherOsAppState();
}

class _WeatherOsAppState extends State<WeatherOsApp> {
  late final WeatherProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = WeatherProvider(
      repository: WeatherRepository(service: widget.weatherService),
      locationService: widget.locationService,
      cacheService: widget.cacheService,
    )..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: WeatherTheme.dark,
        scrollBehavior: const WeatherOsAppScrollBehavior(),
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
      builder: (context, child) {
        return WeatherScope(
          provider: _provider,
          child: child!,
        );
      },
    );
  }
}
