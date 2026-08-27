import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/providers/weather_provider.dart';
import 'package:weather_os/features/weather/providers/weather_scope.dart';
import 'package:weather_os/features/weather/screens/weather_home_screen.dart';
import 'package:weather_os/features/weather/services/weather_repository.dart';
import 'package:weather_os/features/weather/services/weather_service.dart';

void main() {
  setUpAll(() async {
    final fontLoader = FontLoader('Barlow')
      ..addFont(rootBundle.load('assets/fonts/Barlow-Light.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Barlow-Bold.ttf'));
    await fontLoader.load();
  });

  for (final scenario in <({String name, Size size})>[
    (name: 'compact_ios', size: const Size(390, 844)),
    (name: 'compact_android', size: const Size(360, 800)),
    (name: 'medium', size: const Size(768, 1024)),
    (name: 'expanded', size: const Size(1280, 900)),
  ]) {
    testWidgets('home renders at ${scenario.name} size', (
      WidgetTester tester,
    ) async {
      await _pumpHome(tester, size: scenario.size, disableAnimations: true);

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('home-boundary')),
        matchesGoldenFile('goldens/home_${scenario.name}.png'),
      );
    });
  }

  testWidgets('short home scroll keeps metrics reachable', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(320, 640),
      disableAnimations: true,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -420),
    );
    await tester.pump();

    expect(find.text('PRESSURE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_short_lower.png'),
    );
  });

  testWidgets('home remains complete at large accessibility text', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      disableAnimations: true,
      textScaler: const TextScaler.linear(1.8),
    );

    expect(find.text('NEW YORK'), findsOneWidget);
    expect(find.text('71°'), findsAtLeastNWidgets(2));
    expect(find.text('Rain'), findsOneWidget);
    expect(find.text('Feels like 69°'), findsOneWidget);
    expect(find.text('H 74°   L 62°'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('home-boundary')),
      matchesGoldenFile('goldens/home_large_text.png'),
    );
  });

  for (final frame in <({String name, Duration elapsed})>[
    (name: 'start', elapsed: const Duration(milliseconds: 800)),
    (name: 'mid', elapsed: const Duration(milliseconds: 5800)),
  ]) {
    testWidgets('ambient weather renders the ${frame.name} motion frame', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(390, 844),
        disableAnimations: false,
        initialPump: frame.elapsed,
      );
      await expectLater(
        find.byKey(const ValueKey<String>('home-boundary')),
        matchesGoldenFile('goldens/home_motion_${frame.name}.png'),
      );
    });
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required bool disableAnimations,
  Duration initialPump = Duration.zero,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final provider = WeatherProvider(
    repository: const WeatherRepository(
      service: _StaticWeatherService(MockWeather.newYorkRain),
    ),
  );
  await provider.load();
  addTearDown(provider.dispose);

  await tester.pumpWidget(
    WeatherScope(
      provider: provider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: WeatherTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
            textScaler: textScaler,
          ),
          child: const RepaintBoundary(
            key: ValueKey<String>('home-boundary'),
            child: WeatherHomeScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump(initialPump);
}

class _StaticWeatherService implements WeatherService {
  const _StaticWeatherService(this.weather);

  final WeatherModel weather;

  @override
  Future<WeatherModel> fetchCurrentWeather({
    double latitude = 40.7128,
    double longitude = -74.0060,
    String locationName = 'New York',
  }) async =>
      weather;
}
