import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/theme/weather_theme.dart';
import 'package:weather_os/features/weather/models/mock_weather.dart';
import 'package:weather_os/features/weather/models/weather_condition.dart';
import 'package:weather_os/features/weather/screens/weather_showcase_screen.dart';
import 'package:weather_os/features/weather/widgets/current_conditions_hero.dart';
import 'package:weather_os/features/weather/widgets/hourly_forecast_rail.dart';
import 'package:weather_os/features/weather/widgets/weather_metrics_strip.dart';
import 'package:weather_os/features/weather/widgets/weather_glyph.dart';

void main() {
  testWidgets('atmosphere fills the expanded viewport', (
    WidgetTester tester,
  ) async {
    const size = Size(1280, 900);
    await _pumpShowcase(tester, disableAnimations: true, surfaceSize: size);

    expect(tester.getSize(find.byType(WeatherShowcaseScreen)), size);
    expect(tester.getSize(find.byKey(_atmosphereBoundaryKey)), size);
  });

  testWidgets('weather summary precedes forecast and metrics semantically', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpShowcase(tester, disableAnimations: true);

    expect(
      find.bySemanticsLabel(RegExp(r'Woonsocket, RI\. 71 degrees\. Rain\.')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'12 PM, 71 degrees, Rain, 90 percent chance of rain'),
      ),
      findsOneWidget,
    );

    final heroTop = tester.getTopLeft(find.byType(CurrentConditionsHero)).dy;
    final forecastTop = tester.getTopLeft(find.byType(HourlyForecastRail)).dy;
    final metricsTop = tester.getTopLeft(find.byType(WeatherMetricsStrip)).dy;
    expect(heroTop, lessThan(forecastTop));
    expect(forecastTop, lessThan(metricsTop));
    semantics.dispose();
  });

  testWidgets('metrics use a two by two fallback below 350 dp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WeatherTheme.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: WeatherMetricsStrip(weather: MockWeather.newYorkRain),
          ),
        ),
      ),
    );

    final humidity = tester.getCenter(find.text('HUMIDITY'));
    final wind = tester.getCenter(find.text('WIND'));
    final uv = tester.getCenter(find.text('UV'));
    final pressure = tester.getCenter(find.text('PRESSURE'));
    expect((humidity.dy - wind.dy).abs(), lessThan(1));
    expect((uv.dy - pressure.dy).abs(), lessThan(1));
    expect(uv.dy, greaterThan(humidity.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('weather glyph stops its ticker when animation is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: WeatherGlyph(condition: WeatherCondition.rain),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: WeatherGlyph(condition: WeatherCondition.rain, animate: false),
        ),
      ),
    );
    await tester.pump();

    expect(tester.binding.transientCallbackCount, 0);
  });
}

Future<void> _pumpShowcase(
  WidgetTester tester, {
  required bool disableAnimations,
  TextScaler textScaler = TextScaler.noScaling,
  Size surfaceSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: WeatherTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          disableAnimations: disableAnimations,
          textScaler: textScaler,
        ),
        child: const WeatherShowcaseScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 800));
}

const _atmosphereBoundaryKey = ValueKey<String>('weather-atmosphere-boundary');
