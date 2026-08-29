import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/features/weather/models/hourly_forecast.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_condition.dart';
import 'package:weather_os/features/weather/models/weather_model.dart';
import 'package:weather_os/features/weather/screens/weather_showcase_screen.dart';

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
    (name: 'compact', size: const Size(390, 844)),
    (name: 'medium', size: const Size(768, 1024)),
    (name: 'expanded', size: const Size(1280, 900)),
  ]) {
    testWidgets('showcase renders at ${scenario.name} size', (
      WidgetTester tester,
    ) async {
      await _pumpShowcase(tester, size: scenario.size);

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('showcase-boundary')),
        matchesGoldenFile('goldens/showcase_${scenario.name}.png'),
      );
    });
  }

  testWidgets('showcase compact lower primitives stay visible', (
    WidgetTester tester,
  ) async {
    await _pumpShowcase(tester, size: const Size(390, 844));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -620),
    );
    await tester.pump();

    expect(find.text('PRESSURE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_compact_lower.png'),
    );
  });

  testWidgets('showcase remains composed with large text', (
    WidgetTester tester,
  ) async {
    await _pumpShowcase(
      tester,
      size: const Size(390, 844),
      textScaler: const TextScaler.linear(1.8),
    );

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_large_text.png'),
    );
  });

  testWidgets('showcase large text keeps lower primitives visible', (
    WidgetTester tester,
  ) async {
    await _pumpShowcase(
      tester,
      size: const Size(390, 844),
      textScaler: const TextScaler.linear(1.8),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    expect(find.text('WEATHER GLYPH VARIANTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_large_text_lower.png'),
    );
  });

  testWidgets('showcase renders the storm environment', (
    WidgetTester tester,
  ) async {
    final weather = MockWeather.newYorkStorm;
    expect(
      weather.hourly
          .take(6)
          .map((HourlyForecast forecast) => forecast.condition),
      everyElement(WeatherCondition.storm),
    );
    expect(weather.dailyForecasts.first.condition, WeatherCondition.storm);
    await _pumpShowcase(tester, size: const Size(390, 844), weather: weather);

    expect(
      find.bySemanticsLabel(
        'Woonsocket, RI. 65 degrees. Storm. Feels like 59 degrees. '
        'High 68, low 57.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_storm.png'),
    );
  });
}

Future<void> _pumpShowcase(
  WidgetTester tester, {
  required Size size,
  WeatherModel weather = MockWeather.newYorkRain,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: WeatherTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: textScaler,
        ),
        child: WeatherShowcaseScreen(weather: weather, atmosphereHour: 12),
      ),
    ),
  );
  await tester.pump();
}
