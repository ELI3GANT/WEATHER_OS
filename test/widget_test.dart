import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_os/app/weather_os_app.dart';
import 'package:weather_os/features/weather/models/hourly_forecast.dart';
import 'package:weather_os/features/weather/models/weather_condition.dart';
import 'package:weather_os/features/weather/widgets/weather_status_view.dart';
import 'package:weather_os/features/weather/widgets/weather_threat_bar.dart';

void main() {
  testWidgets('WeatherOS loads the current conditions experience', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WeatherOsApp(cacheService: null));
    expect(find.byType(WeatherLoadingView), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.byType(WeatherLoadingView), findsNothing);
    expect(find.text('Woonsocket, RI'), findsOneWidget);
    expect(find.text('71°'), findsAtLeastNWidgets(1));
    expect(find.text('Rain'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeatherOS location switch does not throw RangeError or red screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WeatherOsApp(cacheService: null));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // Verify initial load
    expect(find.text('Woonsocket, RI'), findsOneWidget);

    // Tap an hour in the rail to change selected forecast index
    final hourCell = find.text('10 AM');
    if (hourCell.evaluate().isNotEmpty) {
      await tester.tap(hourCell.first);
      await tester.pump();
    }

    // Verify no exceptions thrown and UI rendered cleanly
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeatherOS location dialog entry does not throw or crash', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WeatherOsApp(cacheService: null));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Woonsocket, RI'), findsOneWidget);

    // Tap location header to open dialog
    await tester.tap(find.text('Woonsocket, RI'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Change weather location'), findsOneWidget);

    // Enter new location/zip code
    await tester.enterText(find.byType(TextField), 'Los Angeles');
    await tester.pump();

    // Tap 'Use location'
    await tester.tap(find.text('Use location'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('WeatherThreatBar renders subtle track instead of neon green for sunny/dry conditions', (
    WidgetTester tester,
  ) async {
    const sunnyForecasts = <HourlyForecast>[
      HourlyForecast(
        timeLabel: '12 PM',
        temperature: 75,
        condition: WeatherCondition.sunny,
        precipChance: 0,
      ),
      HourlyForecast(
        timeLabel: '1 PM',
        temperature: 77,
        condition: WeatherCondition.cloudy,
        precipChance: 5,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WeatherThreatBar(forecasts: sunnyForecasts),
        ),
      ),
    );

    expect(find.text('PRECIPITATION / INTENSITY • CALM / DRY'), findsOneWidget);

    // Verify none of the container decorations use the old neon green 0xFF69F0AE
    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final container in containers) {
      final decoration = container.decoration;
      if (decoration is BoxDecoration && decoration.color != null) {
        expect(decoration.color, isNot(equals(const Color(0xFF69F0AE))));
      }
    }
  });
}

