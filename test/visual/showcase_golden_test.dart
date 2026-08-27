import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/screens/weather_showcase_screen.dart';
import 'package:weather_os/main.dart';

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
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const WeatherOsShowcaseApp());
      await tester.pump(const Duration(milliseconds: 800));

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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WeatherOsShowcaseApp());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -620),
    );
    await tester.pump(const Duration(milliseconds: 300));

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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: WeatherTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.8),
          ),
          child: WeatherShowcaseScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_large_text.png'),
    );
  });

  testWidgets('showcase renders the storm environment', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: WeatherTheme.dark,
        home: const WeatherShowcaseScreen(weather: MockWeather.newYorkStorm),
      ),
    );
    await tester.pump(const Duration(milliseconds: 13680));

    expect(find.text('Storm'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey<String>('showcase-boundary')),
      matchesGoldenFile('goldens/showcase_storm.png'),
    );
  });
}
